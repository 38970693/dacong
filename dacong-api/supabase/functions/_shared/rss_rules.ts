import { XMLParser, XMLValidator } from "npm:fast-xml-parser@5.3.0";
import { cleanText } from "./news_rules.ts";

export const AI_RSS_FEEDS = [
  ["OpenAI", "https://openai.com/news/rss.xml"],
  ["HuggingFace", "https://huggingface.co/blog/feed.xml"],
  ["GitHub", "https://github.blog/ai-and-ml/feed/"],
  ["TheSequence", "https://thesequence.substack.com/feed"],
  ["VentureBeat_AI", "https://venturebeat.com/category/ai/feed/"],
  ["Google_AI", "https://blog.google/technology/ai/rss/"],
  ["MIT_Tech_AI", "https://www.technologyreview.com/topic/artificial-intelligence/feed"],
] as const;

interface FeedEntry {
  title: string;
  url: string;
  summary: string;
  source_published_at: string;
}

function record(value: unknown): Record<string, unknown> {
  return value !== null && typeof value === "object" ? value as Record<string, unknown> : {};
}

function list(value: unknown): unknown[] {
  return value === undefined ? [] : Array.isArray(value) ? value : [value];
}

function text(value: unknown): string {
  const content = typeof value === "string" ? value : record(value)["#text"];
  return typeof content === "string" ? content : "";
}

export function parseRecentRSS(xml: string, now = Date.now()): FeedEntry[] {
  if (XMLValidator.validate(xml) !== true) throw new Error("Invalid RSS XML");
  const parsed = new XMLParser({ ignoreAttributes: false, parseTagValue: false,
    processEntities: true, removeNSPrefix: true }).parse(xml);
  const root = record(parsed);
  const channel = record(record(root.rss).channel);
  const feed = record(root.feed);
  if (!root.rss && !root.feed) throw new Error("Unsupported RSS format");
  const entries: FeedEntry[] = [];
  const seen = new Set<string>();
  for (const value of list(channel.item ?? feed.entry)) {
    const item = record(value);
    const title = cleanText(text(item.title));
    const links = list(item.link);
    const link = links.find((value) => record(value)["@_rel"] === "alternate") ?? links[0];
    const url = text(record(link)["@_href"]) || text(link);
    const published = Date.parse(text(item.pubDate ?? item.published ?? item.updated));
    if (!title || !/^https?:\/\//i.test(url) || seen.has(url) || !Number.isFinite(published) ||
      published > now || published < now - 30 * 86_400_000) continue;
    seen.add(url);
    entries.push({ title, url, summary: cleanText(text(item.description ?? item.summary ?? item.content ?? item.encoded)).slice(0, 500),
      source_published_at: new Date(published).toISOString() });
  }
  return entries.sort((a, b) => b.source_published_at.localeCompare(a.source_published_at)).slice(0, 20);
}
