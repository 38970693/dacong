import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

interface AnalyticsEvent {
  event_type: string
  user_id?: string
  session_id: string
  content_id?: string
  properties: Record<string, any>
  device_info: Record<string, any>
  created_at: string
}

serve(async (req) => {
  // 处理 CORS 预检请求
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { events } = await req.json() as { events: AnalyticsEvent[] }

    if (!events || !Array.isArray(events) || events.length === 0) {
      return new Response(
        JSON.stringify({ error: 'Invalid events data' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // 批量插入事件
    const { data, error } = await supabase
      .from('analytics_events')
      .insert(events.map(event => ({
        event_type: event.event_type,
        user_id: event.user_id || null,
        session_id: event.session_id,
        content_id: event.content_id || null,
        properties: event.properties || {},
        device_info: event.device_info || {},
        created_at: event.created_at
      })))

    if (error) {
      console.error('Insert error:', error)
      throw error
    }

    console.log(`[track-event] Inserted ${events.length} events`)

    return new Response(
      JSON.stringify({
        success: true,
        count: events.length
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
