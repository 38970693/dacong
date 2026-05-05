import type { CrawlResult, CrawledPost } from '../types';
import { logger } from '../logger';
import { createSupabaseAdmin } from '../supabase';

// RSS 订阅源配置
const RSS_SOURCES = [
  {
    name: '36kr_rss',
    url: 'https://36kr.com/feed',
    source: '36kr',
  },
  {
    name: 'huxiu_rss',
    url: 'https://www.huxiu.com/rss/0.xml',
    source: 'huxiu',
  },
  {
    name: 'jiemian_rss',
    url: 'https://www.jiemian.com/rss.xml',
    source: 'jiemian',
  },
  {
    name: 'sina_rss',
    url: 'https://feed.mix.sina.com.cn/api/roll/get?pageid=153&lid=2516&num=20&page=1',
    source: 'sina',
  },
];

interface FeedItem {
  title?: string;
  link?: string;
  description?: string;
  pubDate?: string;
  author?: string;
}

interface ParsedFeed {
  items: FeedItem[];
  title?: string;
}

// 解析 RSS/Atom XML
function parseXML(xml: string): ParsedFeed {
  const items: FeedItem[] = [];

  // 移除 XML 声明和 CDATA
  const cleanXml = xml.replace(/<!\[CDATA\[|\]\]>/g, '');

  // 匹配 item 或 entry 标签
  const itemRegex = /<(?:item|entry)>([\s\S]*?)<\/(?:item|entry)>/gi;
  let match;

  while ((match = itemRegex.exec(cleanXml)) !== null) {
    const itemXml = match[1];

    const item: FeedItem = {
      title: extractTag(itemXml, 'title'),
      link: extractTag(itemXml, 'link') || extractAttr(itemXml, 'link'),
      description: extractTag(itemXml, 'description') || extractTag(itemXml, 'content:encoded'),
      pubDate: extractTag(itemXml, 'pubDate') || extractTag(itemXml, 'published') || extractTag(itemXml, 'updated'),
      author: extractTag(itemXml, 'author') || extractTag(itemXml, 'dc:creator'),
    };

    if (item.title) {
      items.push(item);
    }
  }

  return { items };
}

// 提取标签内容
function extractTag(xml: string, tag: string): string | undefined {
  const regex = new RegExp(`<${tag}[^>]*>([^<]*)</${tag}>`, 'i');
  const match = regex.exec(xml);
  return match?.[1]?.trim();
}

// 提取 link 标签的 href 属性
function extractAttr(xml: string, tag: string): string | undefined {
  const regex = new RegExp(`<${tag}[^>]*href=["']([^"']*)["'][^>]*>`, 'i');
  const match = regex.exec(xml);
  return match?.[1];
}

// 爬取单个 RSS 源
async function crawlRSS(
  name: string,
  url: string,
  source: string
): Promise<CrawlResult> {
  const supabase = createSupabaseAdmin();
  const posts: CrawledPost[] = [];

  logger.info(`开始爬取 RSS: ${name}...`);

  try {
    const response = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; DaCong Bot)',
        'Accept': 'application/rss+xml, application/xml, text/xml, */*',
        'Cache-Control': 'no-cache',
      },
    });

    if (!response.ok) {
      throw new Error(`RSS 请求失败: ${response.status}`);
    }

    const xml = await response.text();
    const feed = parseXML(xml);

    for (const item of feed.items.slice(0, 20)) {
      if (!item.title || !item.link) continue;

      posts.push({
        title: item.title.trim(),
        content: item.description?.replace(/<[^>]*>/g, '').substring(0, 500) || null,
        source_url: item.link.startsWith('http') ? item.link : item.link,
        author: item.author || null,
        published_at: parseDate(item.pubDate),
      });
    }

    // 保存到数据库
    if (posts.length > 0) {
      const rawPosts = posts.map(post => ({
        source: source as '36kr' | 'huxiu' | 'sina' | 'jiemian',
        source_url: post.source_url,
        title: post.title,
        content: post.content,
        author: post.author,
        published_at: post.published_at,
        status: 'pending' as const,
      }));

      const { error } = await supabase
        .from('raw_posts')
        .upsert(rawPosts, {
          onConflict: 'source_url',
          ignoreDuplicates: true
        });

      if (error) {
        logger.error(`保存 ${name} RSS 数据失败:`, error);
      } else {
        logger.info(`成功保存 ${posts.length} 条 ${name} RSS 数据`);
      }
    }

    return {
      source: name,
      posts,
      success: true,
      crawledCount: posts.length,
    };

  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error(`[crawlRSS] ${name} 爬取失败:`, message, error);
    logger.error(`${name} RSS 爬取失败: ${message}`, error);

    return {
      source: name,
      posts,
      success: false,
      error: message,
      crawledCount: 0,
    };
  }
}

// 解析日期字符串
function parseDate(dateStr: string | undefined): string {
  if (!dateStr) {
    return new Date().toISOString();
  }

  try {
    const date = new Date(dateStr);
    return isNaN(date.getTime()) ? new Date().toISOString() : date.toISOString();
  } catch {
    return new Date().toISOString();
  }
}

// 将 raw_posts 发布到 posts 表
async function publishPosts(source: string) {
  const supabase = createSupabaseAdmin();

  // 获取该来源的待审核数据
  const { data: rawPosts, error } = await supabase
    .from('raw_posts')
    .select('id, source, source_url, title, content, author, published_at')
    .eq('source', source)
    .eq('status', 'pending')
    .limit(20);

  if (error || !rawPosts || rawPosts.length === 0) {
    logger.info(`[publishPosts] ${source}: 没有待发布的数据`);
    return;
  }

  logger.info(`[publishPosts] ${source}: 准备发布 ${rawPosts.length} 条数据`);

  // 转换到 posts 表，使用 upsert 处理重复
  const posts = rawPosts.map(raw => ({
    raw_post_id: raw.id,
    title: raw.title,
    content: raw.content,
    source: raw.source,
    source_url: raw.source_url,
    status: 'approved' as const,
  }));

  // 使用 upsert 代替 insert，避免重复键错误
  const { error: insertError } = await supabase
    .from('posts')
    .upsert(posts, {
      onConflict: 'raw_post_id',
      ignoreDuplicates: false
    });

  if (insertError) {
    logger.error(`发布 ${source} 数据失败:`, insertError);
    return;
  }

  // 更新 raw_posts 状态为 approved（关键！否则不会同步）
  const ids = rawPosts.map(p => p.id);
  await supabase
    .from('raw_posts')
    .update({ status: 'approved' })
    .in('id', ids);

  logger.info(`已将 ${rawPosts.length} 条 ${source} 数据发布到 posts 表`);
}

// 爬取所有 RSS 源
export async function crawlAllRSS(): Promise<CrawlResult[]> {
  logger.info('开始爬取所有 RSS 源...');

  const results: CrawlResult[] = [];

  for (const source of RSS_SOURCES) {
    const result = await crawlRSS(source.name, source.url, source.source);
    results.push(result);
  }

  const totalCrawled = results.reduce((sum, r) => sum + r.crawledCount, 0);
  const successCount = results.filter(r => r.success).length;

  logger.info(`RSS 爬取完成: ${totalCrawled} 条数据, ${successCount}/${RSS_SOURCES.length} 个来源成功`);

  return results;
}

// 爬取指定 RSS 源
export async function crawlSingleRSS(name: string): Promise<CrawlResult | null> {
  const source = RSS_SOURCES.find(s => s.name === name);
  if (!source) {
    logger.warn(`未找到 RSS 源: ${name}`);
    return null;
  }

  return crawlRSS(source.name, source.url, source.source);
}