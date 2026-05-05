import { createClient } from '@supabase/supabase-js';

export function createSupabaseAdmin() {
  return createClient(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
      // 禁用 Realtime，因为 Worker 不需要实时订阅功能
      // 启用 Realtime 需要安装 ws 包或使用 Node.js 22+
      realtime: {
        enabled: false,
      },
    }
  );
}