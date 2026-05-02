import { createSupabaseAdmin } from './supabase';
import { logger } from './logger';

// 榜单计算公式
// score = (views * 0.3 + likes * 0.5 + comments * 0.2) * time_decay
// time_decay = exp(-age_hours / 6)  // 6小时半衰期

interface TrendingItem {
  post_id: string;
  score: number;
}

// 计算单条帖子的热度分数
function calculateScore(views: number, likes: number, comments: number, createdAt: Date): number {
  const baseScore = views * 0.3 + likes * 0.5 + comments * 0.2;

  // 时间衰减：6小时半衰期
  const ageHours = (Date.now() - createdAt.getTime()) / (1000 * 60 * 60);
  const decay = Math.exp(-ageHours / 6);

  return baseScore * decay;
}

// 计算综合热榜
export async function calculateHotTrending(limit: number = 50): Promise<TrendingItem[]> {
  const supabase = createSupabaseAdmin();

  // 获取最近 24 小时的数据
  const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

  const { data: posts, error } = await supabase
    .from('posts')
    .select('id, views, likes, comments_count, created_at')
    .eq('status', 'approved')
    .gte('created_at', oneDayAgo.toISOString());

  if (error) {
    logger.error('获取 posts 失败:', error);
    return [];
  }

  // 计算每个帖子的分数
  const items: TrendingItem[] = posts.map(post => ({
    post_id: post.id,
    score: calculateScore(
      post.views,
      post.likes,
      post.comments_count,
      new Date(post.created_at)
    ),
  }));

  // 按分数排序
  items.sort((a, b) => b.score - a.score);

  // 返回前 N 条
  return items.slice(0, limit);
}

// 更新榜单缓存
export async function updateTrendingCache() {
  const supabase = createSupabaseAdmin();
  logger.info('开始计算榜单...');

  try {
    // 计算热榜
    const hotItems = await calculateHotTrending(50);

    // 清空旧的热榜缓存
    await supabase
      .from('trending_cache')
      .delete()
      .eq('list_type', 'hot');

    // 插入新的热榜数据
    if (hotItems.length > 0) {
      const cacheEntries = hotItems.map((item, index) => ({
        post_id: item.post_id,
        list_type: 'hot' as const,
        score: item.score,
        rank: index + 1,
        updated_at: new Date().toISOString(),
      }));

      const { error } = await supabase
        .from('trending_cache')
        .insert(cacheEntries);

      if (error) {
        logger.error('更新热榜缓存失败:', error);
      } else {
        logger.info(`热榜更新完成: ${hotItems.length} 条`);
      }
    }

    logger.info('榜单计算完成');
  } catch (error) {
    logger.error('榜单计算失败:', error);
  }
}

// 运行一次榜单计算
export async function runTrendingCalculation() {
  await updateTrendingCache();
}