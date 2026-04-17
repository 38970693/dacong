import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

serve(async (req) => {
  // 处理 CORS 预检请求
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const url = new URL(req.url)
    const type = url.searchParams.get('type') || 'overview'
    const days = parseInt(url.searchParams.get('days') || '7')

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    let result: any = {}

    switch (type) {
      case 'overview':
        // 获取概览数据（最近N天的汇总）
        const startDate = new Date()
        startDate.setDate(startDate.getDate() - days)
        startDate.setHours(0, 0, 0, 0)

        const { data: dailyData, error: dailyError } = await supabase
          .from('analytics_daily')
          .select('*')
          .gte('date', startDate.toISOString().split('T')[0])
          .order('date', { ascending: true })

        if (dailyError) throw dailyError

        // 计算总计和平均值
        const totals = dailyData.reduce((acc, day) => ({
          dau: acc.dau + day.dau,
          pv: acc.pv + day.pv,
          uv: acc.uv + day.uv,
          content_views: acc.content_views + day.content_views,
          searches: acc.searches + day.searches
        }), { dau: 0, pv: 0, uv: 0, content_views: 0, searches: 0 })

        result = {
          period: `${days}d`,
          daily_data: dailyData,
          totals,
          averages: {
            dau: Math.round(totals.dau / dailyData.length),
            pv: Math.round(totals.pv / dailyData.length),
            uv: Math.round(totals.uv / dailyData.length),
            content_views: Math.round(totals.content_views / dailyData.length),
            searches: Math.round(totals.searches / dailyData.length)
          }
        }
        break

      case 'hot_content':
        // 获取热门内容排行
        const limit = parseInt(url.searchParams.get('limit') || '10')
        const { data: hotContent, error: hotContentError } = await supabase
          .from('analytics_events')
          .select('content_id, properties')
          .eq('event_type', 'content_view')
          .not('content_id', 'is', null)
          .gte('created_at', new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString())

        if (hotContentError) throw hotContentError

        // 统计每个内容的浏览量
        const contentStats = hotContent.reduce((acc: any, event: any) => {
          const id = event.content_id
          if (!acc[id]) {
            acc[id] = { content_id: id, view_count: 0 }
          }
          acc[id].view_count++
          return acc
        }, {})

        result = {
          hot_content: Object.values(contentStats)
            .sort((a: any, b: any) => b.view_count - a.view_count)
            .slice(0, limit)
        }
        break

      case 'hot_searches':
        // 获取热门搜索词
        const searchLimit = parseInt(url.searchParams.get('limit') || '10')
        const { data: searches, error: searchesError } = await supabase
          .from('analytics_events')
          .select('properties')
          .eq('event_type', 'search')
          .gte('created_at', new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString())

        if (searchesError) throw searchesError

        // 统计搜索词频率
        const searchStats = searches.reduce((acc: any, event: any) => {
          const query = event.properties?.query
          if (query) {
            if (!acc[query]) {
              acc[query] = { query, count: 0 }
            }
            acc[query].count++
          }
          return acc
        }, {})

        result = {
          hot_searches: Object.values(searchStats)
            .sort((a: any, b: any) => b.count - a.count)
            .slice(0, searchLimit)
        }
        break

      case 'funnel':
        // 获取转化漏斗数据
        const funnelStart = new Date()
        funnelStart.setDate(funnelStart.getDate() - days)

        const events = ['page_view', 'content_view', 'favorite_add', 'feedback_submit']
        const funnelData = []

        for (const eventType of events) {
          const { count, error } = await supabase
            .from('analytics_events')
            .select('*', { count: 'exact', head: true })
            .eq('event_type', eventType)
            .gte('created_at', funnelStart.toISOString())

          if (error) throw error

          funnelData.push({
            event: eventType,
            count: count || 0
          })
        }

        result = { funnel: funnelData }
        break

      default:
        throw new Error(`Unknown type: ${type}`)
    }

    return new Response(
      JSON.stringify({
        success: true,
        type,
        data: result
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})
