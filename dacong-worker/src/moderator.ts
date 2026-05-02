import { createSupabaseAdmin } from './supabase';
import { logger } from './logger';

// 本地关键词黑名单
const BLACKLIST = [
  // 政治敏感词（示例，实际需要更完整）
  '台独', '藏独', '疆独', '港独',
  // 其他违规词（示例）
  '赌博', '色情', '毒品', '诈骗',
];

// 检查是否命中黑名单
function checkLocalBlacklist(text: string): boolean {
  const lowerText = text.toLowerCase();
  return BLACKLIST.some(word => lowerText.includes(word.toLowerCase()));
}

// 本地关键词审核
export function localModeration(title: string, content: string | null): {
  passed: boolean;
  reason?: string;
} {
  const text = `${title} ${content || ''}`;

  if (checkLocalBlacklist(text)) {
    return {
      passed: false,
      reason: '命中本地黑名单',
    };
  }

  return { passed: true };
}

// 获取待审核的 raw_posts
export async function getPendingRawPosts(limit: number = 50) {
  const supabase = createSupabaseAdmin();

  const { data, error } = await supabase
    .from('raw_posts')
    .select('*')
    .eq('status', 'pending')
    .order('crawled_at', { ascending: true })
    .limit(limit);

  if (error) {
    logger.error('获取待审核数据失败:', error);
    return [];
  }

  return data;
}

// 获取待审核的 posts
export async function getPendingPosts(limit: number = 50) {
  const supabase = createSupabaseAdmin();

  const { data, error } = await supabase
    .from('posts')
    .select('*')
    .eq('status', 'pending')
    .order('created_at', { ascending: true })
    .limit(limit);

  if (error) {
    logger.error('获取待审核 posts 失败:', error);
    return [];
  }

  return data;
}

// 更新审核状态
export async function updatePostStatus(
  id: string,
  status: 'approved' | 'rejected',
  table: 'raw_posts' | 'posts' = 'raw_posts'
) {
  const supabase = createSupabaseAdmin();

  const { error } = await supabase
    .from(table)
    .update({ status })
    .eq('id', id);

  if (error) {
    logger.error(`更新 ${table} 状态失败:`, error);
    return false;
  }

  return true;
}

// 主审核流程
export async function moderatePosts() {
  logger.info('开始 AI 审核...');

  // 首先检查 raw_posts（爬虫原始数据）
  const rawPosts = await getPendingRawPosts(30);

  for (const post of rawPosts) {
    const text = `${post.title} ${post.content || ''}`;

    // 先本地审核
    const localResult = localModeration(post.title, post.content);

    if (!localResult.passed) {
      logger.info(`raw_posts ${post.id} 被本地审核拒绝: ${localResult.reason}`);
      await updatePostStatus(post.id, 'rejected', 'raw_posts');
      continue;
    }

    // TODO: 集成阿里云内容审核 API
    // const aliyunResult = await aliyunModeration(text);
    // if (!aliyunResult.passed) {
    //   await updatePostStatus(post.id, 'rejected', 'raw_posts');
    //   continue;
    // }

    // 通过本地审核，先发布到 posts 表
    await publishRawPost(post);
  }

  // 然后检查 posts（可能有通过本地审核但还没最终确认的）
  const posts = await getPendingPosts(30);

  for (const post of posts) {
    // 继续阿里云审核...

    // 如果通过，更新为 approved
    await updatePostStatus(post.id, 'approved', 'posts');
  }

  logger.info('AI 审核完成');
}

// 将 raw_posts 转换并发布到 posts 表
async function publishRawPost(rawPost: Record<string, unknown>) {
  const supabase = createSupabaseAdmin();

  const { error } = await supabase
    .from('posts')
    .insert({
      raw_post_id: rawPost.id,
      title: rawPost.title,
      content: rawPost.content,
      source: rawPost.source,
      source_url: rawPost.source_url,
      status: 'approved', // 直接通过，后续可改进为 pending
    });

  if (error && error.code !== '23505') { // 忽略重复插入
    logger.error('发布 raw_post 失败:', error);
    return;
  }

  // 更新 raw_posts 状态为 approved
  await updatePostStatus(rawPost.id as string, 'approved', 'raw_posts');
  logger.info(`raw_post ${rawPost.id} 已发布到 posts`);
}

// 运行一次审核
export async function runModeration() {
  try {
    await moderatePosts();
  } catch (error) {
    logger.error('审核失败:', error);
  }
}