/**
 * Cache Utility Unit Tests
 */

import {
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { Cache } from "../_shared/utils/cache.ts";

Deno.test("Cache - set and get should work correctly", () => {
  const cache = new Cache<string>();

  cache.set("key1", "value1", 60);
  const result = cache.get("key1");

  assertEquals(result, "value1");
});

Deno.test("Cache - get should return null for non-existent key", () => {
  const cache = new Cache<string>();

  const result = cache.get("non-existent");

  assertEquals(result, null);
});

Deno.test("Cache - get should return null for expired key", async () => {
  const cache = new Cache<string>();

  cache.set("key1", "value1", 1); // 1秒过期

  // 等待2秒
  await new Promise((resolve) => setTimeout(resolve, 2000));

  const result = cache.get("key1");

  assertEquals(result, null);
});

Deno.test("Cache - delete should remove key", () => {
  const cache = new Cache<string>();

  cache.set("key1", "value1", 60);
  cache.delete("key1");
  const result = cache.get("key1");

  assertEquals(result, null);
});

Deno.test("Cache - clear should remove all keys", () => {
  const cache = new Cache<string>();

  cache.set("key1", "value1", 60);
  cache.set("key2", "value2", 60);
  cache.clear();

  assertEquals(cache.size(), 0);
  assertEquals(cache.get("key1"), null);
  assertEquals(cache.get("key2"), null);
});

Deno.test("Cache - size should return correct count", () => {
  const cache = new Cache<string>();

  cache.set("key1", "value1", 60);
  cache.set("key2", "value2", 60);

  assertEquals(cache.size(), 2);
});

Deno.test("Cache - cleanup should remove expired entries", async () => {
  const cache = new Cache<string>();

  cache.set("key1", "value1", 1); // 1秒过期
  cache.set("key2", "value2", 60); // 60秒过期

  // 等待2秒
  await new Promise((resolve) => setTimeout(resolve, 2000));

  cache.cleanup();

  assertEquals(cache.size(), 1);
  assertEquals(cache.get("key1"), null);
  assertExists(cache.get("key2"));
});

Deno.test("Cache - should handle complex objects", () => {
  interface TestData {
    id: string;
    name: string;
    count: number;
  }

  const cache = new Cache<TestData>();
  const testData: TestData = { id: "1", name: "test", count: 100 };

  cache.set("key1", testData, 60);
  const result = cache.get("key1");

  assertExists(result);
  assertEquals(result!.id, "1");
  assertEquals(result!.name, "test");
  assertEquals(result!.count, 100);
});

Deno.test("Cache - should handle arrays", () => {
  const cache = new Cache<number[]>();
  const testArray = [1, 2, 3, 4, 5];

  cache.set("key1", testArray, 60);
  const result = cache.get("key1");

  assertExists(result);
  assertEquals(result!.length, 5);
  assertEquals(result![0], 1);
});
