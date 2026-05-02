import { NextResponse } from 'next/server';
import { createClient as createServerClient } from '@/utils/supabase/server';

interface RouteParams {
  params: Promise<{ id: string }>;
}

export async function GET(request: Request, { params }: RouteParams) {
  const { id } = await params;
  const supabase = await createServerClient();

  const { data: post, error } = await supabase
    .from('posts')
    .select('id, title, content, source, source_url, views, likes, comments_count, created_at, updated_at')
    .eq('id', id)
    .single();

  if (error) {
    console.error('[API Error] GET /api/posts/[id]:', error);
    return NextResponse.json(
      { success: false, error: 'Post not found' },
      { status: error.code === 'PGRST116' ? 404 : 500 }
    );
  }

  return NextResponse.json({
    success: true,
    post
  });
}