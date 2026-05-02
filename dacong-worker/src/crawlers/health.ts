import { crawlAll } from './index';
import { crawlAllRSS } from './rss';
import { logger } from '../logger';

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

// 爬取并更新状态
export async function runCrawlWithHealth(): Promise<void> {
  const start = Date.now();

  try {
    logger.info('开始爬取...');

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
    logger.info(`爬取完成: ${lastCrawlTotal} 条数据, ${successfulSources.length} 个来源成功, 耗时 ${duration}ms`);

  } catch (error) {
    lastCrawlTime = new Date();
    lastCrawlSuccess = false;

    const errorMsg = error instanceof Error ? error.message : 'Unknown error';
    recentErrors = [errorMsg, ...recentErrors].slice(0, 10);

    logger.error('爬取失败:', error);
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