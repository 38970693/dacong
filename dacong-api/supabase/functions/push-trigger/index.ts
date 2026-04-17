/**
 * DaCong Edge Function: push-trigger
 * 推送触发器：当用户订阅的模型/话题有新动态时，通过 FCM 发送推送
 * 触发方式：Supabase Database Webhook（posts / model_ranks 变动时）
 */
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY") ?? "";

interface Subscription {
  id: number;
  user_id: string;
  sub_type: string;
  sub_value: string;
  notify_enabled: boolean;
  fcm_token: string;
}

async function sendFCM(token: string, title: string, body: string, data: Record<string, string> = {}) {
  if (!FCM_SERVER_KEY) return;
  const resp = await fetch("https://fcm.googleapis.com/fcm/send", {
    method: "POST",
    headers: {
      "Authorization": `key=${FCM_SERVER_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      to: token,
      notification: { title, body },
      data,
      priority: "high",
    }),
  });
  if (!resp.ok) console.error(`FCM error: ${resp.status}`);
  return resp.json();
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { trigger_type, table, record } = await req.json();

    // ── 找出需要通知的订阅 ───────────────────────────
    let subType: string, subValue: string;

    if (table === "posts" && record) {
      subType = "topic";
      subValue = record.topic_id ?? "";
    } else if (table === "model_ranks" && record) {
      subType = "model";
      subValue = record.model_id ?? "";
    } else {
      return new Response(JSON.stringify({ ok: true, message: "Unhandled trigger" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: subs, error } = await supabase
      .from("subscriptions")
      .select("id, user_id, sub_type, sub_value, notify_enabled, fcm_token:user_fcm_token")
      .eq("sub_type", subType)
      .eq("sub_value", subValue)
      .eq("notify_enabled", true);

    if (error) throw error;

    // ── 发送推送 ─────────────────────────────────────
    const title = table === "posts" ? "话题更新" : "模型排名变动";
    const body = table === "posts"
      ? `您订阅的话题有新帖子：${record.title?.slice(0, 50)}`
      : `模型排名已更新，综合得分：${record.score}`;

    const results = await Promise.allSettled(
      (subs as unknown as Subscription[]).map((sub) =>
        sendFCM(sub.fcm_token as string, title, body, { table, id: record.id })
      )
    );

    const sent = results.filter((r) => r.status === "fulfilled").length;
    return new Response(JSON.stringify({ ok: true, notified: sent, total: results.length }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
