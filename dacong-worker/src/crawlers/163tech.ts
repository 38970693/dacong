import type { CrawlResult, CrawledPost } from '../types';
import { logger } from '../logger';
import { createSupabaseAdmin } from '../supabase';

const BASE_URL = 'https://tech.163.com';
const API_URL = `${BASE_URL}/special/blockdata?callback=callback&toppos=0&sizes=20&ckid=`;

export async function crawl163Tech(): Promise<CrawlResult> {
  const supabase = createSupabaseAdmin();
  const posts: CrawledPost[] = [];

  logger.info('开始爬取网易科技...');

  try {
    const response = await fetch(API_URL, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/json, text/javascript, */*',
        'Referer': BASE_URL,
      },
    });

    if (!response.ok) {
      throw new Error(`网易科技请求失败: ${response.status}`);
    }

    const text = await response.text();

    // 解析 JSONP 响应
    const jsonStr = text.replace(/^callback\(|\);?$/g, '');
    const data = JSON.parse(jsonStr);

    const items = data.map((item: Record<string, string>) => ({
      title: item.title || item.docdesc || '',
      url: item.url || item.docurl || '',
      docfrom: item.docfrom || '',
      time: item.pdatetime || new Date().toISOString(),
    }));

    for (const item of items) {
      if (!item.title || !item.url) continue;

      posts.push({
        title: item.title.trim(),
        content: null,
        source_url: item.url.startsWith('http') ? item.url : `${BASE_URL}${item.url}`,
        author: item.docfrom || null,
        published_at: item.time,
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
          ignoreDuplicates: true
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
    const message = error instanceof Error ? error.message : 'Unknown error';
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