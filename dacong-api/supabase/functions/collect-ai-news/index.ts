import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";
import { AI_RSS_FEEDS, parseRecentRSS } from "../_shared/rss_rules.ts";
import { articleSummary, parseAnthropicNews } from "../_shared/anthropic_news.ts";

const SOURCES = [...AI_RSS_FEEDS, ["Anthropic", "https://www.anthropic.com/news"] as const];

serve(async (req) => {
  if (req.method !== "POST") return Response.json({ error: "Method not allowed" }, { status: 405 });
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const key = Deno.env.get("AI_NEWS_SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!url || !key) return Response.json({ error: "Server is not configured" }, { status: 500 });
  if (req.headers.get("authorization") !== `Bearer ${key}`) return Response.json({ error: "Unauthorized" }, { status: 401 });

  const supabase = createClient(url, key);
  const { data: settings, error } = await supabase.from("ai_source_settings").select("source,enabled");
  if (error) return Response.json({ error: error.message }, { status: 500 });
  const disabled = new Set((settings ?? []).filter((row) => !row.enabled).map((row) => row.source.toLowerCase()));
  const sources = await Promise.all(SOURCES.map(async ([source, feedURL]) => {
    if (disabled.has(source.toLowerCase())) return { source, skipped: true, written: 0 };
    try {
      const response = await fetch(feedURL, { signal: AbortSignal.timeout(20_000),
        headers: { "User-Agent": "Dacong-AI-News/1.1 (+https://dacong-weld.vercel.app)", "Accept": "application/rss+xml, application/atom+xml, application/xml, text/xml" } });
      if (!response.ok) throw new Error(`RSS HTTP ${response.status}`);
      const content = await response.text();
      const entries = source === "Anthropic" ? parseAnthropicNews(content) : parseRecentRSS(content);
      if (!entries.length) return { source, fetched: 0, written: 0 };
      const { data: existing, error: lookupError } = await supabase.from("hot_news_raw").select("url").eq("source", source).in("url", entries.map((entry) => entry.url));
      if (lookupError) throw lookupError;
      const known = new Set((existing ?? []).map((row) => row.url));
      let summaryFailures = 0;
      const rows = await Promise.all(entries.filter((entry) => !known.has(entry.url)).map(async (entry) => {
        if (source === "Anthropic" && !entry.summary) {
          try {
            const article = await fetch(entry.url, { signal: AbortSignal.timeout(12_000) });
            if (!article.ok) throw new Error(`Article HTTP ${article.status}`);
            entry.summary = articleSummary(await article.text());
            if (!entry.summary) summaryFailures += 1;
          } catch { summaryFailures += 1; }
        }
        return { ...entry, source, is_ai_related: true, fetched_at: new Date().toISOString() };
      }));
      if (rows.length) {
        const { error: insertError } = await supabase.from("hot_news_raw").insert(rows);
        if (insertError) throw insertError;
      }
      return { source, fetched: entries.length, written: rows.length, summaryFailures };
    } catch (error) {
      return { source, written: 0, error: error instanceof Error ? error.message : String(error) };
    }
  }));
  if (!sources.some((source) => "fetched" in source)) return Response.json({ success: false, data: { sources } }, { status: 502 });
  try {
    const response = await fetch(`${url}/functions/v1/process-ai-news`, { method: "POST", signal: AbortSignal.timeout(30_000),
      headers: { "Content-Type": "application/json", "Authorization": `Bearer ${key}` }, body: "{}" });
    const processed = await response.json();
    return Response.json({ success: response.ok && processed.success, data: { sources, processed } }, { status: response.ok ? response.status : 502 });
  } catch {
    return Response.json({ success: false, data: { sources }, error: "Processing failed; pending items will be retried by the processing schedule" }, { status: 502 });
  }
});
