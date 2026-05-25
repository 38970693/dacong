// Static export mode: exclude this route from static generation
export const dynamic = 'force-static';

// Static export mode requires: return placeholder to prevent pre-rendering
export async function generateStaticParams() {
  return [{ id: '__placeholder__' }];
}

/**
 * 通知标记已读 API
 * POST /api/notifications/[id]/read
 */
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import { getCurrentUser } from '@/lib/auth-utils';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://prszkdbdgffbdqclbgol.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

// 延迟初始化 Supabase 客户端
function getSupabaseClient() {
  if (!supabaseKey) {
    throw new Error('SUPABASE_SERVICE_ROLE_KEY is not configured');
  }
  return createClient(supabaseUrl, supabaseKey);
}

// POST /api/notifications/[id]/read - 标记单条通知为已读
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const user = await getCurrentUser(request);

    if (!user) {
      return NextResponse.json(
        { success: false, error: 'Authentication required' },
        { status: 401 }
      );
    }

    const supabase = getSupabaseClient();

    // 标记通知为已读，同时验证用户只能标记自己的通知
    const { data, error } = await supabase
      .from('notifications')
      .update({
        is_read: true,
        read_at: new Date().toISOString()
      })
      .eq('id', id)
      .eq('user_id', user.id)  // 确保只能标记自己的通知
      .select()
      .single();

    if (error) {
      // 如果找不到通知或无权限，返回 404
      if (error.code === 'PGRST116') {
        return NextResponse.json(
          { success: false, error: 'Notification not found or access denied' },
          { status: 404 }
        );
      }
      throw error;
    }

    return NextResponse.json({
      success: true,
      data
    });
  } catch (error) {
    console.error('标记通知已读失败:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to mark notification as read' },
      { status: 500 }
    );
  }
}