import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RealtimeStats {
  today_dau: number
  today_pv: number
  today_uv: number
  new_users: number
  published_content: number
  total_users: number
  total_content: number
  pending_review: number
  total_comments: number
  pending_comments: number
  dau_change: number
  pv_change: number
  uv_change: number
  new_users_change: number
}

// 简单的内存缓存
let cachedStats: RealtimeStats | null = null
let cacheTime: number | null = null
const CACHE_DURATION = 60 * 1000 // 1分钟

serve(async (req) => {
  // 处理 CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // 检查缓存
    const now = Date.now()
    if (cachedStats && cacheTime && (now - cacheTime) < CACHE_DURATION) {
      return new Response(
        JSON.stringify(cachedStats),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      )
    }

    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const todayStr = today.toISOString()

    const yesterday = new Date(today)
    yesterday.setDate(yesterday.getDate() - 1)
    const yesterdayStr = yesterday.toISOString()

    // 并行查询所有数据
    const [
      todayAnalytics,
      yesterdayAnalytics,
      todayUsers,
      yesterdayUsers,
      totalUsers,
      totalContent,
      publishedContent,
      pendingReview,
      totalComments,
      pendingComments,
    ] = await Promise.all([
      // 今日分析数据
      supabaseClient
        .from('analytics_daily')
        .select('dau, pv, uv')
        .gte('date', todayStr)
        .single(),

      // 昨日分析数据
      supabaseClient
        .from('analytics_daily')
        .select('dau, pv, uv')
        .gte('date', yesterdayStr)
        .lt('date', todayStr)
        .single(),

      // 今日新增用户
      supabaseClient
        .from('users')
        .select('id', { count: 'exact', head: true })
        .gte('created_at', todayStr),

      // 昨日新增用户
      supabaseClient
        .from('users')
        .select('id', { count: 'exact', head: true })
        .gte('created_at', yesterdayStr)
        .lt('created_at', todayStr),

      // 总用户数
      supabaseClient
        .from('users')
        .select('id', { count: 'exact', head: true }),

      // 总内容数
      supabaseClient
        .from('contents')
        .select('id', { count: 'exact', head: true }),

      // 已发布内容
      supabaseClient
        .from('contents')
        .select('id', { count: 'exact', head: true })
        .eq('status', 'published'),

      // 待审核内容
      supabaseClient
        .from('contents')
        .select('id', { count: 'exact', head: true })
        .eq('status', 'pending'),

      // 总评论数
      supabaseClient
        .from('comments')
        .select('id', { count: 'exact', head: true }),

      // 待审核评论
      supabaseClient
        .from('comments')
        .select('id', { count: 'exact', head: true })
        .eq('status', 'pending'),
    ])

    // 计算变化率
    const calculateChange = (today: number, yesterday: number): number => {
      if (yesterday === 0) return 0
      return ((today - yesterday) / yesterday) * 100
    }

    const todayDau = todayAnalytics.data?.dau || 0
    const todayPv = todayAnalytics.data?.pv || 0
    const todayUv = todayAnalytics.data?.uv || 0
    const yesterdayDau = yesterdayAnalytics.data?.dau || 0
    const yesterdayPv = yesterdayAnalytics.data?.pv || 0
    const yesterdayUv = yesterdayAnalytics.data?.uv || 0
    const newUsersToday = todayUsers.count || 0
    const newUsersYesterday = yesterdayUsers.count || 0

    const stats: RealtimeStats = {
      today_dau: todayDau,
      today_pv: todayPv,
      today_uv: todayUv,
      new_users: newUsersToday,
      published_content: publishedContent.count || 0,
      total_users: totalUsers.count || 0,
      total_content: totalContent.count || 0,
      pending_review: pendingReview.count || 0,
      total_comments: totalComments.count || 0,
      pending_comments: pendingComments.count || 0,
      dau_change: calculateChange(todayDau, yesterdayDau),
      pv_change: calculateChange(todayPv, yesterdayPv),
      uv_change: calculateChange(todayUv, yesterdayUv),
      new_users_change: calculateChange(newUsersToday, newUsersYesterday),
    }

    // 更新缓存
    cachedStats = stats
    cacheTime = now

    return new Response(
      JSON.stringify(stats),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})
