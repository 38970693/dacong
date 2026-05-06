/**
 * 审计日志 API - 获取和创建审计日志
 */
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://prszkdbdgffbdqclbgol.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
if (!supabaseKey) {
  throw new Error('SUPABASE_SERVICE_ROLE_KEY is not configured');
}

const supabase = createClient(supabaseUrl, supabaseKey);

// GET /api/audit-logs - 获取日志列表 (需要管理员权限)
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const userId = searchParams.get('user_id');
    const action = searchParams.get('action');
    const targetType = searchParams.get('target_type');
    const targetId = searchParams.get('target_id');
    const result = searchParams.get('result');
    const startDate = searchParams.get('start_date');
    const endDate = searchParams.get('end_date');
    const limit = parseInt(searchParams.get('limit') || '50', 10);
    const offset = parseInt(searchParams.get('offset') || '0', 10);

    let query = supabase
      .from('audit_logs')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false });

    if (userId) query = query.eq('user_id', userId);
    if (action) query = query.eq('action', action);
    if (targetType) query = query.eq('target_type', targetType);
    if (targetId) query = query.eq('target_id', targetId);
    if (result) query = query.eq('result', result);
    if (startDate) query = query.gte('created_at', startDate);
    if (endDate) query = query.lte('created_at', endDate);

    query = query.range(offset, offset + limit - 1);

    const { data, error, count } = await query;

    if (error) throw error;

    return NextResponse.json({
      success: true,
      data: data || [],
      meta: {
        total: count || 0,
        limit,
        offset
      }
    });
  } catch (error) {
    console.error('获取审计日志失败:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to fetch audit logs' },
      { status: 500 }
    );
  }
}

// POST /api/audit-logs - 创建新日志 (通常由服务端调用)
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    const {
      user_id,
      user_email,
      user_ip,
      user_agent,
      action,
      target_type,
      target_id,
      detail,
      result = 'success',
      request_method,
      request_path,
      request_params,
      response_code
    } = body;

    // 验证必填字段
    if (!action) {
      return NextResponse.json(
        { success: false, error: 'action is required' },
        { status: 400 }
      );
    }

    const { data, error } = await supabase
      .from('audit_logs')
      .insert([{
        user_id: user_id || null,
        user_email: user_email || null,
        user_ip: user_ip || null,
        user_agent: user_agent || null,
        action,
        target_type: target_type || null,
        target_id: target_id || null,
        detail: detail || null,
        result,
        request_method: request_method || null,
        request_path: request_path || null,
        request_params: request_params || null,
        response_code: response_code || null
      }])
      .select()
      .single();

    if (error) throw error;

    return NextResponse.json({
      success: true,
      data
    }, { status: 201 });
  } catch (error) {
    console.error('创建审计日志失败:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to create audit log' },
      { status: 500 }
    );
  }
}