export type NewsCategory =
  | "model"
  | "developer_tool"
  | "open_source"
  | "research"
  | "industry";
export type SourceTier = "official" | "professional" | "community";

export interface RawNews {
  id: string | number;
  source: string;
  title: string;
  url: string;
  summary?: string | null;
  score?: number | null;
  fetched_at?: string | null;
  source_published_at?: string | null;
  is_ai_related?: boolean | null;
}

export interface CuratedNews {
  event_key: string;
  normalized_title: string;
  title: string;
  summary: string;
  language: "zh" | "en" | "other";
  category: NewsCategory;
  source_tier: SourceTier;
  quality_score: number;
  importance_score: number;
  status: "published" | "quarantined";
  published_at: string | null;
}

export interface ExistingNews {
  id: string;
  event_key: string;
  title: string;
  status: "published" | "quarantined" | "withdrawn";
}

const CATEGORY_KEYWORDS: Record<NewsCategory, string[]> = {
  model: ["model", "llm", "gpt", "claude", "gemini", "llama", "模型", "多模态"],
  developer_tool: [
    "api",
    "sdk",
    "agent",
    "coding",
    "developer",
    "copilot",
    "codex",
    "mcp",
    "harness",
    "开发",
    "编程",
    "智能体",
  ],
  open_source: [
    "github",
    "open source",
    "release",
    "repository",
    "开源",
    "发布",
  ],
  research: ["paper", "research", "benchmark", "arxiv", "论文", "研究", "评测"],
  industry: [
    "funding",
    "company",
    "policy",
    "business",
    "融资",
    "公司",
    "行业",
    "政策",
  ],
};

const AI_SIGNALS = [
  /\b(?:ai|artificial intelligence|machine learning|deep learning|llms?)\b/i,
  /\b(?:gpt(?:-?\d)?|chatgpt|openai|anthropic|claude|gemini|llama|qwen|deepseek|kimi|mistral|codex|copilot|hugging\s?face)\b/i,
  /\b(?:neural networks?|diffusion models?|language models?|computer vision|coding agents?|ai agents?|mcp)\b/i,
  /人工智能|大语言模型|大模型|机器学习|深度学习|神经网络|智能体/,
];

export function cleanText(value: string | null | undefined): string {
  return (value ?? "")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;|&#160;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/\s+/g, " ")
    .trim();
}

export function normalizeTitle(title: string): string {
  return cleanText(title)
    .toLowerCase()
    .replace(/[\p{P}\p{S}]/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
}

export function detectLanguage(text: string): "zh" | "en" | "other" {
  if (!text) return "other";
  const chinese = (text.match(/[\u4e00-\u9fff]/g) ?? []).length;
  if (chinese / text.length >= 0.15) return "zh";
  if (/[a-z]/i.test(text)) return "en";
  return "other";
}

export function summarize(
  text: string,
  language: "zh" | "en" | "other",
): string {
  const cleaned = cleanText(text);
  if (!cleaned) return "";
  const limit = language === "zh" ? 150 : 240;
  if (cleaned.length <= limit) return cleaned;
  const candidate = cleaned.slice(0, limit + 1);
  const sentenceEnd = Math.max(
    candidate.lastIndexOf("。"),
    candidate.lastIndexOf("！"),
    candidate.lastIndexOf("？"),
    candidate.lastIndexOf(". "),
    candidate.lastIndexOf("! "),
    candidate.lastIndexOf("? "),
  );
  const cut = sentenceEnd >= Math.floor(limit * 0.55) ? sentenceEnd + 1 : limit;
  return `${candidate.slice(0, cut).trim()}…`;
}

export function classify(
  text: string,
  fallback?: NewsCategory | null,
): NewsCategory {
  const lower = text.toLowerCase();
  let best: NewsCategory = fallback ?? "industry";
  let bestScore = 0;
  for (
    const [category, keywords] of Object.entries(CATEGORY_KEYWORDS) as [
      NewsCategory,
      string[],
    ][]
  ) {
    const score = keywords.filter((keyword) => lower.includes(keyword)).length;
    if (score > bestScore) {
      best = category;
      bestScore = score;
    }
  }
  return best;
}

export function titleSimilarity(a: string, b: string): number {
  const left = new Set(normalizeTitle(a).split(" ").filter(Boolean));
  const right = new Set(normalizeTitle(b).split(" ").filter(Boolean));
  if (!left.size || !right.size) return 0;
  const intersection = [...left].filter((token) => right.has(token)).length;
  return (2 * intersection) / (left.size + right.size);
}

export function findMergeCandidate(
  existing: ExistingNews[],
  news: Pick<CuratedNews, "event_key" | "title">,
): ExistingNews | undefined {
  const exact = existing.find((item) => item.event_key === news.event_key);
  if (exact) return exact;
  return existing.find((item) =>
    item.status !== "withdrawn" &&
    titleSimilarity(item.title, news.title) >= 0.88
  );
}

export async function eventKey(
  title: string,
  publishedAt?: string | null,
): Promise<string> {
  const date = publishedAt ? new Date(publishedAt) : new Date();
  const bucket = Number.isNaN(date.getTime())
    ? new Date().toISOString().slice(0, 10)
    : date.toISOString().slice(0, 10);
  const bytes = new TextEncoder().encode(`${normalizeTitle(title)}|${bucket}`);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)].map((byte) =>
    byte.toString(16).padStart(2, "0")
  ).join("");
}

export async function curateNews(
  raw: RawNews,
  tier: SourceTier,
  fallbackCategory?: NewsCategory | null,
): Promise<CuratedNews> {
  const title = cleanText(raw.title);
  const body = cleanText(raw.summary);
  const language = detectLanguage(`${title} ${body}`);
  const combined = `${title} ${body}`.toLowerCase();
  const keywordMatches = AI_SIGNALS.filter((signal) => signal.test(combined)).length;
  const relevance = keywordMatches && raw.is_ai_related === true
    ? 30
    : Math.min(30, keywordMatches * 10);
  const tierScore = tier === "official"
    ? 40
    : tier === "professional"
    ? 30
    : 20;
  const publishedAt = [raw.source_published_at, raw.fetched_at].find((value) =>
    value && Number.isFinite(Date.parse(value))
  ) ?? null;
  const ageHours = publishedAt
    ? (Date.now() - new Date(publishedAt).getTime()) / 3_600_000
    : Infinity;
  const freshness = ageHours >= 0 && ageHours <= 24
    ? 15
    : ageHours >= 0 && ageHours <= 72
    ? 10
    : ageHours >= 0 && ageHours <= 168
    ? 5
    : 0;
  const completeness = (title ? 4 : 0) + (body ? 4 : 0) + (raw.url ? 4 : 0) +
    (publishedAt ? 3 : 0);
  const quality = Math.max(
    0,
    Math.min(100, tierScore + relevance + freshness + completeness),
  );
  const summary = summarize(body || title, language);
  return {
    event_key: await eventKey(title, publishedAt),
    normalized_title: normalizeTitle(title),
    title,
    summary,
    language,
    category: classify(combined, fallbackCategory),
    source_tier: tier,
    quality_score: quality,
    importance_score: Math.min(
      100,
      Math.round(quality * 0.75 + Math.min(Number(raw.score ?? 0), 100) * 0.25),
    ),
    status: title && raw.url && keywordMatches > 0 && ageHours >= 0 && quality >= 65 ? "published" : "quarantined",
    published_at: publishedAt,
  };
}
