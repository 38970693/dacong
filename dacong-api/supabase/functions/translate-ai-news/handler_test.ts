import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { handleTranslationRequest } from "./handler.ts";

interface NewsRow {
  id: string;
  title: string;
  summary: string;
  title_zh: string | null;
  summary_zh: string | null;
}

const rows: NewsRow[] = [
  { id: "first", title: "First model", summary: "First model", title_zh: null, summary_zh: null },
  { id: "second", title: "Second model", summary: "Second model", title_zh: null, summary_zh: null },
];

async function runRequest(
  selected: NewsRow[],
  translate: (input: Request, signal?: AbortSignal | null) => Response,
  provider = "mymemory",
) {
  const trace: string[] = [];
  const saves: { url: URL; body: Record<string, unknown> }[] = [];
  const previousFetch = globalThis.fetch;
  const environment = {
    SUPABASE_URL: "https://translation-test.supabase.co",
    AI_NEWS_SERVICE_ROLE_KEY: "test-service-key",
    AI_NEWS_TRANSLATION_PROVIDER: provider,
    ANTHROPIC_API_KEY: "test-api-key",
  };
  const previousEnvironment = Object.fromEntries(Object.keys(environment).map((key) => [key, Deno.env.get(key)]));
  for (const [key, value] of Object.entries(environment)) Deno.env.set(key, value);
  globalThis.fetch = async (input, init) => {
    const request = new Request(input, init);
    const url = new URL(request.url);
    if (url.host === "translation-test.supabase.co" && url.pathname === "/rest/v1/ai_news_items") {
      if (request.method === "GET") {
        trace.push("select");
        assertEquals(request.headers.get("authorization"), "Bearer test-service-key");
        return Response.json(selected);
      }
      assertEquals(request.method, "PATCH");
      const id = url.searchParams.get("id")!.replace("eq.", "");
      trace.push(`save:${id}`);
      saves.push({ url, body: await request.json() });
      return Response.json([{ id }]);
    }
    if (url.host === "api.mymemory.translated.net") {
      trace.push(`translate:${url.searchParams.get("q")}`);
      return translate(request, (init as { signal?: AbortSignal | null } | undefined)?.signal);
    }
    if (url.host === "api.anthropic.com") {
      trace.push("translate:batch");
      return translate(request);
    }
    throw new Error(`Unexpected request: ${request.method} ${url.origin}${url.pathname}`);
  };
  try {
    const response = await handleTranslationRequest(new Request("https://translation-test.supabase.co/functions/v1/translate-ai-news", {
      method: "POST", headers: { authorization: "Bearer test-service-key" },
    }));
    return { status: response.status, body: await response.json(), trace, saves };
  } finally {
    globalThis.fetch = previousFetch;
    for (const [key, value] of Object.entries(previousEnvironment)) {
      if (value === undefined) Deno.env.delete(key);
      else Deno.env.set(key, value);
    }
  }
}

function translated(text: string) {
  return Response.json({ responseStatus: 200, responseData: { translatedText: text } });
}

Deno.test("MyMemory saves the first translation before a second article exhausts the quota", async () => {
  let calls = 0;
  const result = await runRequest(rows, () => ++calls === 1 ? translated("第一个模型") : Response.json({
    responseStatus: 429, quotaFinished: true, responseData: { translatedText: "Quota exceeded" },
  }));
  assertEquals(result.status, 502);
  assertEquals(result.body, { success: false, error: "Translation daily quota exceeded", data: { translated: 1 } });
  assertEquals(result.trace, ["select", "translate:First model", "save:first", "translate:Second model"]);
  assertEquals(result.saves.length, 1);
});

Deno.test("MyMemory stops without saving when the first article fails", async () => {
  const result = await runRequest(rows, () => new Response("Unavailable", { status: 503 }));
  assertEquals(result.status, 502);
  assertEquals(result.body, { success: false, error: "Translation HTTP 503", data: { translated: 0 } });
  assertEquals(result.trace, ["select", "translate:First model"]);
  assertEquals(result.saves, []);
});

Deno.test("MyMemory reports saved progress when the second article has an HTTP failure", async () => {
  let calls = 0;
  const result = await runRequest(rows, () => ++calls === 1
    ? translated("第一个模型") : new Response("Unavailable", { status: 503 }));
  assertEquals(result.status, 502);
  assertEquals(result.body, { success: false, error: "Translation HTTP 503", data: { translated: 1 } });
  assertEquals(result.trace, ["select", "translate:First model", "save:first", "translate:Second model"]);
});

Deno.test("MyMemory translates and saves each successful article in order", async () => {
  const result = await runRequest(rows, () => translated("模型译文"));
  assertEquals(result.status, 200);
  assertEquals(result.body, { success: true, data: { translated: 2 } });
  assertEquals(result.trace, ["select", "translate:First model", "save:first", "translate:Second model", "save:second"]);
});

Deno.test("MyMemory shares one translation deadline across article titles and summaries", async () => {
  const signals: (AbortSignal | null | undefined)[] = [];
  const selected = rows.map((row) => ({ ...row, summary: `${row.title} details` }));
  const result = await runRequest(selected, (_request, signal) => {
    signals.push(signal);
    return translated("模型译文");
  });
  assertEquals(result.status, 200);
  assertEquals(signals.length, 4);
  assertEquals(signals[0] instanceof AbortSignal, true);
  assertEquals(signals.every((signal) => signal === signals[0]), true);
});

Deno.test("saving a translation retains existing Chinese and guards unchanged original fields", async () => {
  const original = { ...rows[0], summary: "First model details", title_zh: "已有中文标题" };
  const result = await runRequest([original], () => translated("新翻译"));
  assertEquals(result.status, 200);
  assertEquals(result.body.data.translated, 1);
  assertEquals(result.saves[0].body, { title_zh: "已有中文标题", summary_zh: "新翻译" });
  assertEquals(result.saves[0].url.searchParams.get("title"), "eq.First model");
  assertEquals(result.saves[0].url.searchParams.get("summary"), "eq.First model details");
  assertEquals(result.saves[0].url.searchParams.get("status"), "eq.published");
});

Deno.test("Anthropic still translates the selected articles in one batch", async () => {
  let calls = 0;
  const result = await runRequest(rows, () => {
    calls++;
    return Response.json({ content: [{ type: "tool_use", name: "translate_news", input: { translations: rows.map((row) => ({
      id: row.id, title_zh: "模型标题", summary_zh: "模型摘要",
    })) } }] });
  }, "anthropic");
  assertEquals(calls, 1);
  assertEquals(result.status, 200);
  assertEquals(result.body, { success: true, data: { translated: 2 } });
  assertEquals(result.trace, ["select", "translate:batch", "save:first", "save:second"]);
});
