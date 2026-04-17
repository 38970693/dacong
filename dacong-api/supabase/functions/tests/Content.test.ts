/**
 * Content Domain Entity Unit Tests
 */

import { assertEquals } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { Content, ContentType, Scenario } from "../_shared/domain/Content.ts";

Deno.test("Content - incrementViewCount should increase view count by 1", () => {
  const content = new Content(
    "test-id",
    ContentType.RECOMMENDATION,
    "测试标题",
    "测试摘要",
    { test: "data" },
    "Test Title",
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

  const updated = content.incrementViewCount();

  assertEquals(updated.viewCount, 101);
  assertEquals(content.viewCount, 100); // 原对象不变（不可变性）
});

Deno.test("Content - incrementShareCount should increase share count by 1", () => {
  const content = new Content(
    "test-id",
    ContentType.RECOMMENDATION,
    "测试标题",
    "测试摘要",
    { test: "data" },
    "Test Title",
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

  const updated = content.incrementShareCount();

  assertEquals(updated.shareCount, 6);
  assertEquals(content.shareCount, 5); // 原对象不变
});

Deno.test("Content - helpfulRate should calculate correctly", () => {
  const content = new Content(
    "test-id",
    ContentType.RECOMMENDATION,
    "测试标题",
    "测试摘要",
    { test: "data" },
    "Test Title",
    "Test Summary",
    { test: "data" },
    Scenario.CODING,
    100,
    80, // helpful
    20, // unhelpful
    5,
    new Date(),
    new Date(),
    new Date()
  );

  assertEquals(content.helpfulRate, 0.8);
});

Deno.test("Content - helpfulRate should return null when no feedback", () => {
  const content = new Content(
    "test-id",
    ContentType.RECOMMENDATION,
    "测试标题",
    "测试摘要",
    { test: "data" },
    "Test Title",
    "Test Summary",
    { test: "data" },
    Scenario.CODING,
    100,
    0, // helpful
    0, // unhelpful
    5,
    new Date(),
    new Date(),
    new Date()
  );

  assertEquals(content.helpfulRate, null);
});

Deno.test("Content - isPopular should return true for high view count", () => {
  const content = new Content(
    "test-id",
    ContentType.RECOMMENDATION,
    "测试标题",
    "测试摘要",
    { test: "data" },
    "Test Title",
    "Test Summary",
    { test: "data" },
    Scenario.CODING,
    1500, // > 1000
    50,
    10,
    5,
    new Date(),
    new Date(),
    new Date()
  );

  assertEquals(content.isPopular(), true);
});

Deno.test("Content - isPopular should return true for high helpful count", () => {
  const content = new Content(
    "test-id",
    ContentType.RECOMMENDATION,
    "测试标题",
    "测试摘要",
    { test: "data" },
    "Test Title",
    "Test Summary",
    { test: "data" },
    Scenario.CODING,
    500,
    150, // > 100
    10,
    5,
    new Date(),
    new Date(),
    new Date()
  );

  assertEquals(content.isPopular(), true);
});

Deno.test("Content - isPopular should return false for low counts", () => {
  const content = new Content(
    "test-id",
    ContentType.RECOMMENDATION,
    "测试标题",
    "测试摘要",
    { test: "data" },
    "Test Title",
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

  assertEquals(content.isPopular(), false);
});

Deno.test("Content - toJSON should return correct structure", () => {
  const now = new Date();
  const content = new Content(
    "test-id",
    ContentType.RECOMMENDATION,
    "测试标题",
    "测试摘要",
    { test: "data" },
    "Test Title",
    "Test Summary",
    { test: "data" },
    Scenario.CODING,
    100,
    50,
    10,
    5,
    now,
    now,
    now
  );

  const json = content.toJSON();

  assertEquals(json.id, "test-id");
  assertEquals(json.content_type, ContentType.RECOMMENDATION);
  assertEquals(json.title_zh, "测试标题");
  assertEquals(json.helpful_rate, 50 / 60);
});
