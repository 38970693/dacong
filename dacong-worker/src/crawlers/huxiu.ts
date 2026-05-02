import type { CrawlResult, CrawledPost } from '../types';
import { logger } from '../logger';
import { createSupabaseAdmin } from '../supabase';

const BASE_URL = 'https://www.huxiu.com';
const API_URL = `${BASE_URL}/article/listing`;

export async function crawlHuxiu(): Promise<CrawlResult> {
  const supabase = createSupabaseAdmin();
  const posts: CrawledPost[] = [];

  logger.info('开始爬取虎嗅...');

  try {
    // 虎嗅 API
    const response = await fetch(API_URL, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/json, text/plain, */*',
        'Referer': BASE_URL,
        'X-Requested-With': 'XMLHttpRequest',
      },
    });

    if (!response.ok) {
      throw new Error(`虎嗅 API 请求失败: ${response.status}`);
    }

    const data = await response.json();
    const items = data.data?.list || [];

    for (const item of items) {
      const publishedAt = item.publish_time
        ? new Date(item.publish_time * 1000).toISOString()
        : new Date().toISOString();

      posts.push({
        title: item.title?.trim() || '',
        content: item.sub_title || null,
        source_url: `${BASE_URL}/article/${item.aid}.html`,
        author: item.author_name || null,
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
          ignoreDuplicates: true
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
    const message = error instanceof Error ? error.message : 'Unknown error';
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