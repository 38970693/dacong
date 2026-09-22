import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";
import {
  curateNews,
  findMergeCandidate,
  type NewsCategory,
  type RawNews,
  type SourceTier,
} from "../_shared/news_rules.ts";

function authorized(req: Request, serviceKey: string): boolean {
  return req.headers.get("authorization") === `Bearer ${serviceKey}`;
}

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
  if (!authorized(req, serviceKey)) {
    return Response.json({ error: "Unauthorized" }, { status: 401 });
  }

  const supabase = createClient(url, serviceKey);
  const { data: settings, error: settingsError } = await supabase
    .from("ai_source_settings")
    .select("source,tier,default_category,enabled");
  if (settingsError) {
    return Response.json({ error: settingsError.message }, { status: 500 });
  }

  const sourceSettings = new Map(
    (settings ?? []).map((item) => [item.source.toLowerCase(), item]),
  );
  const { data: rawRows, error: rawError } = await supabase
    .from("hot_news_raw")
    .select("id,source,title,url,summary,score,fetched_at,is_ai_related")
    .order("fetched_at", { ascending: false })
    .limit(250);
  if (rawError) {
    return Response.json({ error: rawError.message }, { status: 500 });
  }

  const rawIds = (rawRows ?? []).map((item) => item.id);
  const { data: processed, error: processedError } = rawIds.length
    ? await supabase.from("ai_news_sources").select("raw_news_id").in(
      "raw_news_id",
      rawIds,
    )
    : { data: [], error: null };
  if (processedError) {
    return Response.json({ error: processedError.message }, { status: 500 });
  }
  const processedIds = new Set(
    (processed ?? []).map((item) => item.raw_news_id),
  );

  const since = new Date(Date.now() - 72 * 3_600_000).toISOString();
  const { data: recent } = await supabase
    .from("ai_news_items")
    .select("id,event_key,title,status")
    .gte("created_at", since);

  let published = 0;
  let quarantined = 0;
  let merged = 0;
  const errors: string[] = [];

  for (const raw of (rawRows ?? []) as RawNews[]) {
    if (processedIds.has(raw.id)) continue;
    const setting = sourceSettings.get(raw.source.toLowerCase());
    if (setting?.enabled === false) continue;
    try {
      const tier = (setting?.tier ?? "community") as SourceTier;
      const category = (setting?.default_category ?? null) as
        | NewsCategory
        | null;
      const curated = await curateNews(raw, tier, category);
      const similar = findMergeCandidate(recent ?? [], curated);

      let itemId: string;
      if (similar) {
        itemId = similar.id;
        merged += 1;
      } else {
        const { data: item, error: itemError } = await supabase
          .from("ai_news_items")
          .upsert(curated, { onConflict: "event_key", ignoreDuplicates: false })
          .select("id,status")
          .single();
        if (itemError) throw itemError;
        itemId = item.id;
        (recent ?? []).push({
          id: item.id,
          event_key: curated.event_key,
          title: curated.title,
          status: item.status,
        });
        if (item.status === "published") published += 1;
        else quarantined += 1;
      }

      const { error: sourceError } = await supabase.from("ai_news_sources")
        .upsert({
          news_item_id: itemId,
          raw_news_id: raw.id,
          source: raw.source,
          url: raw.url,
          original_title: raw.title,
          source_published_at: raw.fetched_at,
          is_primary: !similar,
        }, { onConflict: "raw_news_id", ignoreDuplicates: true });
      if (sourceError) throw sourceError;
    } catch (error) {
      errors.push(
        `${raw.id}: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  return Response.json({
    success: errors.length === 0,
    data: { published, quarantined, merged, errors: errors.slice(0, 20) },
  }, { status: errors.length ? 207 : 200 });
});
