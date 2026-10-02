import { assertEquals, assertThrows } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { parseRecentRSS } from "./rss_rules.ts";

const now = Date.parse("2026-10-02T12:00:00Z");

Deno.test("RSS preserves publication date and cleans HTML", () => {
  const rows = parseRecentRSS(`<rss><channel><item><title>AI &amp; tools</title>
    <link>https://example.com/ai</link><description><![CDATA[<p>OpenAI <b>agent</b> update.</p>]]></description>
    <pubDate>Thu, 01 Oct 2026 12:00:00 GMT</pubDate></item></channel></rss>`, now);
  assertEquals(rows, [{ title: "AI & tools", url: "https://example.com/ai", summary: "OpenAI agent update.", source_published_at: "2026-10-01T12:00:00.000Z" }]);
});

Deno.test("Atom uses the alternate link and published date", () => {
  const rows = parseRecentRSS(`<feed xmlns="http://www.w3.org/2005/Atom"><entry><title>Claude coding</title>
    <link rel="self" href="https://example.com/feed/1"/><link rel="alternate" href="https://example.com/article"/>
    <summary>AI coding agents</summary><published>2026-09-30T12:00:00Z</published>
    <updated>2026-10-02T00:00:00Z</updated></entry></feed>`, now);
  assertEquals(rows[0].url, "https://example.com/article");
  assertEquals(rows[0].source_published_at, "2026-09-30T12:00:00.000Z");
});

Deno.test("old, future, unknown dates and duplicate URLs are excluded", () => {
  const dates = ["2020-01-01", "2026-10-03", "bad date", "2026-10-01", "2026-10-01"];
  const rows = parseRecentRSS(`<rss><channel>${dates.map((date) => `<item><title>AI</title><link>https://example.com/article</link><pubDate>${date}</pubDate></item>`).join("")}</channel></rss>`, now);
  assertEquals(rows.length, 1);
});

Deno.test("malformed and non-feed XML fails instead of looking empty", () => {
  assertThrows(() => parseRecentRSS("<rss><broken></rss>", now));
  assertThrows(() => parseRecentRSS("<html>Blocked</html>", now));
});
