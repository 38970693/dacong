import { config } from 'dotenv';
config();

import { logger } from './logger';
import { runCrawlWithHealth, getHealthStatus } from './crawlers/health';
import { runModeration } from './moderator';
import { updateTrendingCache } from './trending';

const CRAWL_INTERVAL = parseInt(process.env.CRAWL_INTERVAL_MINUTES || '5', 10) * 60 * 1000;
const MODERATE_INTERVAL = 30 * 1000;
const TRENDING_INTERVAL = 60 * 1000;
const HEALTH_CHECK_PORT = parseInt(process.env.HEALTH_CHECK_PORT || '8080', 10);

// HTTP 服务器（健康检查）
let httpServer: { close: () => void } | null = null;

async function startHealthServer() {
  try {
    // 尝试使用 Node.js 内置模块创建简单的 HTTP 服务器
    const http = await import('http');

    httpServer = http.createServer((req, res) => {
      const url = new URL(req.url || '/', `http://localhost:${HEALTH_CHECK_PORT}`);

      if (url.pathname === '/health' || url.pathname === '/') {
        const health = getHealthStatus();
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(health, null, 2));
      } else if (url.pathname === '/health/live') {
        res.writeHead(200, { 'Content-Type': 'text/plain' });
        res.end('OK');
      } else if (url.pathname === '/health/ready') {
        const health = getHealthStatus();
        if (health.status === 'down') {
          res.writeHead(503, { 'Content-Type': 'text/plain' });
          res.end('NOT READY');
        } else {
          res.writeHead(200, { 'Content-Type': 'text/plain' });
          res.end('READY');
        }
      } else {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('Not Found');
      }
    });

    httpServer.listen(HEALTH_CHECK_PORT, () => {
      logger.info(`健康检查服务器运行在端口 ${HEALTH_CHECK_PORT}`);
    });
  } catch (error) {
    logger.warn('无法启动健康检查服务器:', error);
  }
}

async function main() {
  logger.info('DaCong Worker 启动...');
  logger.info(`爬虫间隔: ${CRAWL_INTERVAL / 60000} 分钟`);
  logger.info(`审核间隔: ${MODERATE_INTERVAL / 1000} 秒`);
  logger.info(`榜单间隔: ${TRENDING_INTERVAL / 1000} 秒`);

  // 启动健康检查服务器
  await startHealthServer();

  // 立即运行一次
  await runCrawlAndModerate();
  await updateTrendingCache();

  // 设置定时任务
  setInterval(runCrawlAndModerate, CRAWL_INTERVAL);
  setInterval(runModeration, MODERATE_INTERVAL);
  setInterval(updateTrendingCache, TRENDING_INTERVAL);

  logger.info('Worker 运行中...');

  // 优雅关闭
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

async function runCrawlAndModerate() {
  logger.info('=== 爬取 + 审核循环 ===');

  // 1. 爬取数据
  await runCrawlWithHealth();

  // 2. AI 审核
  await runModeration();

  logger.info('=== 爬取 + 审核完成 ===');
}

async function shutdown() {
  logger.info('Worker 关闭中...');

  if (httpServer) {
    httpServer.close();
  }

  process.exit(0);
}

main().catch((error) => {
  logger.error('Worker 启动失败:', error);
  process.exit(1);
});