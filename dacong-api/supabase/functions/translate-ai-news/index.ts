import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";
import { translateNews } from "../_shared/news_translation.ts";
import { translateNewsWithMyMemory } from "../_shared/mymemory_translation.ts";

serve(async (req) => {
  if (req.method !== "POST") return Response.json({ error: "Method not allowed" }, { status: 405 });
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const key = Deno.env.get("AI_NEWS_SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!url || !key) return Response.json({ error: "Server is not configured" }, { status: 500 });
  if (req.headers.get("authorization") !== `Bearer ${key}`) return Response.json({ error: "Unauthorized" }, { status: 401 });
  const provider = Deno.env.get("AI_NEWS_TRANSLATION_PROVIDER") ?? "anthropic";
  if (!["anthropic", "mymemory"].includes(provider)) return Response.json({ success: false, error: "Unsupported translation provider" }, { status: 503 });
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (provider === "anthropic" && !apiKey) return Response.json({ success: false, error: "Translation API is not configured" }, { status: 503 });
  const supabase = createClient(url, key);
  const { data: rows, error } = await supabase.from("ai_news_items")
    .select("id,title,summary,title_zh,summary_zh").eq("status", "published").eq("language", "en")
    .or("title_zh.is.null,summary_zh.is.null").order("published_at", { ascending: false }).limit(provider === "mymemory" ? 2 : 5);
  if (error) return Response.json({ success: false, error: error.message }, { status: 500 });
  if (!rows?.length) return Response.json({ success: true, data: { translated: 0 } });
  try {
    const translations = provider === "mymemory" ? await translateNewsWithMyMemory(rows)
      : await translateNews(rows, apiKey!, Deno.env.get("AI_NEWS_TRANSLATION_MODEL") ?? "claude-sonnet-5-5");
    let translated = 0;
    for (const result of translations) {
      const original = rows.find((row) => row.id === result.id)!;
      const { data: saved, error: saveError } = await supabase.from("ai_news_items").update({
        title_zh: original.title_zh || result.title_zh, summary_zh: original.summary_zh || result.summary_zh,
      }).eq("id", result.id).eq("status", "published").eq("title", original.title).eq("summary", original.summary)
        .or("title_zh.is.null,summary_zh.is.null").select("id");
      if (saveError) throw saveError;
      translated += saved?.length ?? 0;
    }
    return Response.json({ success: true, data: { translated } });
  } catch (error) {
    return Response.json({ success: false, error: error instanceof Error ? error.message : "Translation failed" }, { status: 502 });
  }
});
