import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { type DigestCandidate, selectDigestItems } from "./digest_rules.ts";

Deno.test("digest selection caps each category and is deterministic", () => {
  const items: DigestCandidate[] = [
    ...[100, 99, 98, 97].map((score, index) => ({
      id: `model-${index}`,
      category: "model" as const,
      importance_score: score,
      quality_score: score,
      published_at: `2026-09-21T0${index}:00:00Z`,
    })),
    {
      id: "research",
      category: "research",
      importance_score: 80,
      quality_score: 90,
      published_at: "2026-09-21T10:00:00Z",
    },
  ];
  assertEquals(selectDigestItems(items).map((item) => item.id), [
    "model-0",
    "model-1",
    "model-2",
    "research",
  ]);
});
