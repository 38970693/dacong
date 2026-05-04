// 直接获取 36kr RSS 并插入到 posts 表
const { createClient } = require('@supabase/supabase-js');
const https = require('https');
const { DOMParser } = require('linkedom');

// Supabase 配置
const supabaseUrl = 'https://prszkdbdgffbdqclbgol.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByc3prZGJkZ2ZmYmRxY2xiZ29sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2NzUyMDksImV4cCI6MjA5MzI1MTIwOX0.m2eElXYUlB-XHXZ8w988APQs4u1s2rn5VlIOjn2m_t0';

const supabase = createClient(supabaseUrl, supabaseKey);

function fetch(url) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { 'User-Agent': 'Mozilla/5.0' } }, res => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data));
    }).on('error', reject);
  });
}

function parseDate(dateStr) {
  if (!dateStr) return new Date().toISOString();
  try {
    const date = new Date(dateStr);
    return isNaN(date.getTime()) ? new Date().toISOString() : date.toISOString();
  } catch {
    return new Date().toISOString();
  }
}

async function main() {
  console.log('=== 获取 36kr RSS 数据 ===\n');

  // 获取 RSS
  const xml = await fetch('https://36kr.com/feed');
  console.log('RSS 获取成功，长度:', xml.length);

  // 解析 XML
  const { window: { document } } = new DOMParser().parseFromString(xml, 'text/xml');
  const items = document.querySelectorAll('item');

  const posts = [];
  items.forEach(item => {
    const title = item.querySelector('title')?.textContent?.trim();
    const link = item.querySelector('link')?.textContent?.trim();
    const description = item.querySelector('description')?.textContent || '';
    const pubDate = item.querySelector('pubDate')?.textContent;

    if (title && link) {
      // 清理 HTML 标签
      const content = description.replace(/<[^>]*>/g, '').substring(0, 500);

      posts.push({
        title,
        content,
        source_url: link,
        source: '36kr',
        status: 'approved',
        published_at: parseDate(pubDate),
      });
    }
  });

  console.log(`\n解析到 ${posts.length} 条文章\n`);

  // 显示前 5 条
  console.log('=== 最新文章预览 ===\n');
  posts.slice(0, 5).forEach((p, i) => {
    console.log(`[${i + 1}] ${p.title}`);
    console.log(`    日期: ${p.published_at}`);
    console.log('');
  });

  // 插入到数据库
  console.log('=== 插入数据库 ===\n');

  // 先获取现有 URL
  const { data: existing } = await supabase.from('posts').select('source_url');
  const existingUrls = new Set(existing?.map(p => p.source_url) || []);

  // 过滤掉已存在的
  const newPosts = posts.filter(p => !existingUrls.has(p.source_url));
  console.log(`已有 ${existing.length} 条，过滤后新增 ${newPosts.length} 条`);

  if (newPosts.length > 0) {
    const postsToInsert = newPosts.map(p => ({
      title: p.title,
      content: p.content,
      source: p.source,
      source_url: p.source_url,
      status: p.status,
      created_at: p.published_at,
    }));

    const { error } = await supabase.from('posts').insert(postsToInsert);

    if (error) {
      console.log('插入错误:', error.message);
    } else {
      console.log('插入成功!');
    }
  }

  // 验证结果
  console.log('\n=== 数据库验证 ===\n');
  const { data: allPosts } = await supabase
    .from('posts')
    .select('source, title, created_at')
    .eq('status', 'approved')
    .order('created_at', { ascending: false })
    .limit(10);

  console.log(`posts 表共有 ${allPosts?.length || 0} 条 approved 数据\n`);
  allPosts?.forEach((p, i) => {
    console.log(`[${i + 1}] ${p.source} - ${p.created_at.split('T')[0]} - ${p.title.substring(0, 50)}...`);
  });
}

main().catch(err => {
  console.error('失败:', err);
  process.exit(1);
});