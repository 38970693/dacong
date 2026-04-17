import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { csrfMiddleware } from "../_shared/middleware/csrf.ts";
import { validateBody } from "../_shared/middleware/validation.ts";
import { likeCommentSchema } from "../_shared/schemas/comment_schemas.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-csrf-token",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // CSRF 防护
    const csrfError = await csrfMiddleware(req);
    if (csrfError) return csrfError;

    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    // 验证用户身份
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser();

    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 验证输入
    const validation = await validateBody(req, likeCommentSchema);
    if (!validation.success) {
      return validation.response;
    }

    const { comment_id, action } = validation.data;

    // 验证评论是否存在
    const { data: comment, error: commentError } = await supabaseClient
      .from("comments")
      .select("id, likes_count")
      .eq("id", comment_id)
      .single();

    if (commentError || !comment) {
      return new Response(
        JSON.stringify({ success: false, error: "Comment not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (action === "like") {
      // 点赞
      const { error: insertError } = await supabaseClient
        .from("comment_likes")
        .insert({
          comment_id,
          user_id: user.id,
        });

      if (insertError) {
        // 如果已经点赞过，返回成功
        if (insertError.code === "23505") {
          return new Response(
            JSON.stringify({
              success: true,
              data: {
                message: "Already liked",
                likes_count: comment.likes_count,
              },
            }),
            { headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }
        throw insertError;
      }

      return new Response(
        JSON.stringify({
          success: true,
          data: {
            message: "Comment liked",
            likes_count: comment.likes_count + 1,
          },
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    } else {
      // 取消点赞
      const { error: deleteError } = await supabaseClient
        .from("comment_likes")
        .delete()
        .eq("comment_id", comment_id)
        .eq("user_id", user.id);

      if (deleteError) {
        throw deleteError;
      }

      return new Response(
        JSON.stringify({
          success: true,
          data: {
            message: "Comment unliked",
            likes_count: Math.max(0, comment.likes_count - 1),
          },
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
  } catch (error) {
    console.error("Error liking comment:", error);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
