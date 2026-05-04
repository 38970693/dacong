import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';

export async function GET() {
  try {
    const supabaseUrl = 'https://prszkdbdgffbdqclbgol.supabase.co';
    const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByc3prZGJkZ2ZmYmRxY2xiZ29sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2NzUyMDksImV4cCI6MjA5MzI1MTIwOX0.m2eElXYUlB-XHXZ8w988APQs4u1s2rn5VlIOjn2m_t0';

    const supabase = createClient(supabaseUrl, supabaseKey);

    const { data, error } = await supabase
      .from('posts')
      .select('id, title')
      .limit(3);

    return NextResponse.json({
      success: !error,
      error: error?.message || null,
      data: data || [],
      count: data?.length || 0
    });
  } catch (e: any) {
    return NextResponse.json({
      success: false,
      error: e.message,
      data: null
    }, { status: 500 });
  }
}