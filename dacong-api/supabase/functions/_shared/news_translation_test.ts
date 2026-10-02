import { assertEquals, assertRejects, assertThrows } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { translateNews, validateTranslations } from "./news_translation.ts";

const news = [{ id: "news-1", title: "Claude coding update", summary: "AI tools improve coding." }];
const valid = [{ id: "news-1", title_zh: "Claude 编程更新", summary_zh: "AI 工具改进编程体验。" }];

Deno.test("translation validates Chinese content and matches only requested IDs", () => {
  assertEquals(validateTranslations(valid, news), valid);
  for (const payload of [[], [...valid, ...valid], [{ ...valid[0], id: "other" }],
    [{ ...valid[0], summary_zh: "" }], [{ ...valid[0], title_zh: "Original", summary_zh: "English only" }]]) {
    assertThrows(() => validateTranslations(payload, news));
  }
});

Deno.test("Anthropic request forces structured translation and keeps article text as data", async () => {
  let body: Record<string, unknown> = {};
  const mockFetch: typeof fetch = (_url, options) => {
    body = JSON.parse(String((options as { body?: unknown })?.body));
    return Promise.resolve(Response.json({ content: [{ type: "tool_use", name: "translate_news", input: { translations: valid } }] }));
  };
  const result = await translateNews(news, "test-key", "test-model", mockFetch);
  assertEquals(result, valid);
  assertEquals(body.model, "test-model");
  assertEquals(body.tool_choice, { type: "tool", name: "translate_news" });
  assertEquals(news[0].title, "Claude coding update");
});

Deno.test("provider failures and missing structured output cannot become cached translations", async () => {
  await assertRejects(() => translateNews(news, "test-key", "test-model",
    () => Promise.resolve(new Response("secret-provider-error", { status: 401 }))), Error, "Translation HTTP 401");
  await assertRejects(() => translateNews(news, "test-key", "test-model",
    () => Promise.resolve(Response.json({ content: [{ type: "text", text: "Not a translation" }] }))), Error, "structured");
});
