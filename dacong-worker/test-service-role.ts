// 测试 service role key
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://prszkdbdgffbdqclbgol.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByc3prZGJkZ2ZmYmRxY2xiZ29sIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NzY3NTIwOSwiZXhwIjoyMDkzMjUxMjA5fQ.Z2aTbg3xZI0eGPLZ8p9YqN8Xqe1l0xvlJnv6dTh7j2Y'
);

async function test() {
  console.log('测试 service role key...\n');

  // 测试插入
  const { data, error } = await supabase.from('posts').insert({
    title: '测试文章 - ' + new Date().toISOString(),
    content: '这是一篇测试文章',
    source: '36kr',
    source_url: 'https://example.com/test-' + Date.now(),
    status: 'approved'
  }).select();

  console.log('插入结果:', error ? error.message : '成功');
  console.log('数据:', data);

  // 如果成功，删除测试数据
  if (data && data.length > 0) {
    await supabase.from('posts').delete().eq('id', data[0].id);
    console.log('已清理测试数据');
  }
}

test().catch(console.error);