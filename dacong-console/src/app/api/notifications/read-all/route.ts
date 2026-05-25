// Static export mode: exclude from static generation
export const dynamic = 'force-static';

/**
 * Batch Mark Notifications Read API
 * POST /api/notifications/read-all
 */
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import { getCurrentUser } from '@/lib/auth-utils';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://prszkdbdgffbdqclbgol.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

function getSupabaseClient() {
  if (!supabaseKey) {
    throw new Error('SUPABASE_SERVICE_ROLE_KEY is not configured');
  }
  return createClient(supabaseUrl, supabaseKey);
}

// POST /api/notifications/read-all - 批量标记所有未读通知为已读
export async function POST(request: NextRequest) {
  try {
    const user = await getCurrentUser(request);

    if (!user) {
      return NextResponse.json(
        { success: false, error: 'Authentication required' },
        { status: 401 }
      );
    }

    const supabase = getSupabaseClient();

    // 批量更新当前用户的所有未读通知
    const { data, error } = await supabase
      .from('notifications')
      .update({
        is_read: true,
        read_at: new Date().toISOString()
      })
      .eq('user_id', user.id)
      .eq('is_read', false)
      .select();

    if (error) throw error;

    return NextResponse.json({
      success: true,
      data: {
        marked_count: data?.length || 0
      }
    });
  } catch (error) {
    console.error('批量标记通知已读失败:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to mark notifications as read' },
      { status: 500 }
    );
  }
}