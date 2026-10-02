import { assertEquals, assertRejects } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { splitTranslationText, translateNewsWithMyMemory } from "./mymemory_translation.ts";

Deno.test("MyMemory segments stay within 500 UTF-8 bytes without losing Unicode text", () => {
  for (const text of ["AI🙂".repeat(150), "a".repeat(501), "a".repeat(500) + " b", "模型".repeat(150), "one word ".repeat(100)]) {
    const parts = splitTranslationText(text);
    assertEquals(parts.every((part) => new TextEncoder().encode(part).length <= 500), true);
    assertEquals(parts.join("").replace(/\s/g, ""), text.replace(/\s/g, ""));
    assertEquals(parts.some((part) => part.includes("\ufffd")), false);
  }
  assertEquals(splitTranslationText("  "), []);
});

Deno.test("MyMemory uses anonymous official API and saves both Chinese fields", async () => {
  const inputs = [{ id: "news", title: "New model", summary: "AI agents help developers." }];
  const calls: string[] = [];
  const request: typeof fetch = (input, options) => {
    const url = new URL(String(input));
    assertEquals(url.origin, "https://api.mymemory.translated.net");
    assertEquals(url.searchParams.get("langpair"), "en|zh-CN");
    assertEquals(url.searchParams.has("key") || url.searchParams.has("de") || url.searchParams.has("ip"), false);
    assertEquals((options as { signal?: AbortSignal })?.signal instanceof AbortSignal, true);
    calls.push(url.searchParams.get("q")!);
    return Promise.resolve(Response.json({ responseStatus: 200, responseData: {
      translatedText: calls.length === 1 ? "新模型" : "AI Agent 帮助开发者。",
    } }));
  };
  assertEquals(await translateNewsWithMyMemory(inputs, request), [
    { id: "news", title_zh: "新模型", summary_zh: "AI Agent 帮助开发者。" },
  ]);
  assertEquals(calls, [inputs[0].title, inputs[0].summary]);
});

Deno.test("duplicate title-summary uses one request and an empty batch uses none", async () => {
  let calls = 0;
  const request: typeof fetch = () => {
    calls++;
    return Promise.resolve(Response.json({ responseStatus: 200, responseData: { translatedText: "新模型" } }));
  };
  assertEquals(await translateNewsWithMyMemory([], request), []);
  await translateNewsWithMyMemory([{ id: "news", title: "New model", summary: "New model" }], request);
  assertEquals(calls, 1);
});

Deno.test("quota notices, provider errors and English-only results are never translations", async () => {
  const news = [{ id: "news", title: "New model", summary: "New model" }];
  for (const body of [
    { responseStatus: 200, quotaFinished: true, responseData: { translatedText: "QUOTA EXCEEDED" } },
    { responseStatus: 429, responseData: { translatedText: "Quota exceeded" } },
    { responseStatus: 403, responseData: { translatedText: "Provider error" } },
    { responseStatus: 200, responseData: { translatedText: "" } },
    { responseStatus: 200, responseData: { translatedText: "English only" } },
  ]) {
    await assertRejects(() => translateNewsWithMyMemory(news, () => Promise.resolve(Response.json(body))));
  }
  await assertRejects(() => translateNewsWithMyMemory(news,
    () => Promise.resolve(new Response("provider-error", { status: 503 }))), Error, "Translation HTTP 503");
});
