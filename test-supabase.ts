// 测试 Supabase 连接和数据
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://prszkdbdgffbdqclbgol.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByc3prZGJkZ2ZmYmRxY2xiZ29sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2NzUyMDksImV4cCI6MjA5MzI1MTIwOX0.m2eElXYUlB-XHXZ8w988APQs4u1s2rn5VlIOjn2m_t0';

const supabase = createClient(supabaseUrl, supabaseKey);

async function test() {
  console.log('Testing Supabase connection...\n');

  // 1. 测试连接
  const { data: versionData, error: versionError } = await supabase.rpc('version');
  console.log('1. Connection test:', versionError ? 'FAILED' : 'OK');

  // 2. 查询 posts 表
  const { data: posts, error: postsError } = await supabase
    .from('posts')
    .select('id, title, source, status, created_at')
    .eq('status', 'approved')
    .limit(5);

  console.log('2. Posts query:');
  console.log('   - Error:', postsError ? postsError.message : 'None');
  console.log('   - Count:', posts?.length || 0);
  console.log('   - Data:', posts);

  // 3. 查询所有 posts (不管状态)
  const { data: allPosts, error: allError } = await supabase
    .from('posts')
    .select('id, title, status')
    .limit(5);

  console.log('\n3. All posts (any status):');
  console.log('   - Count:', allPosts?.length || 0);
  console.log('   - Data:', allPosts);

  // 4. 列出所有表
  console.log('\n4. Tables in database:');
  const { data: tables, error: tablesError } = await supabase
    .from('information_schema.tables')
    .select('table_name')
    .eq('table_schema', 'public');

  console.log('   - Error:', tablesError ? tablesError.message : 'None');
  console.log('   - Tables:', tables?.map(t => t.table_name));
}

test().catch(console.error);