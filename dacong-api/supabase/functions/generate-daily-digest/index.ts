import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";
import {
  type DigestCandidate,
  selectDigestItems,
} from "../_shared/digest_rules.ts";

serve(async (req) => {
  if (req.method !== "POST") {
    return Response.json({ error: "Method not allowed" }, { status: 405 });
  }
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!url || !serviceKey) {
    return Response.json({ error: "Server is not configured" }, {
      status: 500,
    });
  }
  if (req.headers.get("authorization") !== `Bearer ${serviceKey}`) {
    return Response.json({ error: "Unauthorized" }, { status: 401 });
  }

  const supabase = createClient(url, serviceKey);
  const today = new Date().toISOString().slice(0, 10);
  const since = new Date(Date.now() - 24 * 3_600_000).toISOString();
  const { data, error } = await supabase
    .from("ai_news_items")
    .select("id,category,importance_score,quality_score,published_at")
    .eq("status", "published")
    .gte("published_at", since)
    .order("importance_score", { ascending: false })
    .limit(100);
  if (error) return Response.json({ error: error.message }, { status: 500 });

  const selected = selectDigestItems((data ?? []) as DigestCandidate[]);
  const intro = selected.length
    ? `过去 24 小时共精选 ${selected.length} 条值得关注的 AI 动态。`
    : "过去 24 小时暂无符合发布标准的 AI 动态。";
  const { data: digest, error: digestError } = await supabase
    .from("daily_digests")
    .upsert({
      digest_date: today,
      title: `${today} AI 日报`,
      intro,
      status: "published",
      item_count: selected.length,
      published_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }, { onConflict: "digest_date" })
    .select("id")
    .single();
  if (digestError) {
    return Response.json({ error: digestError.message }, { status: 500 });
  }

  const { error: deleteError } = await supabase.from("daily_digest_items")
    .delete().eq("digest_id", digest.id);
  if (deleteError) {
    return Response.json({ error: deleteError.message }, { status: 500 });
  }
  if (selected.length) {
    const { error: itemsError } = await supabase.from("daily_digest_items")
      .insert(
        selected.map((item, index) => ({
          digest_id: digest.id,
          news_item_id: item.id,
          rank: index + 1,
          category: item.category,
        })),
      );
    if (itemsError) {
      return Response.json({ error: itemsError.message }, { status: 500 });
    }
  }

  return Response.json({
    success: true,
    data: { date: today, count: selected.length },
  });
});
