import type { CrawlResult, CrawledPost } from '../types';
import { logger } from '../logger';
import { createSupabaseAdmin } from '../supabase';

const BASE_URL = 'https://www.jiemian.com';
const API_URL = `${BASE_URL}/lists/3.html`;

export async function crawlJiemian(): Promise<CrawlResult> {
  const supabase = createSupabaseAdmin();
  const posts: CrawledPost[] = [];

  logger.info('开始爬取界面新闻...');

  try {
    const response = await fetch(API_URL, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'text/html,application/xhtml+xml',
        'Accept-Language': 'zh-CN,zh;q=0.9',
        'Referer': BASE_URL,
      },
    });

    if (!response.ok) {
      throw new Error(`界面新闻请求失败: ${response.status}`);
    }

    const html = await response.text();

    // 简化解析：从 HTML 中提取链接和标题
    // 界面新闻使用 article 标签包裹内容
    const articleRegex = /<a[^>]*href="(\/article\/[^"]*)"[^>]*class="[^"]*title[^"]*"[^>]*>([^<]*)<\/a>/gi;
    const newsList: { url: string; title: string }[] = [];

    let match;
    while ((match = articleRegex.exec(html)) !== null && newsList.length < 15) {
      const url = match[1];
      const title = match[2].trim();

      if (url && title && title.length > 5) {
        newsList.push({ url, title });
      }
    }

    for (const item of newsList) {
      posts.push({
        title: item.title,
        content: null,
        source_url: `${BASE_URL}${item.url}`,
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
          ignoreDuplicates: true
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
    const message = error instanceof Error ? error.message : 'Unknown error';
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