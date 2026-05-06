/**
 * 新浪财经爬虫 - 使用 Obscura 浏览器
 *
 * 使用无头浏览器替代原生 fetch，避免反爬检测
 * 通过 JavaScript 直接提取结构化数据
 */
import type { CrawlResult, CrawledPost } from '../../types';
import { logger } from '../../logger';
import { createSupabaseAdmin } from '../../supabase';
import { obscuraFetch } from './mod';

const BASE_URL = 'https://finance.sina.com.cn';
const LIST_URL = 'https://finance.sina.com.cn/roll/index.shtml';

// 提取新闻列表的 JavaScript
const EXTRACT_NEWS_SCRIPT = `JSON.stringify(Array.from(document.querySelectorAll('a[href*="/article/"], a[href*=".sina.com.cn/"]')).filter(a => { const href = a.href; const text = a.textContent?.trim() || ''; return href && text.length > 10 && !href.includes('javascript') && !href.includes('comment') && (href.includes('sina.com.cn') || href.startsWith('/')) && !text.includes('<') && !text.includes('title='); }).slice(0, 20).map(a => ({ title: a.textContent?.trim(), url: a.href })).filter(item => item.title && item.url))`;

export async function crawlSinaFinance(): Promise<CrawlResult> {
  const supabase = createSupabaseAdmin();
  const posts: CrawledPost[] = [];

  logger.info('开始爬取新浪财经 (Obscura)...');

  try {
    // 使用 Obscura 执行 JavaScript 提取结构化数据
    const result = await obscuraFetch(LIST_URL, {
      stealth: true,
      waitUntil: 'networkidle0',
      timeout: 30,
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
      throw new Error(`JSON 解析失败: ${result.content.slice(0, 200)}`);
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
        author: '新浪财经',
        published_at: new Date().toISOString(),
      });
    }

    // 保存到数据库
    if (posts.length > 0) {
      const rawPosts = posts.map(post => ({
        source: 'sina' as const,
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
        logger.error('保存新浪财经数据失败:', error);
      } else {
        logger.info(`成功保存 ${posts.length} 条新浪财经数据`);
      }
    }

    return {
      source: 'sina',
      posts,
      success: true,
      crawledCount: posts.length,
    };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    logger.error(`新浪财经爬取失败: ${message}`);

    return {
      source: 'sina',
      posts,
      success: false,
      error: message,
      crawledCount: 0,
    };
  }
}