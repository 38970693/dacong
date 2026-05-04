// 直接运行爬虫测试
const { crawlAll } = require('./src/crawlers/index.ts');

console.log('开始运行爬虫...\n');

crawlAll()
  .then(results => {
    console.log('\n=== 爬取结果 ===');
    results.forEach(r => {
      console.log(`[${r.success ? '✓' : '✗'}] ${r.source}: ${r.crawledCount} 条 ${r.error ? '(' + r.error + ')' : ''}`);
    });

    const total = results.reduce((sum, r) => sum + r.crawledCount, 0);
    console.log(`\n总计: ${total} 条`);
    process.exit(0);
  })
  .catch(err => {
    console.error('运行失败:', err);
    process.exit(1);
  });