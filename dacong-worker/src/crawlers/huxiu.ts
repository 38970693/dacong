import type { CrawlResult, CrawledPost } from '../types';
import { logger } from '../logger';
import { createSupabaseAdmin } from '../supabase';
import { obscuraFetch } from './obscura/mod';

const BASE_URL = 'https://www.huxiu.com';
const LIST_URL = `${BASE_URL}/`;

/**
 * 虎嗅爬虫 - 使用 Obscura 浏览器
 *
 * 使用无头浏览器避免 API 反爬检测
 */
export async function crawlHuxiu(): Promise<CrawlResult> {
  const supabase = createSupabaseAdmin();
  const posts: CrawledPost[] = [];

  logger.info('开始爬取虎嗅 (Obscura)...');

  try {
    // 使用 Obscura 获取页面并执行 JavaScript 提取数据
    const result = await obscuraFetch(LIST_URL, {
      stealth: true,
      waitUntil: 'load',
      timeout: 45,
      eval: `JSON.stringify(Array.from(document.querySelectorAll('.hp-mod-articlelist a[data-type="article"]')).slice(0, 30).map(a => ({
        title: a.querySelector('.hp-mod-title')?.textContent?.trim() || '',
        url: a.href,
        author: a.querySelector('.hp-mod-author span')?.textContent?.trim() || null,
        time: a.querySelector('.hp-mod-time')?.textContent?.trim() || ''
      })).filter(item => item.title && item.url))`,
    });

    if (!result.success) {
      throw new Error(result.error || 'Obscura fetch 失败');
    }

    // 解析 JSON 数据
    let items: Array<{ title: string; url: string; author: string | null; time: string }> = [];
    try {
      items = JSON.parse(result.content);
    } catch {
      logger.warn('虎嗅 JSON 解析失败，尝试 HTML 解析');
      return await crawlHuxiuHTML();
    }

    logger.info(`提取到 ${items.length} 条虎嗅文章`);

    for (const item of items) {
      // 处理 URL
      let url = item.url;
      if (url.startsWith('//')) {
        url = 'https:' + url;
      } else if (url.startsWith('/')) {
        url = `${BASE_URL}${url}`;
      }

      // 解析时间
      let publishedAt = new Date().toISOString();
      if (item.time) {
        const timeStr = item.time.trim();
        // 尝试解析 "3小时前", "昨天", "2024-01-01" 等格式
        if (timeStr.includes('小时')) {
          const hours = parseInt(timeStr.match(/\d+/)?.[0] || '0');
          publishedAt = new Date(Date.now() - hours * 3600 * 1000).toISOString();
        } else if (timeStr.includes('昨天')) {
          const yesterday = new Date();
          yesterday.setDate(yesterday.getDate() - 1);
          publishedAt = yesterday.toISOString();
        } else if (timeStr.includes('-')) {
          publishedAt = new Date(timeStr).toISOString();
        }
      }

      posts.push({
        title: item.title,
        content: null,
        source_url: url,
        author: item.author || '虎嗅',
        published_at: publishedAt,
      });
    }

    // 保存到数据库
    if (posts.length > 0) {
      const rawPosts = posts.map(post => ({
        source: 'huxiu' as const,
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
        logger.error('保存虎嗅数据失败:', error);
      } else {
        logger.info(`成功保存 ${posts.length} 条虎嗅数据`);
      }
    }

    return {
      source: 'huxiu',
      posts,
      success: true,
      crawledCount: posts.length,
    };

  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    logger.error(`虎嗅爬取失败: ${message}`);

    return {
      source: 'huxiu',
      posts,
      success: false,
      error: message,
      crawledCount: 0,
    };
  }
}

/**
 * 使用 HTML 解析方式爬取虎嗅
 */
async function crawlHuxiuHTML(): Promise<CrawlResult> {
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
    const articles = parseHuxiuHTML(html);

    logger.info(`HTML 解析到 ${articles.length} 条虎嗅文章`);

    for (const item of articles) {
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
        author: item.author || '虎嗅',
        published_at: item.time || new Date().toISOString(),
      });
    }

    if (posts.length > 0) {
      const rawPosts = posts.map(post => ({
        source: 'huxiu' as const,
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
        logger.error('保存虎嗅数据失败:', error);
      } else {
        logger.info(`成功保存 ${posts.length} 条虎嗅数据`);
      }
    }

    return {
      source: 'huxiu',
      posts,
      success: true,
      crawledCount: posts.length,
    };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    logger.error(`虎嗅 HTML 解析失败: ${message}`);

    return {
      source: 'huxiu',
      posts,
      success: false,
      error: message,
      crawledCount: 0,
    };
  }
}

/**
 * 解析虎嗅 HTML
 */
function parseHuxiuHTML(html: string): Array<{ title: string; url: string; author: string | null; time: string | null }> {
  const articles: Array<{ title: string; url: string; author: string | null; time: string | null }> = [];

  // 匹配文章链接
  const pattern = /<a[^>]+href=["']([^"']*\/article\/[^"']+)["'][^>]*>[\s\S]*?<span[^>]*class="[^"]*title[^"]*"[^>]*>([^<]+)<\/span>/gi;

  let match;
  while ((match = pattern.exec(html)) !== null && articles.length < 30) {
    const url = match[1];
    const title = match[2].trim();

    if (url && title && title.length > 5 && !url.includes('javascript')) {
      articles.push({ url, title, author: null, time: null });
    }
  }

  // 去重
  const seen = new Set<string>();
  return articles.filter(item => {
    if (seen.has(item.url)) return false;
    seen.add(item.url);
    return true;
  });
}