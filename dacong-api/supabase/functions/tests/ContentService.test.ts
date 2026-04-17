/**
 * Content Service Unit Tests
 */

import { assertEquals, assertExists } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { ContentService } from "../_shared/services/ContentService.ts";
import { Content, ContentType, Scenario } from "../_shared/domain/Content.ts";
import { IContentRepository } from "../_shared/repositories/IContentRepository.ts";

// Mock Repository
class MockContentRepository implements IContentRepository {
  private contents: Map<string, Content> = new Map();

  constructor() {
    // 添加测试数据
    const testContent = new Content(
      "test-id-1",
      ContentType.RECOMMENDATION,
      "测试内容",
      "测试摘要",
      { test: "data" },
      "Test Content",
      "Test Summary",
      { test: "data" },
      Scenario.CODING,
      100,
      50,
      10,
      5,
      new Date(),
      new Date(),
      new Date()
    );
    this.contents.set("test-id-1", testContent);
  }

  async findById(id: string): Promise<Content | null> {
    return this.contents.get(id) || null;
  }

  async findByScenario(scenario: Scenario, limit?: number): Promise<Content[]> {
    return Array.from(this.contents.values())
      .filter((c) => c.scenario === scenario)
      .slice(0, limit);
  }

  async search(
    query: string,
    language: "zh" | "en",
    limit?: number,
    offset?: number
  ): Promise<Content[]> {
    return Array.from(this.contents.values()).slice(offset, offset! + limit!);
  }

  async findPopular(limit?: number): Promise<Content[]> {
    return Array.from(this.contents.values())
      .sort((a, b) => b.helpfulCount - a.helpfulCount)
      .slice(0, limit);
  }

  async findRecent(limit?: number): Promise<Content[]> {
    return Array.from(this.contents.values())
      .sort((a, b) => b.publishedAt.getTime() - a.publishedAt.getTime())
      .slice(0, limit);
  }

  async incrementViewCount(id: string): Promise<void> {
    const content = this.contents.get(id);
    if (content) {
      const updated = content.incrementViewCount();
      this.contents.set(id, updated);
    }
  }

  async incrementShareCount(id: string): Promise<void> {
    const content = this.contents.get(id);
    if (content) {
      const updated = content.incrementShareCount();
      this.contents.set(id, updated);
    }
  }

  async count(): Promise<number> {
    return this.contents.size;
  }
}

Deno.test("ContentService - getContentDetail should return content", async () => {
  const mockRepo = new MockContentRepository();
  const service = new ContentService(mockRepo);

  const content = await service.getContentDetail("test-id-1", false);

  assertExists(content);
  assertEquals(content!.id, "test-id-1");
  assertEquals(content!.titleZh, "测试内容");
});

Deno.test("ContentService - getContentDetail should increment view count", async () => {
  const mockRepo = new MockContentRepository();
  const service = new ContentService(mockRepo);

  const before = await service.getContentDetail("test-id-1", false);
  const initialViewCount = before!.viewCount;

  await service.getContentDetail("test-id-1", true);
  const after = await service.getContentDetail("test-id-1", false);

  assertEquals(after!.viewCount, initialViewCount + 1);
});

Deno.test("ContentService - getContentDetail should return null for non-existent content", async () => {
  const mockRepo = new MockContentRepository();
  const service = new ContentService(mockRepo);

  const content = await service.getContentDetail("non-existent-id");

  assertEquals(content, null);
});

Deno.test("ContentService - getRecommendationsByScenario should return content list", async () => {
  const mockRepo = new MockContentRepository();
  const service = new ContentService(mockRepo);

  const recommendations = await service.getRecommendationsByScenario(Scenario.CODING);

  assertExists(recommendations);
  assertEquals(recommendations.length > 0, true);
});

Deno.test("ContentService - searchContent should return search results", async () => {
  const mockRepo = new MockContentRepository();
  const service = new ContentService(mockRepo);

  const { items, total } = await service.searchContent("测试", "zh", 20, 0);

  assertExists(items);
  assertEquals(total, 1);
});

Deno.test("ContentService - validateContentExists should return true for existing content", async () => {
  const mockRepo = new MockContentRepository();
  const service = new ContentService(mockRepo);

  const exists = await service.validateContentExists("test-id-1");

  assertEquals(exists, true);
});

Deno.test("ContentService - validateContentExists should return false for non-existent content", async () => {
  const mockRepo = new MockContentRepository();
  const service = new ContentService(mockRepo);

  const exists = await service.validateContentExists("non-existent-id");

  assertEquals(exists, false);
});
