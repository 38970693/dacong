import { crawl36kr } from './36kr';
import { crawlHuxiu } from './huxiu';
import { crawlSinaFinance } from './obscura/sina';
import { crawl163Tech } from './obscura/163tech';
import { crawlJiemian } from './obscura/jiemian';
import type { CrawlResult } from '../types';
import { logger } from '../logger';
import { createSupabaseAdmin } from '../supabase';

// 可用的爬虫列表
export const crawlers = {
  '36kr': crawl36kr,
  'huxiu': crawlHuxiu,
  'sina': crawlSinaFinance,
  '163tech': crawl163Tech,
  'jiemian': crawlJiemian,
};

export type CrawlerName = keyof typeof crawlers;

// 获取所有可用的数据源名称
export function getAvailableSources(): CrawlerName[] {
  return Object.keys(crawlers) as CrawlerName[];
}

// 爬取所有数据源
export async function crawlAll(): Promise<CrawlResult[]> {
  logger.info('开始全量爬取...');

  const sources = getAvailableSources();
  const results: CrawlResult[] = [];

  for (const source of sources) {
    try {
      const crawler = crawlers[source];
      const result = await crawler();
      results.push(result);
    } catch (error) {
      const msg = error instanceof Error ? error.message : String(error);
      console.error(`[crawlAll] 爬取 ${source} 失败:`, msg, error);
      logger.error(`爬取 ${source} 失败:`, msg, error);
      results.push({
        source,
        posts: [],
        success: false,
        error: msg,
        crawledCount: 0,
      });
    }
  }

  // 统计
  const totalCrawled = results.reduce((sum, r) => sum + r.crawledCount, 0);
  const successCount = results.filter(r => r.success).length;

  logger.info(`爬取完成: ${totalCrawled} 条数据, ${successCount}/${sources.length} 个来源成功`);

  return results;
}

// 爬取指定数据源
export async function crawlSource(source: CrawlerName): Promise<CrawlResult> {
  const crawler = crawlers[source];
  if (!crawler) {
    return {
      source,
      posts: [],
      success: false,
      error: `Unknown source: ${source}`,
      crawledCount: 0,
    };
  }

  const result = await crawler();

  // 如果成功，发布到 posts 表
  if (result.success && result.posts.length > 0) {
    await publishPosts(source);
  }

  return result;
}

// 将爬取的数据快速发布到 posts 表
async function publishPosts(source: string) {
  const supabase = createSupabaseAdmin();

  // 获取该来源的待审核数据
  const { data: rawPosts, error } = await supabase
    .from('raw_posts')
    .select('*')
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