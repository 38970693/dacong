import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface PerformanceQuery {
  service?: string;
  metric_type?: string;
  start_date?: string;
  end_date?: string;
  limit?: number;
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
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
    );

    // 验证用户身份
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser();

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const query: PerformanceQuery = await req.json();

    // 构建查询
    let dbQuery = supabaseClient
      .from('performance_metrics')
      .select('*')
      .order('created_at', { ascending: false });

    if (query.service) {
      dbQuery = dbQuery.eq('service', query.service);
    }

    if (query.metric_type) {
      dbQuery = dbQuery.eq('metric_type', query.metric_type);
    }

    if (query.start_date) {
      dbQuery = dbQuery.gte('created_at', query.start_date);
    }

    if (query.end_date) {
      dbQuery = dbQuery.lte('created_at', query.end_date);
    }

    if (query.limit) {
      dbQuery = dbQuery.limit(query.limit);
    } else {
      dbQuery = dbQuery.limit(1000);
    }

    const { data, error } = await dbQuery;

    if (error) {
      throw error;
    }

    // 计算统计信息
    const stats = calculateStats(data || []);

    return new Response(
      JSON.stringify({
        success: true,
        data,
        stats,
        count: data?.length || 0,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('Error fetching performance metrics:', error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});

/**
 * 计算性能统计
 */
function calculateStats(metrics: any[]) {
  if (metrics.length === 0) {
    return null;
  }

  const values = metrics.map(m => m.metric_value).sort((a, b) => a - b);

  return {
    count: metrics.length,
    avg: values.reduce((a, b) => a + b, 0) / values.length,
    min: values[0],
    max: values[values.length - 1],
    p50: values[Math.floor(values.length * 0.5)],
    p95: values[Math.floor(values.length * 0.95)],
    p99: values[Math.floor(values.length * 0.99)],
  };
}
