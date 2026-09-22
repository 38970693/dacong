import type { NewsCategory } from "./news_rules.ts";

export interface DigestCandidate {
  id: string;
  category: NewsCategory;
  importance_score: number;
  quality_score: number;
  published_at: string;
}

export function selectDigestItems(
  candidates: DigestCandidate[],
  limit = 10,
): DigestCandidate[] {
  const categoryCounts = new Map<NewsCategory, number>();
  const sorted = [...candidates].sort((a, b) =>
    b.importance_score - a.importance_score ||
    b.quality_score - a.quality_score ||
    b.published_at.localeCompare(a.published_at)
  );
  const selected: DigestCandidate[] = [];
  for (const item of sorted) {
    const count = categoryCounts.get(item.category) ?? 0;
    if (count >= 3) continue;
    selected.push(item);
    categoryCounts.set(item.category, count + 1);
    if (selected.length >= limit) break;
  }
  return selected;
}
