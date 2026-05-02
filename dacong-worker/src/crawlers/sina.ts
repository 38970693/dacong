import type { CrawlResult, CrawledPost } from '../types';
import { logger } from '../logger';
import { createSupabaseAdmin } from '../supabase';

const BASE_URL = 'https://finance.sina.com.cn';
const API_URL = `${BASE_URL}/roll/index.shtml`;

export async function crawlSinaFinance(): Promise<CrawlResult> {
  const supabase = createSupabaseAdmin();
  const posts: CrawledPost[] = [];

  logger.info('开始爬取新浪财经...');

  try {
    // 新浪财经使用 HTML，需要解析
    const response = await fetch(API_URL, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'text/html,application/xhtml+xml',
        'Accept-Language': 'zh-CN,zh;q=0.9',
        'Referer': BASE_URL,
      },
    });

    if (!response.ok) {
      throw new Error(`新浪财经请求失败: ${response.status}`);
    }

    const html = await response.text();

    // 解析新闻列表（简化版，实际需要更复杂的解析）
    const titleRegex = /<a[^>]*href="([^"]*channel=[^"]*)"[^>]*>([^<]*)<\/a>/g;
    const newsList: { url: string; title: string }[] = [];

    let match;
    while ((match = titleRegex.exec(html)) !== null && newsList.length < 20) {
      const url = match[1];
      const title = match[2].trim();

      if (url && title && title.length > 5) {
        newsList.push({ url, title });
      }
    }

    // 简单处理：直接使用找到的标题
    for (const item of newsList) {
      posts.push({
        title: item.title,
        content: null,
        source_url: item.url.startsWith('http') ? item.url : `${BASE_URL}${item.url}`,
        author: null,
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
          ignoreDuplicates: true
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
    const message = error instanceof Error ? error.message : 'Unknown error';
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