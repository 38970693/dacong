/**
 * Recommendation Service Unit Tests
 */

import {
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { RecommendationService } from "../_shared/services/RecommendationService.ts";
import { Content, ContentType, Scenario } from "../_shared/domain/Content.ts";
import { Recommendation } from "../_shared/domain/Recommendation.ts";
import { IContentRepository } from "../_shared/repositories/IContentRepository.ts";
import { IRecommendationRepository } from "../_shared/repositories/IRecommendationRepository.ts";

// Mock Content Repository
class MockContentRepository implements IContentRepository {
  private contents: Map<string, Content> = new Map();

  constructor() {
    // 添加测试数据 - 不同质量的内容
    const highQualityContent = new Content(
      "content-1",
      ContentType.RECOMMENDATION,
      "高质量内容",
      "高质量摘要",
      { test: "data" },
      "High Quality Content",
      "High Quality Summary",
      { test: "data" },
      Scenario.CODING,
      5000, // 高浏览量
      800, // 高有用数
      50, // 低无用数
      100, // 高分享数
      new Date(),
      new Date(),
      new Date()
    );

    const mediumQualityContent = new Content(
      "content-2",
      ContentType.RECOMMENDATION,
      "中等质量内容",
      "中等质量摘要",
      { test: "data" },
      "Medium Quality Content",
      "Medium Quality Summary",
      { test: "data" },
      Scenario.CODING,
      1000,
      200,
      100,
      20,
      new Date(),
      new Date(),
      new Date()
    );

    const lowQualityContent = new Content(
      "content-3",
      ContentType.RECOMMENDATION,
      "低质量内容",
      "低质量摘要",
      { test: "data" },
      "Low Quality Content",
      "Low Quality Summary",
      { test: "data" },
      Scenario.CODING,
      100,
      10,
      50,
      1,
      new Date(),
      new Date(),
      new Date()
    );

    this.contents.set("content-1", highQualityContent);
    this.contents.set("content-2", mediumQualityContent);
    this.contents.set("content-3", lowQualityContent);
  }

  async findById(id: string): Promise<Content | null> {
    return this.contents.get(id) || null;
  }

  async findByScenario(
    _scenario: Scenario,
    _limit?: number
  ): Promise<Content[]> {
    return Array.from(this.contents.values());
  }

  async search(
    _query: string,
    _language: "zh" | "en",
    _limit?: number,
    _offset?: number
  ): Promise<Content[]> {
    return [];
  }

  async findPopular(_limit?: number): Promise<Content[]> {
    return [];
  }

  async findRecent(_limit?: number): Promise<Content[]> {
    return [];
  }

  async incrementViewCount(_id: string): Promise<void> {}

  async incrementShareCount(_id: string): Promise<void> {}

  async count(): Promise<number> {
    return this.contents.size;
  }
}

// Mock Recommendation Repository
class MockRecommendationRepository implements IRecommendationRepository {
  private recommendations: Map<string, Recommendation> = new Map();

  constructor() {
    // 添加测试推荐配置
    const bestRec = new Recommendation(
      "rec-1",
      Scenario.CODING,
      1, // 最佳推荐
      "content-1",
      true,
      new Date(),
      new Date()
    );

    const altRec = new Recommendation(
      "rec-2",
      Scenario.CODING,
      2, // 平替推荐
      "content-2",
      true,
      new Date(),
      new Date()
    );

    const freeRec = new Recommendation(
      "rec-3",
      Scenario.CODING,
      3, // 免费推荐
      "content-3",
      true,
      new Date(),
      new Date()
    );

    this.recommendations.set("rec-1", bestRec);
    this.recommendations.set("rec-2", altRec);
    this.recommendations.set("rec-3", freeRec);
  }

  async findByScenario(scenario: string): Promise<Recommendation[]> {
    return Array.from(this.recommendations.values()).filter(
      (r) => r.scenario === scenario && r.active
    );
  }

  async findById(id: string): Promise<Recommendation | null> {
    return this.recommendations.get(id) || null;
  }

  async create(
    _recommendation: Omit<Recommendation, "id" | "createdAt" | "updatedAt">
  ): Promise<Recommendation> {
    throw new Error("Not implemented");
  }

  async update(
    _id: string,
    _data: Partial<Recommendation>
  ): Promise<Recommendation> {
    throw new Error("Not implemented");
  }

  async delete(_id: string): Promise<void> {
    throw new Error("Not implemented");
  }

  async findAllActive(): Promise<Recommendation[]> {
    return Array.from(this.recommendations.values()).filter((r) => r.active);
  }
}

Deno.test("RecommendationService - getRecommendationsWithContent should return sorted recommendations", async () => {
  const mockContentRepo = new MockContentRepository();
  const mockRecRepo = new MockRecommendationRepository();
  const service = new RecommendationService(mockRecRepo, mockContentRepo);

  const recommendations = await service.getRecommendationsWithContent(
    Scenario.CODING,
    10
  );

  assertExists(recommendations);
  assertEquals(recommendations.length, 3);

  // 验证排序：最佳推荐应该在第一位
  assertEquals(recommendations[0].id, "content-1");
  assertEquals(recommendations[0].titleZh, "高质量内容");
});

Deno.test("RecommendationService - getRecommendationsWithContent should respect limit", async () => {
  const mockContentRepo = new MockContentRepository();
  const mockRecRepo = new MockRecommendationRepository();
  const service = new RecommendationService(mockRecRepo, mockContentRepo);

  const recommendations = await service.getRecommendationsWithContent(
    Scenario.CODING,
    2
  );

  assertEquals(recommendations.length, 2);
});

Deno.test("RecommendationService - getRecommendationsWithContent should use cache", async () => {
  const mockContentRepo = new MockContentRepository();
  const mockRecRepo = new MockRecommendationRepository();
  const service = new RecommendationService(mockRecRepo, mockContentRepo);

  // 第一次调用
  const first = await service.getRecommendationsWithContent(
    Scenario.CODING,
    10
  );

  // 第二次调用应该从缓存获取
  const second = await service.getRecommendationsWithContent(
    Scenario.CODING,
    10
  );

  assertEquals(first.length, second.length);
  assertEquals(first[0].id, second[0].id);
});

Deno.test("RecommendationService - getRecommendationsWithContent should return empty array for non-existent scenario", async () => {
  const mockContentRepo = new MockContentRepository();
  const mockRecRepo = new MockRecommendationRepository();
  const service = new RecommendationService(mockRecRepo, mockContentRepo);

  const recommendations = await service.getRecommendationsWithContent(
    Scenario.VIDEO,
    10
  );

  assertEquals(recommendations.length, 0);
});

Deno.test("RecommendationService - getBestRecommendation should return best content", async () => {
  const mockContentRepo = new MockContentRepository();
  const mockRecRepo = new MockRecommendationRepository();
  const service = new RecommendationService(mockRecRepo, mockContentRepo);

  const best = await service.getBestRecommendation(Scenario.CODING);

  assertExists(best);
  assertEquals(best!.id, "content-1");
});

Deno.test("RecommendationService - getAlternativeRecommendations should return alternatives", async () => {
  const mockContentRepo = new MockContentRepository();
  const mockRecRepo = new MockRecommendationRepository();
  const service = new RecommendationService(mockRecRepo, mockContentRepo);

  const alternatives = await service.getAlternativeRecommendations(
    Scenario.CODING
  );

  assertEquals(alternatives.length, 1);
  assertEquals(alternatives[0].id, "content-2");
});

Deno.test("RecommendationService - getFreeRecommendations should return free options", async () => {
  const mockContentRepo = new MockContentRepository();
  const mockRecRepo = new MockRecommendationRepository();
  const service = new RecommendationService(mockRecRepo, mockContentRepo);

  const freeOptions = await service.getFreeRecommendations(Scenario.CODING);

  assertEquals(freeOptions.length, 1);
  assertEquals(freeOptions[0].id, "content-3");
});

Deno.test("RecommendationService - validateRecommendationIntegrity should detect missing best recommendation", async () => {
  const mockContentRepo = new MockContentRepository();
  const mockRecRepo = new MockRecommendationRepository();
  const service = new RecommendationService(mockRecRepo, mockContentRepo);

  const result = await service.validateRecommendationIntegrity(Scenario.VIDEO);

  assertEquals(result.valid, false);
  assertEquals(result.errors.length > 0, true);
});

Deno.test("RecommendationService - validateRecommendationIntegrity should pass for valid scenario", async () => {
  const mockContentRepo = new MockContentRepository();
  const mockRecRepo = new MockRecommendationRepository();
  const service = new RecommendationService(mockRecRepo, mockContentRepo);

  const result = await service.validateRecommendationIntegrity(
    Scenario.CODING
  );

  assertEquals(result.valid, true);
  assertEquals(result.errors.length, 0);
});
