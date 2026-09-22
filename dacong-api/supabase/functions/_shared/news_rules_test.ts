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
