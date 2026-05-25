// Static export mode: exclude from static generation
export const dynamic = 'force-static';

/**
 * Reports API - reporting feature
 * Used for creating and managing reports on comments/posts/reviews
 */
import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://prszkdbdgffbdqclbgol.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

// 单例 Supabase 客户端
let supabase: ReturnType<typeof createClient> | null = null;

function getSupabaseClient() {
  if (!supabase && supabaseKey) {
    supabase = createClient(supabaseUrl, supabaseKey);
  }
  return supabase;
}

// 举报原因枚举
export type ReportReason =
  | 'spam'
  | 'harassment'
  | 'hate_speech'
  | 'violence'
  | 'misinformation'
  | 'other';

// 举报状态枚举
export type ReportStatus = 'pending' | 'resolved' | 'dismissed';

// 举报接口
interface Report {
  id: string;
  target_type: 'comment' | 'post' | 'review';
  target_id: string;
  reporter_id: string | null;
  reason: ReportReason;
  description: string | null;
  status: ReportStatus;
  created_at: string;
  resolved_at: string | null;
}

// 请求体接口
interface CreateReportBody {
  target_type: 'comment' | 'post' | 'review';
  target_id: string;
  reason: ReportReason;
  description?: string;
}

// 有效的举报原因
const VALID_REASONS: ReportReason[] = [
  'spam',
  'harassment',
  'hate_speech',
  'violence',
  'misinformation',
  'other',
];

// GET /api/comments/reports - 获取举报列表（管理端）
export async function GET(request: NextRequest) {
  try {
    const client = getSupabaseClient();
    if (!client) {
      return NextResponse.json(
        { success: false, error: 'Database not configured' },
        { status: 500 }
      );
    }

    const searchParams = request.nextUrl.searchParams;
    const status = searchParams.get('status') as ReportStatus | null;
    const limit = Math.min(parseInt(searchParams.get('limit') || '20', 10), 100);
    const offset = parseInt(searchParams.get('offset') || '0', 10);

    // 构建查询
    let query = client
      .from('reports')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (status) {
      query = query.eq('status', status);
    }

    const { data: reports, error, count } = await query;

    if (error) {
      console.error('Failed to fetch reports:', error);
      return NextResponse.json(
        { success: false, error: 'Failed to fetch reports' },
        { status: 500 }
      );
    }

    return NextResponse.json({
      success: true,
      data: {
        reports: reports || [],
        total: count || 0,
        limit,
        offset,
      },
    });
  } catch (e) {
    console.error('Reports GET error:', e);
    return NextResponse.json(
      { success: false, error: 'Internal server error' },
      { status: 500 }
    );
  }
}

// POST /api/comments/reports - 创建举报
export async function POST(request: NextRequest) {
  try {
    const client = getSupabaseClient();
    if (!client) {
      return NextResponse.json(
        { success: false, error: 'Database not configured' },
        { status: 500 }
      );
    }

    let body: CreateReportBody;
    try {
      body = await request.json();
    } catch {
      return NextResponse.json(
        { success: false, error: 'Invalid JSON body' },
        { status: 400 }
      );
    }

    const { target_type, target_id, reason, description } = body;

    // 验证必填字段
    if (!target_type || !target_id || !reason) {
      return NextResponse.json(
        {
          success: false,
          error: 'target_type, target_id, and reason are required',
        },
        { status: 400 }
      );
    }

    // 验证 target_type
    const validTargetTypes = ['comment', 'post', 'review'];
    if (!validTargetTypes.includes(target_type)) {
      return NextResponse.json(
        {
          success: false,
          error: `target_type must be one of: ${validTargetTypes.join(', ')}`,
        },
        { status: 400 }
      );
    }

    // 验证 reason
    if (!VALID_REASONS.includes(reason)) {
      return NextResponse.json(
        {
          success: false,
          error: `reason must be one of: ${VALID_REASONS.join(', ')}`,
        },
        { status: 400 }
      );
    }

    // 验证 description 长度
    if (description && description.length > 2000) {
      return NextResponse.json(
        {
          success: false,
          error: 'description exceeds maximum length of 2000 characters',
        },
        { status: 400 }
      );
    }

    // 验证目标是否存在
    const { data: target, error: targetError } = await client
      .from(`${target_type}s`)
      .select('id')
      .eq('id', target_id)
      .single();

    if (targetError || !target) {
      return NextResponse.json(
        {
          success: false,
          error: `${target_type} not found`,
        },
        { status: 404 }
      );
    }

    // 获取当前用户（可选）
    let reporterId: string | null = null;
    const authHeader = request.headers.get('Authorization');
    if (authHeader?.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      try {
        const { data: { user } } = await client.auth.getUser(token);
        reporterId = user?.id ?? null;
      } catch (e) {
        console.error('Auth validation failed:', e);
      }
    }

    // 开发模式：尝试从查询参数获取 reporter_id
    if (!reporterId) {
      const devUserId = new URL(request.url).searchParams.get('dev_user_id');
      if (devUserId && process.env.NODE_ENV === 'development') {
        reporterId = devUserId;
      }
    }

    // 创建举报
    const { data: report, error: insertError } = await client
      .from('reports')
      .insert({
        target_type,
        target_id,
        reporter_id: reporterId,
        reason,
        description: description || null,
        status: 'pending',
      } as never)
      .select()
      .single();

    if (insertError) {
      console.error('Failed to create report:', insertError);
      return NextResponse.json(
        { success: false, error: 'Failed to create report' },
        { status: 500 }
      );
    }

    return NextResponse.json(
      {
        success: true,
        data: report,
      },
      { status: 201 }
    );
  } catch (e) {
    console.error('Reports POST error:', e);
    return NextResponse.json(
      { success: false, error: 'Internal server error' },
      { status: 500 }
    );
  }
}

