import { NewsTranslation, TranslationInput, validateTranslations } from "./news_translation.ts";

export function splitTranslationText(text: string): string[] {
  const encoder = new TextEncoder();
  const chunks: string[] = [];
  let remaining = text.trim();
  while (remaining) {
    let end = 0;
    let bytes = 0;
    for (const character of remaining) {
      const size = encoder.encode(character).length;
      if (bytes + size > 500) break;
      bytes += size;
      end += character.length;
    }
    if (end < remaining.length) {
      const space = remaining.lastIndexOf(" ", end - 1);
      if (space > end / 2) end = space + 1;
    }
    chunks.push(remaining.slice(0, end).trim());
    remaining = remaining.slice(end).trim();
  }
  return chunks;
}

export async function translateNewsWithMyMemory(
  news: TranslationInput[], request: typeof fetch = fetch,
): Promise<NewsTranslation[]> {
  const signal = AbortSignal.timeout(40_000);
  const translate = async (text: string): Promise<string> => {
    const parts: string[] = [];
    for (const chunk of splitTranslationText(text)) {
      const url = new URL("https://api.mymemory.translated.net/get");
      url.searchParams.set("q", chunk);
      url.searchParams.set("langpair", "en|zh-CN");
      const response = await request(url, { signal });
      if (!response.ok) throw new Error(`Translation HTTP ${response.status}`);
      const body = await response.json();
      if (body.quotaFinished || Number(body.responseStatus) === 429) throw new Error("Translation daily quota exceeded");
      const translated = body.responseData?.translatedText;
      if (Number(body.responseStatus) !== 200 || typeof translated !== "string" || !translated.trim()) {
        throw new Error("Invalid translation provider response");
      }
      parts.push(translated.trim());
    }
    return parts.join("");
  };
  const results: NewsTranslation[] = [];
  for (const row of news) {
    const title = await translate(row.title);
    const summary = row.summary.trim() === row.title.trim() || !row.summary.trim()
      ? title : await translate(row.summary);
    results.push({ id: row.id, title_zh: title, summary_zh: summary });
  }
  return validateTranslations(results, news);
}
