/**
 * DaCong Edge Function: content-moderation
 * 从 moderation_queue 消费待审核内容，调用 OpenAI Moderation API
 * 触发方式：
 *   1. Supabase Database Webhook（posts 表 INSERT）
 *   2. cron job 定时扫描 pending 队列
 */
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;
const MODERATION_ENDPOINT = "https://api.openai.com/v1/moderations";

async function moderateText(text: string): Promise<{ flagged: boolean; categories: Record<string, boolean> }> {
  const resp = await fetch(MODERATION_ENDPOINT, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ input: text }),
  });
  if (!resp.ok) throw new Error(`OpenAI API error: ${resp.status}`);
  const data = await resp.json();
  const result = data.results[0];
  return { flagged: result.flagged, categories: result.categories };
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // ── 从队列取出一条待审核内容 ─────────────────────
    const { data: item, error: fetchErr } = await supabase
      .from("moderation_queue")
      .select("id, target_type, target_id")
      .eq("status", "pending")
      .order("created_at", { ascending: true })
      .limit(1)
      .single();

    if (fetchErr && fetchErr.code !== "PGRST116") throw fetchErr; // PGRST116 = no rows

    if (!item) {
      return new Response(JSON.stringify({ ok: true, message: "Queue empty" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 标记为处理中
    await supabase
      .from("moderation_queue")
      .update({ status: "processing" })
      .eq("id", item.id);

    // ── 获取原始内容 ─────────────────────────────────
    const { data: content, error: contentErr } = await supabase
      .from(item.target_type === "post" ? "posts" : "comments")
      .select("id, content")
      .eq("id", item.target_id)
      .single();

    if (contentErr) throw contentErr;

    // ── 调用 OpenAI Moderation ──────────────────────
    const modResult = await moderateText(content.content);

    const newStatus = modResult.flagged ? "flagged" : "passed";
    await supabase
      .from("moderation_queue")
      .update({
        status: newStatus,
        ai_result: modResult,
        processed_at: new Date().toISOString(),
      })
      .eq("id", item.id);

    // 同时更新原始 posts/comments 的 moderation_status
    await supabase
      .from(item.target_type === "post" ? "posts" : "comments")
      .update({ moderation_status: newStatus })
      .eq("id", item.target_id);

    return new Response(
      JSON.stringify({ ok: true, id: item.id, status: newStatus }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
