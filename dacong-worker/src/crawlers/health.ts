import { crawlAll } from './index';
import { crawlAllRSS } from './rss';
import { logger } from '../logger';
import { createSupabaseAdmin } from '../supabase';

// 健康状态
interface HealthStatus {
  status: 'healthy' | 'degraded' | 'down';
  timestamp: string;
  lastCrawl: {
    time: string;
    success: boolean;
    totalCrawled: number;
    sources: string[];
  } | null;
  errors: string[];
  uptime: number;
}

// 全局状态
let lastCrawlTime: Date | null = null;
let lastCrawlSuccess = false;
let lastCrawlTotal = 0;
let lastCrawlSources: string[] = [];
let startTime = Date.now();
let recentErrors: string[] = [];

// 直接打印到 stdout（确保 GitHub Actions 能看到）
function log(...args: unknown[]) {
  console.log('[Crawler]', new Date().toISOString(), ...args);
}

// 爬取并更新状态
export async function runCrawlWithHealth(): Promise<void> {
  const start = Date.now();

  try {
    log('开始爬取...');

    // 同时运行 HTTP 爬虫和 RSS 爬虫
    const [htmlResults, rssResults] = await Promise.allSettled([
      crawlAll(),
      crawlAllRSS(),
    ]);

    const htmlData = htmlResults.status === 'fulfilled' ? htmlResults.value : [];
    const rssData = rssResults.status === 'fulfilled' ? rssResults.value : [];

    // 统计成功的数据源
    const successfulSources = [
      ...htmlData.filter(r => r.success).map(r => r.source),
      ...rssData.filter(r => r.success).map(r => r.source),
    ];

    // 更新状态
    lastCrawlTime = new Date();
    lastCrawlSuccess = successfulSources.length > 0;
    lastCrawlTotal = htmlData.reduce((sum, r) => sum + r.crawledCount, 0) +
                     rssData.reduce((sum, r) => sum + r.crawledCount, 0);
    lastCrawlSources = successfulSources;

    // 收集错误
    const errors = [
      ...htmlData.filter(r => !r.success).map(r => `${r.source}: ${r.error}`),
      ...rssData.filter(r => !r.success).map(r => `${r.source}: ${r.error}`),
    ];

    // 保留最近 10 条错误
    recentErrors = [...errors, ...recentErrors].slice(0, 10);

    const duration = Date.now() - start;
    log(`爬取完成: ${lastCrawlTotal} 条数据, ${successfulSources.length} 个来源成功, 耗时 ${duration}ms`);

    // 如果有数据，同步到 posts 表
    if (lastCrawlTotal > 0) {
      await syncToPosts();
    }

  } catch (error) {
    lastCrawlTime = new Date();
    lastCrawlSuccess = false;

    const errorMsg = error instanceof Error ? error.message : 'Unknown error';
    recentErrors = [errorMsg, ...recentErrors].slice(0, 10);

    console.error('[Crawler] 爬取失败:', errorMsg);
  }
}

// 将 raw_posts 同步到 posts 表
async function syncToPosts() {
  const supabase = createSupabaseAdmin();

  try {
    // 获取所有待发布的 raw_posts
    const { data: rawPosts, error } = await supabase
      .from('raw_posts')
      .select('*')
      .eq('status', 'pending')
      .limit(50);

    if (error) {
      console.error('[Crawler] 获取 raw_posts 失败:', error);
      return;
    }

    if (!rawPosts || rawPosts.length === 0) {
      log('没有待发布的数据');
      return;
    }

    log(`准备发布 ${rawPosts.length} 条数据到 posts 表`);

    // 转换并批量插入
    const posts = rawPosts.map(raw => ({
      raw_post_id: raw.id,
      title: raw.title,
      content: raw.content,
      source: raw.source,
      source_url: raw.source_url,
      status: 'approved' as const,
    }));

    // 使用 upsert 避免重复
    const { error: insertError } = await supabase
      .from('posts')
      .upsert(posts, {
        onConflict: 'raw_post_id',
        ignoreDuplicates: false
      });

    if (insertError) {
      console.error('[Crawler] 发布数据失败:', insertError);
      return;
    }

    log(`成功发布 ${rawPosts.length} 条数据到 posts 表`);

  } catch (err) {
    console.error('[Crawler] syncToPosts 异常:', err);
  }
}

// 获取健康状态
export function getHealthStatus(): HealthStatus {
  const now = Date.now();
  const uptimeSeconds = Math.floor((now - startTime) / 1000);

  // 判断状态
  let status: 'healthy' | 'degraded' | 'down' = 'healthy';

  if (!lastCrawlSuccess) {
    status = 'down';
  } else if (recentErrors.length > 0) {
    status = 'degraded';
  } else if (lastCrawlTime) {
    // 如果上次爬取超过 10 分钟，状态降级
    const timeSinceLastCrawl = now - lastCrawlTime.getTime();
    if (timeSinceLastCrawl > 10 * 60 * 1000) {
      status = 'degraded';
    }
  }

  return {
    status,
    timestamp: new Date().toISOString(),
    lastCrawl: lastCrawlTime ? {
      time: lastCrawlTime.toISOString(),
      success: lastCrawlSuccess,
      totalCrawled: lastCrawlTotal,
      sources: lastCrawlSources,
    } : null,
    errors: recentErrors,
    uptime: uptimeSeconds,
  };
}

// 健康检查处理器（供 Express/Fastify 使用）
export function healthHandler(): { status: number; body: HealthStatus } {
  const health = getHealthStatus();
  const statusCode = health.status === 'down' ? 503 : health.status === 'degraded' ? 200 : 200;

  return {
    status: statusCode,
    body: health,
  };
}

// 主入口 - 直接运行此文件时执行爬虫
runCrawlWithHealth().catch((err) => {
  console.error('[Crawler] 主入口执行失败:', err);
  process.exit(1);
});