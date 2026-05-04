import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://prszkdbdgffbdqclbgol.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByc3prZGJkZ2ZmYmRxY2xiZ29sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2NzUyMDksImV4cCI6MjA5MzI1MTIwOX0.m2eElXYUlB-XHXZ8w988APQs4u1s2rn5VlIOjn2m_t0'
);

async function check() {
  // 检查 posts 表的所有数据
  const { data: posts, error } = await supabase
    .from('posts')
    .select('id, title, source, status, created_at, url, content')
    .order('created_at', { ascending: false });

  console.log('=== 全部数据 ===\n');
  posts?.forEach(p => {
    console.log(`[${p.status}] ${p.created_at.split('T')[0]} ${p.source}`);
    console.log(`  标题: ${p.title}`);
    console.log(`  URL: ${p.url || '无'}`);
    console.log(`  内容长度: ${p.content?.length || 0} 字符`);
    console.log('');
  });

  // 统计
  const approved = posts?.filter(p => p.status === 'approved').length || 0;
  const pending = posts?.filter(p => p.status === 'pending').length || 0;
  const rejected = posts?.filter(p => p.status === 'rejected').length || 0;

  console.log('=== 状态统计 ===');
  console.log(`approved: ${approved}`);
  console.log(`pending: ${pending}`);
  console.log(`rejected: ${rejected}`);
  console.log(`总计: ${posts?.length || 0}`);
}

check().catch(console.error);