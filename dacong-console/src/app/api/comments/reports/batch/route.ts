// Static export mode: exclude from static generation
export const dynamic = 'force-static';

/**
 * Batch Reports API - batch process reports
 * Used for batch updating report status
 */
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/admin-utils';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://prszkdbdgffbdqclbgol.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

// 单例 Supabase 客户端
let supabase: SupabaseClient | null = null;

function getSupabaseClient(): SupabaseClient | null {
  if (!supabase && supabaseKey) {
    supabase = createClient(supabaseUrl, supabaseKey);
  }
  return supabase;
}

// 批量操作类型
type BatchAction = 'resolve' | 'dismiss';

// 请求体接口
interface BatchReportBody {
  ids: string[];
  action: BatchAction;
}

// 映射 action 到 status
const ACTION_TO_STATUS: Record<BatchAction, string> = {
  resolve: 'resolved',
  dismiss: 'dismissed',
};

// POST /api/comments/reports/batch - 批量处理举报
export async function POST(request: NextRequest) {
  try {
    // 检查管理员权限
    const authResult = await requireAdmin(request);
    if (authResult instanceof NextResponse) {
      return authResult;
    }

    const client = getSupabaseClient();

    if (!client) {
      return NextResponse.json(
        { success: false, error: 'Database not configured' },
        { status: 500 }
      );
    }

    // 解析请求体
    let body: BatchReportBody;
    try {
      body = await request.json();
    } catch {
      return NextResponse.json(
        { success: false, error: 'Invalid JSON body' },
        { status: 400 }
      );
    }

    const { ids, action } = body;

    // 验证 ids
    if (!ids || !Array.isArray(ids) || ids.length === 0) {
      return NextResponse.json(
        { success: false, error: 'ids must be a non-empty array' },
        { status: 400 }
      );
    }

    if (ids.length > 100) {
      return NextResponse.json(
        { success: false, error: 'Maximum 100 reports can be processed at once' },
        { status: 400 }
      );
    }

    // 验证每个 id 都是有效的 UUID 格式
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    for (const id of ids) {
      if (!uuidRegex.test(id)) {
        return NextResponse.json(
          { success: false, error: `Invalid report ID format: ${id}` },
          { status: 400 }
        );
      }
    }

    // 验证 action
    const validActions: BatchAction[] = ['resolve', 'dismiss'];
    if (!action || !validActions.includes(action)) {
      return NextResponse.json(
        {
          success: false,
          error: `action must be one of: ${validActions.join(', ')}`,
        },
        { status: 400 }
      );
    }

    const status = ACTION_TO_STATUS[action];
    const resolvedAt = new Date().toISOString();

    // 执行批量更新
    const { data, error } = await client
      .from('reports')
      .update({
        status,
        resolved_at: resolvedAt,
      })
      .in('id', ids)
      .select();

    if (error) {
      console.error('Batch update failed:', error);
      return NextResponse.json(
        { success: false, error: 'Failed to update reports' },
        { status: 500 }
      );
    }

    return NextResponse.json({
      success: true,
      data: {
        updated: data?.length || 0,
      },
    });
  } catch (e) {
    console.error('Batch reports POST error:', e);
    return NextResponse.json(
      { success: false, error: 'Internal server error' },
      { status: 500 }
    );
  }
}