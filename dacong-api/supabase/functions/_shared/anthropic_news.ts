import { DOMParser } from "npm:linkedom@0.18.12/worker";
import { cleanText } from "./news_rules.ts";

export interface OfficialNews {
  title: string;
  url: string;
  summary: string;
  source_published_at: string;
}

export function parseAnthropicNews(html: string, now = Date.now()): OfficialNews[] {
  const document = new DOMParser().parseFromString(html, "text/html");
  const entries: OfficialNews[] = [];
  const seen = new Set<string>();
  let foundCards = false;
  for (const anchor of document.querySelectorAll("a[href]")) {
    const time = anchor.querySelector("time");
    const title = cleanText(anchor.querySelector('h2, h3, [class*="__title"]')?.textContent);
    if (!time || !title) continue;
    foundCards = true;
    const date = time.getAttribute("datetime") || `${time.textContent} UTC`;
    const published = Date.parse(date);
    let url: URL;
    try { url = new URL(anchor.getAttribute("href") ?? "", "https://www.anthropic.com"); }
    catch { continue; }
    if (url.origin !== "https://www.anthropic.com" || seen.has(url.href) ||
      !Number.isFinite(published) || published > now || published < now - 30 * 86_400_000) continue;
    seen.add(url.href);
    entries.push({ title, url: url.href, summary: cleanText(anchor.querySelector("p")?.textContent).slice(0, 500),
      source_published_at: new Date(published).toISOString() });
  }
  if (!foundCards) throw new Error("Anthropic newsroom structure is unavailable");
  return entries.sort((a, b) => b.source_published_at.localeCompare(a.source_published_at)).slice(0, 20);
}

export function articleSummary(html: string): string {
  const document = new DOMParser().parseFromString(html, "text/html");
  const description = document.querySelector('meta[name="description"]')?.getAttribute("content") ||
    document.querySelector('meta[property="og:description"]')?.getAttribute("content") ||
    document.querySelector("article p, main p")?.textContent;
  return cleanText(description).slice(0, 500);
}
