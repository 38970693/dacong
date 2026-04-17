/**
 * Redis Cache Tests
 * Redis 缓存测试
 */

import { assertEquals, assertExists } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { RedisCache, RedisCacheConfig } from "../_shared/core/RedisCache.ts";

// 测试配置
const testConfig: RedisCacheConfig = {
  hostname: Deno.env.get("REDIS_HOST") || "localhost",
  port: parseInt(Deno.env.get("REDIS_PORT") || "6379"),
  password: Deno.env.get("REDIS_PASSWORD"),
  db: 1, // 使用测试数据库
};

Deno.test("RedisCache - Basic Operations", async () => {
  const cache = new RedisCache(testConfig);
  await cache.connect();

  try {
    // 测试 set/get
    await cache.set("test:key1", { value: "hello" });
    const result = await cache.get("test:key1");
    assertEquals(result, { value: "hello" });

    // 测试 TTL
    await cache.set("test:key2", { value: "world" }, { ttl: 2 });
    const ttl = await cache.ttl("test:key2");
    assertEquals(ttl > 0 && ttl <= 2, true);

    // 测试 exists
    const exists = await cache.exists("test:key1");
    assertEquals(exists, true);

    // 测试 del
    await cache.del("test:key1");
    const deleted = await cache.get("test:key1");
    assertEquals(deleted, null);

    // 清理
    await cache.flush();
  } finally {
    await cache.close();
  }
});

Deno.test("RedisCache - Pattern Deletion", async () => {
  const cache = new RedisCache(testConfig);
  await cache.connect();

  try {
    // 创建多个键
    await cache.set("user:1", { name: "Alice" });
    await cache.set("user:2", { name: "Bob" });
    await cache.set("product:1", { name: "Product" });

    // 删除 user:* 模式的键
    const count = await cache.delPattern("user:*");
    assertEquals(count, 2);

    // 验证删除
    const user1 = await cache.get("user:1");
    const product1 = await cache.get("product:1");
    assertEquals(user1, null);
    assertExists(product1);

    // 清理
    await cache.flush();
  } finally {
    await cache.close();
  }
});

Deno.test("RedisCache - Statistics", async () => {
  const cache = new RedisCache(testConfig);
  await cache.connect();

  try {
    // 清空数据库
    await cache.flush();

    // 添加一些数据
    await cache.set("stat:1", { value: 1 });
    await cache.set("stat:2", { value: 2 });

    // 触发命中和未命中
    await cache.get("stat:1"); // hit
    await cache.get("stat:999"); // miss

    // 获取统计
    const stats = await cache.getStats();
    assertExists(stats);
    assertEquals(stats.keys >= 2, true);
    assertExists(stats.hitRate);

    // 清理
    await cache.flush();
  } finally {
    await cache.close();
  }
});

Deno.test("RedisCache - Error Handling", async () => {
  const cache = new RedisCache(testConfig);

  // 测试未连接时的错误
  try {
    await cache.get("test");
    throw new Error("Should have thrown error");
  } catch (error) {
    assertEquals(error.message.includes("not connected"), true);
  }

  // 连接后正常工作
  await cache.connect();
  await cache.set("test", { value: "ok" });
  const result = await cache.get("test");
  assertEquals(result, { value: "ok" });

  await cache.close();
});
