/**
 * Comment Report API - 举报特定评论
 * POST /api/comments/[id]/report - 举报指定评论
 */
import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

// 静态导出模式：排除此路由
export const dynamic = 'force-static';

// 静态导出模式需要：返回占位符，不预渲染任何静态页面
export async function generateStaticParams() {
  return [{ id: '__placeholder__' }];
}

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

// 有效的举报原因
const VALID_REASONS: ReportReason[] = [
  'spam',
  'harassment',
  'hate_speech',
  'violence',
  'misinformation',
  'other',
];

// 请求体接口
interface ReportBody {
  reason: ReportReason;
  description?: string;
}

// POST /api/comments/[id]/report - 举报评论
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;

    const client = getSupabaseClient();
    if (!client) {
      return NextResponse.json(
        { success: false, error: 'Database not configured' },
        { status: 500 }
      );
    }

    // 验证评论是否存在
    const { data: comment, error: commentError } = await client
      .from('comments')
      .select('id, user_id, content')
      .eq('id', id)
      .single();

    if (commentError || !comment) {
      return NextResponse.json(
        { success: false, error: 'Comment not found' },
        { status: 404 }
      );
    }

    let body: ReportBody;
    try {
      body = await request.json();
    } catch {
      return NextResponse.json(
        { success: false, error: 'Invalid JSON body' },
        { status: 400 }
      );
    }

    const { reason, description } = body;

    // 验证 reason
    if (!reason) {
      return NextResponse.json(
        { success: false, error: 'reason is required' },
        { status: 400 }
      );
    }

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

    // 检查是否已经举报过该评论（防止重复举报）
    if (reporterId) {
      const { data: existingReport } = await client
        .from('reports')
        .select('id')
        .eq('target_type', 'comment')
        .eq('target_id', id)
        .eq('reporter_id', reporterId)
        .eq('status', 'pending')
        .single();

      if (existingReport) {
        return NextResponse.json(
          { success: false, error: 'You have already reported this comment' },
          { status: 400 }
        );
      }
    }

    // 创建举报
    const { data: report, error: insertError } = await client
      .from('reports')
      .insert({
        target_type: 'comment',
        target_id: id,
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
    console.error('Comment report POST error:', e);
    return NextResponse.json(
      { success: false, error: 'Internal server error' },
      { status: 500 }
    );
  }
}