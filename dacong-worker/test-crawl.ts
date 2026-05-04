// 简单爬虫测试脚本
import { crawl36kr } from './src/crawlers/36kr';
import { crawlHuxiu } from './src/crawlers/huxiu';
import { createSupabaseAdmin } from './src/supabase';
import { logger } from './src/logger';

const supabase = createSupabaseAdmin();

async function test() {
  console.log('=== 测试爬虫 ===\n');

  // 1. 先清空旧数据
  console.log('1. 清空旧数据...');
  await supabase.from('raw_posts').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('posts').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  console.log('   ✓ 已清空\n');

  // 2. 爬取 36kr
  console.log('2. 爬取 36kr...');
  const kr36Result = await crawl36kr();
  console.log(`   ${kr36Result.success ? '✓' : '✗'} 36kr: ${kr36Result.crawledCount} 条`);
  if (kr36Result.error) console.log(`   错误: ${kr36Result.error}`);
  console.log('');

  // 3. 爬取 虎嗅
  console.log('3. 爬取 虎嗅...');
  const huxiuResult = await crawlHuxiu();
  console.log(`   ${huxiuResult.success ? '✓' : '✗'} 虎嗅: ${huxiuResult.crawledCount} 条`);
  if (huxiuResult.error) console.log(`   错误: ${huxiuResult.error}`);
  console.log('');

  // 4. 检查结果
  console.log('4. 检查数据库...');
  const { data: rawPosts } = await supabase
    .from('raw_posts')
    .select('source, status, title')
    .order('created_at', { ascending: false });

  const bySource = {};
  rawPosts?.forEach(p => {
    bySource[p.source] = (bySource[p.source] || 0) + 1;
  });

  console.log('   raw_posts 表:');
  Object.entries(bySource).forEach(([source, count]) => {
    console.log(`   - ${source}: ${count} 条`);
  });

  const total = rawPosts?.length || 0;
  console.log(`   总计: ${total} 条\n`);

  console.log('5. 显示样本数据...');
  rawPosts?.slice(0, 5).forEach((p, i) => {
    console.log(`   [${i + 1}] ${p.source} - ${p.title?.substring(0, 50)}...`);
  });
}

test().catch(err => {
  console.error('失败:', err);
  process.exit(1);
});