import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function check() {
  // 用 service role 查询所有数据
  const { data, error } = await supabase
    .from('posts')
    .select('id, source, title, created_at')
    .order('created_at', { ascending: false });

  console.log('=== posts 表数据 ===');
  console.log('总数:', data?.length || 0);
  console.log('错误:', error?.message || '无');

  data?.forEach((p, i) => {
    console.log(`[${i + 1}] ${p.source} | ${p.created_at.split('T')[0]} | ${p.title.substring(0, 60)}`);
  });
}

check();