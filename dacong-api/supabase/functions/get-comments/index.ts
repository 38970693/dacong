import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface GetCommentsRequest {
  content_id: string;
  parent_id?: string | null;
  page?: number;
  limit?: number;
  sort?: "latest" | "popular";
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    const { content_id, parent_id = null, page = 1, limit = 20, sort = "latest" } = await req.json() as GetCommentsRequest;

    if (!content_id) {
      return new Response(
        JSON.stringify({ error: "content_id is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const offset = (page - 1) * limit;

    // 构建查询
    let query = supabaseClient
      .from("comments")
      .select(`
        id,
        content_id,
        user_id,
        parent_id,
        content,
        likes_count,
        reply_count,
        created_at,
        updated_at
      `)
      .eq("content_id", content_id)
      .eq("is_deleted", false)
      .eq("moderation_status", "approved");

    // 过滤父评论或回复
    if (parent_id === null) {
      query = query.is("parent_id", null);
    } else {
      query = query.eq("parent_id", parent_id);
    }

    // 排序
    if (sort === "popular") {
      query = query.order("likes_count", { ascending: false });
    } else {
      query = query.order("created_at", { ascending: false });
    }

    // 分页
    query = query.range(offset, offset + limit - 1);

    const { data: comments, error, count } = await query;

    if (error) {
      throw error;
    }

    // 获取当前用户的点赞状态
    const { data: { user } } = await supabaseClient.auth.getUser();
    let userLikes: string[] = [];

    if (user && comments && comments.length > 0) {
      const commentIds = comments.map(c => c.id);
      const { data: likes } = await supabaseClient
        .from("comment_likes")
        .select("comment_id")
        .eq("user_id", user.id)
        .in("comment_id", commentIds);

      userLikes = likes?.map(l => l.comment_id) || [];
    }

    // 添加 is_liked 字段
    const commentsWithLikes = comments?.map(comment => ({
      ...comment,
      is_liked: userLikes.includes(comment.id),
    })) || [];

    return new Response(
      JSON.stringify({
        success: true,
        data: {
          comments: commentsWithLikes,
          pagination: {
            page,
            limit,
            total: count || 0,
            has_more: count ? offset + limit < count : false,
          },
        },
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error fetching comments:", error);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
