// Static export mode: exclude from static generation
export const dynamic = 'force-static';

import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

export async function GET(request: Request) {
  const requestUrl = new URL(request.url);
  const code = requestUrl.searchParams.get('code');
  const next = requestUrl.searchParams.get('next') || '/web';

  if (code) {
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { error } = await supabase.auth.exchangeCodeForSession(code);

    if (!error) {
      // 认证成功，重定向到首页或指定页面
      return NextResponse.redirect(new URL(next, requestUrl.origin));
    }
  }

  // 认证失败，重定向到登录页
  return NextResponse.redirect(new URL('/web/auth/login?error=auth_callback_failed', requestUrl.origin));
}