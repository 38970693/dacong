// Static export mode: exclude from static generation
export const dynamic = 'force-static';

import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

type FeedbackType = 'suggestion' | 'bug' | 'business' | 'other';

interface FeedbackRequest {
  type: FeedbackType;
  content: string;
  contact: string | null;
  user_id: string | null;
  user_email: string | null;
}

export async function POST(request: NextRequest) {
  try {
    const body: FeedbackRequest = await request.json();

    // 验证必填字段
    if (!body.type || !body.content) {
      return NextResponse.json(
        { error: '缺少必填字段' },
        { status: 400 }
      );
    }

    // 验证反馈类型
    const validTypes: FeedbackType[] = ['suggestion', 'bug', 'business', 'other'];
    if (!validTypes.includes(body.type)) {
      return NextResponse.json(
        { error: '无效的反馈类型' },
        { status: 400 }
      );
    }

    // 验证内容长度
    if (body.content.length < 10) {
      return NextResponse.json(
        { error: '反馈内容至少需要 10 个字符' },
        { status: 400 }
      );
    }

    if (body.content.length > 2000) {
      return NextResponse.json(
        { error: '反馈内容不能超过 2000 个字符' },
        { status: 400 }
      );
    }

    // 创建 Supabase 客户端
    const supabase = createClient(supabaseUrl, supabaseKey);

    // 保存反馈到数据库
    const { error: insertError } = await supabase
      .from('feedbacks')
      .insert({
        type: body.type,
        content: body.content,
        contact: body.contact,
        user_id: body.user_id,
        user_email: body.user_email,
        status: 'pending',
      });

    if (insertError) {
      console.error('保存反馈失败:', insertError);
      return NextResponse.json(
        { error: '保存反馈失败，请稍后重试' },
        { status: 500 }
      );
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('处理反馈请求失败:', error);
    return NextResponse.json(
      { error: '服务器错误，请稍后重试' },
      { status: 500 }
    );
  }
}