import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

serve(async (req) => {
  // 处理 CORS 预检请求
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const todayStr = today.toISOString().split('T')[0]

    console.log(`[aggregate-analytics] Aggregating data for ${todayStr}`)

    // 1. 计算 DAU (Daily Active Users)
    const { data: dauData, error: dauError } = await supabase
      .from('analytics_events')
      .select('user_id')
      .gte('created_at', today.toISOString())
      .not('user_id', 'is', null)

    if (dauError) throw dauError

    const dau = new Set(dauData.map(e => e.user_id)).size

    // 2. 计算 PV (Page Views)
    const { count: pv, error: pvError } = await supabase
      .from('analytics_events')
      .select('*', { count: 'exact', head: true })
      .eq('event_type', 'page_view')
      .gte('created_at', today.toISOString())

    if (pvError) throw pvError

    // 3. 计算 UV (Unique Visitors)
    const { data: uvData, error: uvError } = await supabase
      .from('analytics_events')
      .select('session_id')
      .eq('event_type', 'page_view')
      .gte('created_at', today.toISOString())

    if (uvError) throw uvError

    const uv = new Set(uvData.map(e => e.session_id)).size

    // 4. 计算内容浏览量
    const { data: contentViews, error: contentViewsError } = await supabase
      .from('analytics_events')
      .select('content_id')
      .eq('event_type', 'content_view')
      .gte('created_at', today.toISOString())
      .not('content_id', 'is', null)

    if (contentViewsError) throw contentViewsError

    const contentViewCount = contentViews.length

    // 5. 计算搜索次数
    const { count: searchCount, error: searchError } = await supabase
      .from('analytics_events')
      .select('*', { count: 'exact', head: true })
      .eq('event_type', 'search')
      .gte('created_at', today.toISOString())

    if (searchError) throw searchError

    // 6. 插入或更新汇总数据
    const { error: upsertError } = await supabase
      .from('analytics_daily')
      .upsert({
        date: todayStr,
        dau,
        pv: pv || 0,
        uv,
        content_views: contentViewCount,
        searches: searchCount || 0,
        updated_at: new Date().toISOString()
      }, {
        onConflict: 'date'
      })

    if (upsertError) throw upsertError

    console.log(`[aggregate-analytics] Success: DAU=${dau}, PV=${pv}, UV=${uv}`)

    return new Response(
      JSON.stringify({
        success: true,
        date: todayStr,
        metrics: {
          dau,
          pv: pv || 0,
          uv,
          content_views: contentViewCount,
          searches: searchCount || 0
        }
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
