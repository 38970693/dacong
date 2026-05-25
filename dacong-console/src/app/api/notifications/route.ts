// Static export mode: exclude from static generation
export const dynamic = 'force-static';

/**
 * Notifications API - fetch, create and manage user notifications
 */
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://prszkdbdgffbdqclbgol.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

// 延迟初始化 Supabase 客户端
function getSupabaseClient() {
  if (!supabaseKey) {
    throw new Error('SUPABASE_SERVICE_ROLE_KEY is not configured');
  }
  return createClient(supabaseUrl, supabaseKey);
}

// GET /api/notifications - 获取通知列表
export async function GET(request: NextRequest) {
  try {
    const supabase = getSupabaseClient();
    const { searchParams } = new URL(request.url);
    const userId = searchParams.get('user_id');
    const type = searchParams.get('type');
    const isRead = searchParams.get('is_read');
    const limit = parseInt(searchParams.get('limit') || '50', 10);
    const offset = parseInt(searchParams.get('offset') || '0', 10);

    if (!userId) {
      return NextResponse.json(
        { success: false, error: 'user_id is required' },
        { status: 400 }
      );
    }

    let query = supabase
      .from('notifications')
      .select('*', { count: 'exact' })
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (type) {
      query = query.eq('type', type);
    }

    if (isRead !== null) {
      query = query.eq('is_read', isRead === 'true');
    }

    // 过滤过期通知
    query = query.or(`expires_at.is.null,expires_at.gt.${new Date().toISOString()}`);

    query = query.range(offset, offset + limit - 1);

    const { data, error, count } = await query;

    if (error) throw error;

    return NextResponse.json({
      success: true,
      data: data || [],
      meta: {
        total: count || 0,
        unread: (data || []).filter(n => !n.is_read).length,
        limit,
        offset
      }
    });
  } catch (error) {
    console.error('获取通知失败:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to fetch notifications' },
      { status: 500 }
    );
  }
}

// POST /api/notifications - 创建通知 (需要管理员权限或系统调用)
export async function POST(request: NextRequest) {
  try {
    const supabase = getSupabaseClient();
    const body = await request.json();

    const {
      user_id,
      type,
      title,
      content,
      action_url,
      target_type,
      target_id,
      source_user_id,
      source_user_name,
      source_user_avatar,
      priority = 'normal',
      expires_at,
      metadata
    } = body;

    // 验证必填字段
    if (!user_id || !type || !title || !content) {
      return NextResponse.json(
        { success: false, error: 'user_id, type, title, content are required' },
        { status: 400 }
      );
    }

    const { data, error } = await supabase
      .from('notifications')
      .insert([{
        user_id,
        type,
        title,
        content,
        action_url: action_url || null,
        target_type: target_type || null,
        target_id: target_id || null,
        source_user_id: source_user_id || null,
        source_user_name: source_user_name || null,
        source_user_avatar: source_user_avatar || null,
        priority,
        expires_at: expires_at || null,
        metadata: metadata || null
      }])
      .select()
      .single();

    if (error) throw error;

    return NextResponse.json({
      success: true,
      data
    }, { status: 201 });
  } catch (error) {
    console.error('创建通知失败:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to create notification' },
      { status: 500 }
    );
  }
}

// PATCH /api/notifications - 更新通知 (标记已读等)
export async function PATCH(request: NextRequest) {
  try {
    const supabase = getSupabaseClient();
    const body = await request.json();
    const { notification_id, is_read } = body;

    if (!notification_id) {
      return NextResponse.json(
        { success: false, error: 'notification_id is required' },
        { status: 400 }
      );
    }

    const updateData: Record<string, unknown> = {};
    if (is_read !== undefined) {
      updateData.is_read = is_read;
      if (is_read) {
        updateData.read_at = new Date().toISOString();
      }
    }

    const { data, error } = await supabase
      .from('notifications')
      .update(updateData)
      .eq('id', notification_id)
      .select()
      .single();

    if (error) throw error;

    return NextResponse.json({
      success: true,
      data
    });
  } catch (error) {
    console.error('更新通知失败:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to update notification' },
      { status: 500 }
    );
  }
}

// DELETE /api/notifications - 删除通知
export async function DELETE(request: NextRequest) {
  try {
    const supabase = getSupabaseClient();
    const { searchParams } = new URL(request.url);
    const notificationId = searchParams.get('id');

    if (!notificationId) {
      return NextResponse.json(
        { success: false, error: 'id is required' },
        { status: 400 }
      );
    }

    const { error } = await supabase
      .from('notifications')
      .delete()
      .eq('id', notificationId);

    if (error) throw error;

    return NextResponse.json({
      success: true
    });
  } catch (error) {
    console.error('删除通知失败:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to delete notification' },
      { status: 500 }
    );
  }
}