// 使用 .env 中的 service role key
import { createClient } from '@supabase/supabase-js';
import https from 'https';
import dotenv from 'dotenv';
dotenv.config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

function fetch(url) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { 'User-Agent': 'Mozilla/5.0' } }, res => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data));
    }).on('error', reject);
  });
}

function extractTag(xml, tag) {
  const regex = new RegExp(`<${tag}[^>]*><!\\[CDATA\\[([^\\]]*)\\]\\]><\\/${tag}>|<${tag}[^>]*>([^<]*)<\\/${tag}>`, 'i');
  const match = regex.exec(xml);
  return match ? (match[1] || match[2] || '').trim() : '';
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
  const itemRegex = /<item>([\s\S]*?)<\/item>/gi;
  const posts = [];
  let match;

  while ((match = itemRegex.exec(xml)) !== null) {
    const itemXml = match[1];

    const title = extractTag(itemXml, 'title');
    const link = extractTag(itemXml, 'link');
    const description = extractTag(itemXml, 'description');
    const pubDate = extractTag(itemXml, 'pubDate');

    if (title && link) {
      const content = description.replace(/<[^>]*>/g, '').substring(0, 500);
      posts.push({
        title,
        content,
        source_url: link,
        source: '36kr',
        status: 'approved',
        created_at: parseDate(pubDate),
      });
    }
  }

  console.log(`解析到 ${posts.length} 条文章\n`);

  // 显示前 5 条
  console.log('=== 最新文章预览 ===\n');
  posts.slice(0, 5).forEach((p, i) => {
    console.log(`[${i + 1}] ${p.title}`);
    console.log(`    日期: ${p.created_at}`);
    console.log('');
  });

  // 使用 service role 插入
  console.log('=== 插入数据库 (使用 service role) ===\n');

  const { data: existing } = await supabase.from('posts').select('source_url');
  const existingUrls = new Set(existing?.map(p => p.source_url) || []);
  const newPosts = posts.filter(p => !existingUrls.has(p.source_url));

  console.log(`已有 ${existing.length} 条，新增 ${newPosts.length} 条`);

  if (newPosts.length > 0) {
    const postsToInsert = newPosts.map(p => ({
      title: p.title,
      content: p.content,
      source: p.source,
      source_url: p.source_url,
      status: p.status,
      created_at: p.created_at,
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
    .order('created_at', { ascending: false })
    .limit(10);

  console.log(`posts 表共有 ${allPosts?.length || 0} 条数据\n`);
  allPosts?.forEach((p, i) => {
    console.log(`[${i + 1}] ${p.source} - ${p.created_at.split('T')[0]} - ${p.title.substring(0, 50)}...`);
  });
}

main().catch(err => {
  console.error('失败:', err);
  process.exit(1);
});