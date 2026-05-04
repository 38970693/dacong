// RSS 爬虫测试
import { crawlAllRSS } from './src/crawlers/rss';

console.log('=== 开始 RSS 爬取 ===\n');

crawlAllRSS()
  .then(results => {
    console.log('\n=== 结果汇总 ===');
    results.forEach(r => {
      const status = r.success ? '✓' : '✗';
      console.log(`${status} ${r.source}: ${r.crawledCount} 条`);
      if (r.error) console.log(`  错误: ${r.error}`);
    });

    const total = results.reduce((sum, r) => sum + r.crawledCount, 0);
    console.log(`\n总计: ${total} 条新数据`);
    process.exit(0);
  })
  .catch(err => {
    console.error('失败:', err);
    process.exit(1);
  });