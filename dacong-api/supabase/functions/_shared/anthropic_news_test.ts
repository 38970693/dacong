import { assertEquals, assertThrows } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { articleSummary, parseAnthropicNews } from "./anthropic_news.ts";

const now = Date.parse("2026-10-02T12:00:00Z");

Deno.test("Anthropic featured and list cards retain official links, dates and summaries", () => {
  const html = `<main><a href="/claude-sonnet-5-5"><h2>Introducing Claude Sonnet 5.5</h2>
    <time>Sep 28, 2026</time><p>Faster AI coding &amp; everyday work.</p></a>
    <a href="/news/barclays-scales-claude"><time>Oct 1, 2026</time>
    <span class="PublicationList-module__title">Barclays scales Claude</span></a></main>`;
  const entries = parseAnthropicNews(html, now);
  assertEquals(entries.length, 2);
  assertEquals(entries[0], { title: "Barclays scales Claude", url: "https://www.anthropic.com/news/barclays-scales-claude", summary: "", source_published_at: "2026-10-01T00:00:00.000Z" });
  assertEquals(entries[1].summary, "Faster AI coding & everyday work.");
});

Deno.test("Anthropic ignores external, duplicate, unknown and out-of-window articles", () => {
  const cards = [
    ["/news/new", "2026-10-01"], ["/news/new", "2026-10-01"],
    ["https://evil.example/news", "2026-10-01"], ["/news/old", "2020-01-01"],
    ["/news/future", "2026-10-03"], ["/news/unknown", "unknown"],
  ].map(([url, date]) => `<a href="${url}"><h2>Claude</h2><time datetime="${date}">${date}</time></a>`).join("");
  assertEquals(parseAnthropicNews(cards, now).length, 1);
  assertThrows(() => parseAnthropicNews("<h1>Access denied</h1>", now));
});

Deno.test("article summaries use publisher metadata and fall back to article paragraphs", () => {
  assertEquals(articleSummary(`<meta name="description" content="Claude &amp; AI tools.">`), "Claude & AI tools.");
  assertEquals(articleSummary(`<article><p>Claude <b>coding</b> update.</p></article>`), "Claude coding update.");
  assertEquals(articleSummary(`<h1>Title only</h1>`), "");
});
