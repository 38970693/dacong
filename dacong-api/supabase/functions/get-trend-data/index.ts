import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
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

    const url = new URL(req.url)
    const days = parseInt(url.searchParams.get('days') || '7')

    const startDate = new Date()
    startDate.setDate(startDate.getDate() - days)
    startDate.setHours(0, 0, 0, 0)

    const { data, error } = await supabaseClient
      .from('analytics_daily')
      .select('date, dau, pv, uv')
      .gte('date', startDate.toISOString())
      .order('date', { ascending: true })

    if (error) throw error

    const labels: string[] = []
    const dauData: number[] = []
    const pvData: number[] = []
    const uvData: number[] = []

    data.forEach((item) => {
      const date = new Date(item.date)
      labels.push(`${date.getMonth() + 1}/${date.getDate()}`)
      dauData.push(item.dau || 0)
      pvData.push(item.pv || 0)
      uvData.push(item.uv || 0)
    })

    return new Response(
      JSON.stringify({
        labels,
        dau_data: dauData,
        pv_data: pvData,
        uv_data: uvData,
      }),
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
