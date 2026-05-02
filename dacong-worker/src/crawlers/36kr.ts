import type { CrawlResult, CrawledPost } from '../types';
import { logger } from '../logger';
import { createSupabaseAdmin } from '../supabase';

const BASE_URL = 'https://36kr.com';
const ARTICLES_URL = `${BASE_URL}/api/articles?per_page=20&page=1`;

export async function crawl36kr(): Promise<CrawlResult> {
  const supabase = createSupabaseAdmin();
  const posts: CrawledPost[] = [];

  logger.info('开始爬取 36kr...');

  try {
    // 36kr 使用 React SSR，我们需要通过 API 获取数据
    const response = await fetch(ARTICLES_URL, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/json',
        'Referer': BASE_URL,
      },
    });

    if (!response.ok) {
      throw new Error(`36kr API 请求失败: ${response.status}`);
    }

    const data = await response.json();
    const items = data.data?.items || [];

    for (const item of items) {
      // 跳过非文章类型
      if (item.item_type !== 'article') continue;

      const publishedAt = item.published_at
        ? new Date(item.published_at * 1000).toISOString()
        : new Date().toISOString();

      posts.push({
        title: item.title?.trim() || '',
        content: item.summary || null,
        source_url: `${BASE_URL}/p/${item.id}.html`,
        author: item.user_info?.name || null,
        published_at: publishedAt,
      });
    }

    // 保存到数据库
    if (posts.length > 0) {
      const rawPosts = posts.map(post => ({
        source: '36kr' as const,
        source_url: post.source_url,
        title: post.title,
        content: post.content,
        author: post.author,
        published_at: post.published_at,
        status: 'pending' as const,
      }));

      // 批量插入，忽略已存在的（根据 source_url）
      const { error } = await supabase
        .from('raw_posts')
        .upsert(rawPosts, {
          onConflict: 'source_url',
          ignoreDuplicates: true
        });

      if (error) {
        logger.error('保存 36kr 数据失败:', error);
      } else {
        logger.info(`成功保存 ${posts.length} 条 36kr 数据`);
      }
    }

    return {
      source: '36kr',
      posts,
      success: true,
      crawledCount: posts.length,
    };

  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    logger.error(`36kr 爬取失败: ${message}`);

    return {
      source: '36kr',
      posts,
      success: false,
      error: message,
      crawledCount: 0,
    };
  }
}