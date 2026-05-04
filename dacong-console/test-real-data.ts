// 测试真实数据
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://prszkdbdgffbdqclbgol.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByc3prZGJkZ2ZmYmRxY2xiZ29sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2NzUyMDksImV4cCI6MjA5MzI1MTIwOX0.m2eElXYUlB-XHXZ8w988APQs4u1s2rn5VlIOjn2m_t0';

async function test() {
  console.log('=== Supabase 真实数据测试 ===\n');

  const supabase = createClient(supabaseUrl, supabaseKey);

  // 1. 测试连接
  console.log('1. 测试连接...');
  const { data: versionData, error: versionError } = await supabase.rpc('version');
  console.log(`   结果: ${versionError ? '失败 - ' + versionError.message : '成功'}\n`);

  // 2. 查询 posts 表结构
  console.log('2. Posts 表结构:');
  const { data: columns, error: colError } = await supabase
    .from('information_schema.columns')
    .select('column_name, data_type')
    .eq('table_name', 'posts')
    .eq('table_schema', 'public')
    .order('ordinal_position');

  if (colError) {
    console.log(`   错误: ${colError.message}`);
  } else {
    console.log(`   列数: ${columns?.length || 0}`);
    columns?.slice(0, 10).forEach(col => {
      console.log(`   - ${col.column_name}: ${col.data_type}`);
    });
  }
  console.log('');

  // 3. 查询所有 posts (任何状态)
  console.log('3. 查询所有 posts:');
  const { data: allPosts, error: allError } = await supabase
    .from('posts')
    .select('id, title, source, status, created_at')
    .order('created_at', { ascending: false })
    .limit(5);

  console.log(`   总数: ${allPosts?.length || 0}`);
  if (allPosts && allPosts.length > 0) {
    allPosts.forEach((p, i) => {
      console.log(`   [${i + 1}] ${p.title?.substring(0, 40) || '无标题'}...`);
      console.log(`       来源: ${p.source}, 状态: ${p.status}`);
      console.log(`       时间: ${p.created_at}`);
    });
  }
  if (allError) console.log(`   错误: ${allError.message}`);
  console.log('');

  // 4. 查询 approved 状态的 posts
  console.log('4. 查询已批准 posts (status = approved):');
  const { data: approvedPosts, error: approvedError } = await supabase
    .from('posts')
    .select('id, title, source, status, created_at')
    .eq('status', 'approved')
    .order('created_at', { ascending: false })
    .limit(5);

  console.log(`   总数: ${approvedPosts?.length || 0}`);
  if (approvedPosts && approvedPosts.length > 0) {
    approvedPosts.forEach((p, i) => {
      console.log(`   [${i + 1}] ${p.title?.substring(0, 40) || '无标题'}...`);
    });
  }
  if (approvedError) console.log(`   错误: ${approvedError.message}`);
  console.log('');

  // 5. 统计各状态数量
  console.log('5. 状态统计:');
  const { data: statusStats, error: statsError } = await supabase
    .from('posts')
    .select('status');

  if (statusStats) {
    const counts = statusStats.reduce((acc, p) => {
      acc[p.status] = (acc[p.status] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);
    console.log(`   状态分布: ${JSON.stringify(counts)}`);
    console.log(`   总计: ${statusStats.length}`);
  } else {
    console.log(`   错误: ${statsError?.message}`);
  }
  console.log('');

  // 6. 检查 RLS 策略
  console.log('6. RLS 策略:');
  const { data: policies, error: policyError } = await supabase
    .from('pg_policies')
    .select('policyname, cmd, qual')
    .eq('tablename', 'posts');

  if (policyError) {
    console.log(`   无法查询策略: ${policyError.message}`);
  } else if (policies && policies.length > 0) {
    console.log(`   策略数量: ${policies.length}`);
    policies.forEach(p => {
      console.log(`   - ${p.policyname}: ${p.cmd}`);
    });
  } else {
    console.log('   未找到策略');
  }
  console.log('');

  // 7. 检查用户认证状态
  console.log('7. 认证状态:');
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  console.log(`   匿名访问: ${!authError && !user ? '可以' : '需要检查'}`);

  console.log('\n=== 测试完成 ===');
}

test().catch(console.error);