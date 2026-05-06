/**
 * 网易科技爬虫 - 使用 Obscura 浏览器
 *
 * 使用无头浏览器替代原生 fetch，避免反爬检测
 */
import type { CrawlResult, CrawledPost } from '../../types';
import { logger } from '../../logger';
import { createSupabaseAdmin } from '../../supabase';
import { obscuraFetch } from './mod';

const BASE_URL = 'https://tech.163.com';

// 提取新闻列表的 JavaScript - 针对网易科技页面结构调整
const EXTRACT_NEWS_SCRIPT = `JSON.stringify(Array.from(document.querySelectorAll('a')).filter(a => { const href = a.href; const text = a.textContent?.trim() || ''; return href && text.length > 10 && href.includes('163.com') && !href.includes('javascript') && !href.includes('photo') && (href.match(/\\/\\d{6,}\\.html/) || href.includes('article')); }).slice(0, 20).map(a => ({title: a.textContent?.trim(), url: href})).filter(item => item.title && item.url))`;

export async function crawl163Tech(): Promise<CrawlResult> {
  const supabase = createSupabaseAdmin();
  const posts: CrawledPost[] = [];

  logger.info('开始爬取网易科技 (Obscura)...');

  try {
    // 首先尝试使用 HTML 解析
    const result = await obscuraFetch(`${BASE_URL}/`, {
      stealth: true,
      waitUntil: 'networkidle0',
      timeout: 30,
    });

    if (!result.success || !result.content) {
      throw new Error(result.error || '获取页面失败');
    }

    const html = result.content;
    const news = parse163HTML(html);

    logger.info(`HTML 解析到 ${news.length} 条新闻`);

    for (const item of news) {
      // 处理 URL
      let url = item.url;
      if (url.startsWith('//')) {
        url = 'https:' + url;
      } else if (url.startsWith('/')) {
        url = `${BASE_URL}${url}`;
      }

      posts.push({
        title: item.title,
        content: null,
        source_url: url,
        author: '网易科技',
        published_at: new Date().toISOString(),
      });
    }

    // 保存到数据库
    if (posts.length > 0) {
      const rawPosts = posts.map(post => ({
        source: '163tech' as const,
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
          ignoreDuplicates: true,
        });

      if (error) {
        logger.error('保存网易科技数据失败:', error);
      } else {
        logger.info(`成功保存 ${posts.length} 条网易科技数据`);
      }
    }

    return {
      source: '163tech',
      posts,
      success: true,
      crawledCount: posts.length,
    };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    logger.error(`网易科技爬取失败: ${message}`);

    return {
      source: '163tech',
      posts,
      success: false,
      error: message,
      crawledCount: 0,
    };
  }
}

/**
 * 解析网易科技 HTML
 */
function parse163HTML(html: string): Array<{ title: string; url: string }> {
  const news: Array<{ title: string; url: string }> = [];

  // 匹配文章链接模式
  // /digit/2026/05-06/DOCAOS or /article/...
  const pattern = /<a[^>]+href=["']([^"']*(?:\/\d{6,}\/|\/article\/)[^"']+)["'][^>]*>([^<]{5,60})/gi;

  let match;
  while ((match = pattern.exec(html)) !== null && news.length < 20) {
    const url = match[1];
    const title = match[2].trim();

    if (url && title && title.length > 5 && !url.includes('javascript')) {
      news.push({ url, title });
    }
  }

  // 去重
  const seen = new Set<string>();
  return news.filter(item => {
    if (seen.has(item.url)) return false;
    seen.add(item.url);
    return true;
  });
}
