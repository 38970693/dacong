/**
 * Report Detail API - 举报详情
 * 用于获取和更新单条举报的详细信息
 */
// 静态导出模式：排除此路由
export const dynamic = 'force-static';

// 静态导出模式需要：返回空数组，不预渲染任何静态页面
// 但 Next.js 16 要求至少返回一个参数，所以返回占位符
export async function generateStaticParams() {
  return [{ id: '__placeholder__' }];
}

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

// 举报状态枚举
type ReportStatus = 'pending' | 'resolved' | 'dismissed';

// 请求体接口
interface UpdateReportBody {
  status: ReportStatus;
}

// 有效的举报状态
const VALID_STATUSES: ReportStatus[] = ['pending', 'resolved', 'dismissed'];

// GET /api/comments/reports/[id] - 获取举报详情
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    // 检查管理员权限
    const authResult = await requireAdmin(request);
    if (authResult instanceof NextResponse) {
      return authResult;
    }

    const { id } = await params;
    const client = getSupabaseClient();

    if (!client) {
      return NextResponse.json(
        { success: false, error: 'Database not configured' },
        { status: 500 }
      );
    }

    // 获取举报详情
    const { data: report, error } = await client
      .from('reports')
      .select('*')
      .eq('id', id)
      .single();

    if (error || !report) {
      return NextResponse.json(
        { success: false, error: 'Report not found' },
        { status: 404 }
      );
    }

    // 获取被举报内容详情
    let targetContent = null;
    const { data: target, error: targetError } = await client
      .from(`${report.target_type}s`)
      .select('*')
      .eq('id', report.target_id)
      .maybeSingle();

    if (!targetError && target) {
      targetContent = target;
    }

    // 获取举报人信息
    let reporterInfo = null;
    if (report.reporter_id) {
      const { data: reporter } = await client
        .from('profiles')
        .select('username, avatar')
        .eq('id', report.reporter_id)
        .maybeSingle();

      if (reporter) {
        reporterInfo = reporter;
      }
    }

    return NextResponse.json({
      success: true,
      data: {
        ...report,
        target_content: targetContent,
        reporter: reporterInfo,
      },
    });
  } catch (e) {
    console.error('Report detail GET error:', e);
    return NextResponse.json(
      { success: false, error: 'Internal server error' },
      { status: 500 }
    );
  }
}

// PATCH /api/comments/reports/[id] - 更新举报状态
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    // 检查管理员权限
    const authResult = await requireAdmin(request);
    if (authResult instanceof NextResponse) {
      return authResult;
    }

    const { id } = await params;
    const client = getSupabaseClient();

    if (!client) {
      return NextResponse.json(
        { success: false, error: 'Database not configured' },
        { status: 500 }
      );
    }

    // 解析请求体
    let body: UpdateReportBody;
    try {
      body = await request.json();
    } catch {
      return NextResponse.json(
        { success: false, error: 'Invalid JSON body' },
        { status: 400 }
      );
    }

    const { status } = body;

    // 验证状态
    if (!status || !VALID_STATUSES.includes(status)) {
      return NextResponse.json(
        {
          success: false,
          error: `status must be one of: ${VALID_STATUSES.join(', ')}`,
        },
        { status: 400 }
      );
    }

    // 检查举报是否存在
    const { data: existing } = await client
      .from('reports')
      .select('id, status')
      .eq('id', id)
      .single();

    if (!existing) {
      return NextResponse.json(
        { success: false, error: 'Report not found' },
        { status: 404 }
      );
    }

    // 构建更新数据
    const updateData: Record<string, unknown> = {
      status,
    };

    // 如果状态变为 resolved 或 dismissed，设置 resolved_at
    if (status === 'resolved' || status === 'dismissed') {
      updateData.resolved_at = new Date().toISOString();
    }

    // 更新举报状态
    const { data: updated, error: updateError } = await client
      .from('reports')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (updateError) {
      console.error('Failed to update report:', updateError);
      return NextResponse.json(
        { success: false, error: 'Failed to update report' },
        { status: 500 }
      );
    }

    return NextResponse.json({
      success: true,
      data: updated,
    });
  } catch (e) {
    console.error('Report detail PATCH error:', e);
    return NextResponse.json(
      { success: false, error: 'Internal server error' },
      { status: 500 }
    );
  }
}