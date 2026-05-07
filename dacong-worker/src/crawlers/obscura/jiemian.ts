/**
 * 界面新闻爬虫 - 使用 Obscura 浏览器
 *
 * 使用无头浏览器替代原生 fetch，避免反爬检测
 */
import type { CrawlResult, CrawledPost } from '../../types';
import { logger } from '../../logger';
import { createSupabaseAdmin } from '../../supabase';
import { obscuraFetch } from './mod';

const BASE_URL = 'https://www.jiemian.com';

// 使用商业分类 (lists/2.html)，文章更多
const LIST_URL = `${BASE_URL}/lists/2.html`;

// 提取新闻列表的 JavaScript - 更精确的选择器
const EXTRACT_NEWS_SCRIPT = `JSON.stringify(Array.from(document.querySelectorAll('.article-list a[href*="/article/"], .news-list a[href*="/article/"], main a[href*="/article/"])).filter(a => {
  const href = a.href;
  const text = a.textContent?.trim() || '';
  const isArticle = href && href.includes('/article/') && !href.includes('javascript') && text.length > 5;
  const isNotNav = !a.closest('nav') && !a.closest('.header') && !a.closest('.footer');
  return isArticle && isNotNav;
}).slice(0, 30).map(a => ({title: a.textContent?.trim(), url: a.href})).filter(item => item.title && item.url && item.title.length > 5))`;

export async function crawlJiemian(): Promise<CrawlResult> {
  const supabase = createSupabaseAdmin();
  const posts: CrawledPost[] = [];

  logger.info('开始爬取界面新闻 (Obscura)...');

  try {
    // 使用 Obscura 执行 JavaScript 提取结构化数据
    // 使用 load 而不是 networkidle0，因为页面可能有持续的网络活动
    const result = await obscuraFetch(LIST_URL, {
      stealth: true,
      waitUntil: 'load',
      timeout: 45,
      eval: EXTRACT_NEWS_SCRIPT,
    });

    if (!result.success) {
      throw new Error(result.error || 'Obscura fetch 失败');
    }

    // 解析 JSON 数据
    let newsItems: Array<{ title: string; url: string }> = [];
    try {
      newsItems = JSON.parse(result.content);
    } catch {
      logger.warn('JSON 解析失败，尝试 HTML 解析');
      return await crawlJiemianHTML();
    }

    logger.info(`提取到 ${newsItems.length} 条新闻`);

    for (const item of newsItems) {
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
        author: '界面新闻',
        published_at: new Date().toISOString(),
      });
    }

    // 保存到数据库
    if (posts.length > 0) {
      const rawPosts = posts.map(post => ({
        source: 'jiemian' as const,
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
        logger.error('保存界面新闻数据失败:', error);
      } else {
        logger.info(`成功保存 ${posts.length} 条界面新闻数据`);
      }
    }

    return {
      source: 'jiemian',
      posts,
      success: true,
      crawledCount: posts.length,
    };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    logger.error(`界面新闻爬取失败: ${message}`);

    return {
      source: 'jiemian',
      posts,
      success: false,
      error: message,
      crawledCount: 0,
    };
  }
}

/**
 * 使用 HTML 解析方式爬取界面新闻
 */
async function crawlJiemianHTML(): Promise<CrawlResult> {
  const supabase = createSupabaseAdmin();
  const posts: CrawledPost[] = [];

  try {
    const result = await obscuraFetch(LIST_URL, {
      stealth: true,
      waitUntil: 'load',
      timeout: 45,
    });

    if (!result.success || !result.content) {
      throw new Error(result.error || '获取页面失败');
    }

    const html = result.content;
    const news = parseJiemianHTML(html);

    logger.info(`HTML 解析到 ${news.length} 条新闻`);

    for (const item of news) {
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
        author: '界面新闻',
        published_at: new Date().toISOString(),
      });
    }

    if (posts.length > 0) {
      const rawPosts = posts.map(post => ({
        source: 'jiemian' as const,
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
        logger.error('保存界面新闻数据失败:', error);
      } else {
        logger.info(`成功保存 ${posts.length} 条界面新闻数据`);
      }
    }

    return {
      source: 'jiemian',
      posts,
      success: true,
      crawledCount: posts.length,
    };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    logger.error(`界面新闻 HTML 解析失败: ${message}`);

    return {
      source: 'jiemian',
      posts,
      success: false,
      error: message,
      crawledCount: 0,
    };
  }
}

/**
 * 解析界面新闻 HTML
 */
function parseJiemianHTML(html: string): Array<{ title: string; url: string }> {
  const news: Array<{ title: string; url: string }> = [];

  // 匹配文章链接模式 - 多种选择器
  const patterns = [
    // 标准文章链接
    /<a[^>]+href=["']([^"']*\/article\/[^"']+)["'][^>]*>\s*([^<]{5,200})/gi,
    // 带 class 的文章链接
    /<a[^>]+class=["'][^"']*(?:article|news|content)[^"']*["'][^>]+href=["']([^"']*\/article\/[^"']+)["']/gi,
  ];

  for (const pattern of patterns) {
    let match;
    while ((match = pattern.exec(html)) !== null && news.length < 50) {
      const url = match[1];
      const titleMatch = match[2] || match[0].match(/>([^<]{5,200})</);
      const title = titleMatch ? titleMatch[1].trim() : '';

      if (url && title && title.length > 5 && !url.includes('javascript') && !url.includes('writer')) {
        news.push({ url, title });
      }
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
