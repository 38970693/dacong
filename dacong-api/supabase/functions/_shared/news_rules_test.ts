import {
  assert,
  assertEquals,
  assertGreaterOrEqual,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  cleanText,
  curateNews,
  detectLanguage,
  findMergeCandidate,
  summarize,
  titleSimilarity,
} from "./news_rules.ts";

Deno.test("cleanText removes markup and normalizes whitespace", () => {
  assertEquals(cleanText("<p>Hello&nbsp;  AI</p>"), "Hello AI");
});

Deno.test("exact withdrawn news remains the merge target", () => {
  const existing = [{
    id: "withdrawn-id",
    event_key: "same-event",
    title: "OpenAI releases a model",
    status: "withdrawn" as const,
  }];
  assertEquals(
    findMergeCandidate(existing, {
      event_key: "same-event",
      title: "OpenAI releases a model",
    })?.id,
    "withdrawn-id",
  );
});

Deno.test("summarize keeps source language and respects limits", () => {
  const english = "OpenAI released a new model. ".repeat(20);
  assertEquals(detectLanguage(english), "en");
  assert(summarize(english, "en").length <= 241);
  const chinese = "这是一个关于人工智能模型更新的完整句子。".repeat(20);
  assertEquals(detectLanguage(chinese), "zh");
  assert(summarize(chinese, "zh").length <= 151);
});

Deno.test("official AI news is published and categorized", async () => {
  const result = await curateNews({
    id: "1",
    source: "OpenAI",
    title: "OpenAI releases a new GPT model",
    url: "https://example.com/release",
    summary: "The model adds a larger context window for developers.",
    fetched_at: new Date().toISOString(),
    is_ai_related: true,
  }, "official");
  assertEquals(result.status, "published");
  assertEquals(result.category, "model");
  assertGreaterOrEqual(result.quality_score, 65);
});

Deno.test("low signal community content is quarantined", async () => {
  const result = await curateNews({
    id: "2",
    source: "X",
    title: "Look at this",
    url: "https://x.com/example/status/1",
    summary: "Interesting.",
    fetched_at: new Date().toISOString(),
  }, "community");
  assertEquals(result.status, "quarantined");
});

Deno.test("similar titles have a high similarity score", () => {
  assertGreaterOrEqual(
    titleSimilarity(
      "OpenAI releases GPT 5 model",
      "OpenAI releases the GPT 5 model",
    ),
    0.88,
  );
});

Deno.test("generic business and surveillance news is not AI even when the feed marks it", async () => {
  for (const title of ["Company funding and policy update", "Research along the virtual border wall", "Chair company releases a new product"]) {
    const result = await curateNews({ id: title, source: "MIT_Tech_AI", title,
      summary: "Research into surveillance towers along the border.", url: "https://example.com/story",
      is_ai_related: true, fetched_at: new Date().toISOString() }, "professional");
    assertEquals(result.status, "quarantined");
  }
});

Deno.test("AI coding agents and MCP are developer tools", async () => {
  const result = await curateNews({ id: "agent", source: "OpenAI",
    title: "AI coding agents get MCP tools", summary: "A developer SDK for agent workflows.",
    url: "https://example.com/agents", fetched_at: new Date().toISOString() }, "official");
  assertEquals(result.status, "published");
  assertEquals(result.category, "developer_tool");
});

Deno.test("publication date overrides collection time for freshness and deduplication", async () => {
  const originalDate = "2020-01-01T00:00:00Z";
  const raw = { id: "old", source: "OpenAI", title: "GPT model release", summary: "AI model update.",
    url: "https://example.com/old", source_published_at: originalDate,
    fetched_at: new Date().toISOString() };
  const result = await curateNews(raw, "official");
  assertEquals(result.published_at, originalDate);
  assertEquals(result.quality_score, 75);
  const repeated = await curateNews({ ...raw, fetched_at: "2030-01-01T00:00:00Z" }, "official");
  assertEquals(result.event_key, repeated.event_key);
});

Deno.test("future publication dates are quarantined", async () => {
  const result = await curateNews({ id: "future", source: "OpenAI",
    title: "OpenAI AI model release", summary: "GPT model update.", url: "https://example.com/future",
    source_published_at: new Date(Date.now() + 86_400_000).toISOString(), is_ai_related: true }, "official");
  assertEquals(result.status, "quarantined");
});
