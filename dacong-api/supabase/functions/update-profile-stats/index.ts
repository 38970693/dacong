// Edge Function: update-profile-stats
// 手动触发：重新计算 profile_stats 视图（粉丝数、帖子数等）
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const { data, error } = await supabase.rpc('refresh_profile_stats')

  return new Response(JSON.stringify({ ok: !error, error }), {
    headers: { 'Content-Type': 'application/json' }
  })
})
