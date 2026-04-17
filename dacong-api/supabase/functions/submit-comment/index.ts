import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { csrfMiddleware } from "../_shared/middleware/csrf.ts";
import { validateBody } from "../_shared/middleware/validation.ts";
import { submitCommentSchema } from "../_shared/schemas/comment_schemas.ts";
import { sanitizeComment } from "../_shared/utils/sanitize.ts";

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
    const validation = await validateBody(req, submitCommentSchema);
    if (!validation.success) {
      return validation.response;
    }

    const { content_id, content, parent_id } = validation.data;

    // 清理内容并检查敏感词
    const { sanitized: sanitizedContent, needsModeration } = sanitizeComment(content);
    const moderationStatus = needsModeration ? "pending" : "approved";

    // 验证 content_id 是否存在
    const { data: contentExists, error: contentError } = await supabaseClient
      .from("published_content")
      .select("id")
      .eq("id", content_id)
      .single();

    if (contentError || !contentExists) {
      return new Response(
        JSON.stringify({ success: false, error: "Content not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 如果是回复，验证 parent_id 是否存在
    if (parent_id) {
      const { data: parentExists, error: parentError } = await supabaseClient
        .from("comments")
        .select("id")
        .eq("id", parent_id)
        .single();

      if (parentError || !parentExists) {
        return new Response(
          JSON.stringify({ success: false, error: "Parent comment not found" }),
          { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // 插入评论
    const { data: comment, error: insertError } = await supabaseClient
      .from("comments")
      .insert({
        content_id,
        user_id: user.id,
        parent_id,
        content: sanitizedContent,
        moderation_status: moderationStatus,
      })
      .select()
      .single();

    if (insertError) {
      throw insertError;
    }

    return new Response(
      JSON.stringify({
        success: true,
        data: {
          comment: {
            ...comment,
            is_liked: false,
          },
          moderation_status: moderationStatus,
          message: moderationStatus === "pending"
            ? "Comment submitted for review"
            : "Comment posted successfully",
        },
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error submitting comment:", error);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
