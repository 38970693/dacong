import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

// 获取 Supabase 客户端
function getSupabaseClient() {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl || !supabaseKey) {
    return null;
  }

  return createClient(supabaseUrl, supabaseKey, {
    auth: { persistSession: false }
  });
}

// 平台到表的映射
const PLATFORM_TABLES: Record<string, string> = {
  'swebench': 'swebench_rankings',
  'arena': 'arena_rankings',
  'artificial-analysis': 'artificial_analysis_rankings',
  'aiping': 'aiping_rankings',
};

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ platform: string }> }
) {
  try {
    const { platform } = await params;

    // 验证平台
    if (!PLATFORM_TABLES[platform]) {
      return NextResponse.json(
        { success: false, error: '不支持的平台' },
        { status: 400 }
      );
    }

    const tableName = PLATFORM_TABLES[platform];
    const supabase = getSupabaseClient();

    if (!supabase) {
      // 没有数据库配置，返回空数据
      return NextResponse.json({
        success: true,
        data: [],
        source: 'mock'
      });
    }

    // 解析查询参数
    const { searchParams } = new URL(request.url);
    const limit = parseInt(searchParams.get('limit') || '50', 10);
    const sort = searchParams.get('sort') || 'elo_score';
    const order = searchParams.get('order') || 'desc';

    // 构建查询
    let query = supabase
      .from(tableName)
      .select('*')
      .order(sort, { ascending: order === 'asc' })
      .limit(limit);

    // 添加过滤条件
    const search = searchParams.get('search');
    if (search) {
      query = query.or(`model_name.ilike.%${search}%,company.ilike.%${search}%`);
    }

    const { data, error } = await query;

    if (error) {
      console.error(`查询 ${tableName} 失败:`, error);
      return NextResponse.json(
        { success: false, error: error.message },
        { status: 500 }
      );
    }

    return NextResponse.json({
      success: true,
      data: data || [],
      source: 'database'
    });

  } catch (err) {
    console.error('API 错误:', err);
    return NextResponse.json(
      { success: false, error: '服务器内部错误' },
      { status: 500 }
    );
  }
}