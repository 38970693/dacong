import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { csrfMiddleware } from "../_shared/middleware/csrf.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-csrf-token",
};

interface ReportCommentRequest {
  comment_id: string;
  reason?: string;
}

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

    const { comment_id, reason = "" } = await req.json() as ReportCommentRequest;

    if (!comment_id) {
      return new Response(
        JSON.stringify({ success: false, error: "comment_id is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 验证评论是否存在
    const { data: comment, error: commentError } = await supabaseClient
      .from("comments")
      .select("id, is_reported")
      .eq("id", comment_id)
      .single();

    if (commentError || !comment) {
      return new Response(
        JSON.stringify({ success: false, error: "Comment not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 标记为已举报
    const { error: updateError } = await supabaseClient
      .from("comments")
      .update({ is_reported: true })
      .eq("id", comment_id);

    if (updateError) {
      throw updateError;
    }

    // TODO: 可以在这里添加举报记录表，记录举报人和举报原因
    // 目前简化处理，只标记评论为已举报

    return new Response(
      JSON.stringify({
        success: true,
        data: {
          message: "Comment reported successfully",
        },
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error reporting comment:", error);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
