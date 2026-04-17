# Redis 缓存实现文档

## 概述

本文档描述了 Dacong API 的 Redis 缓存实现，包括架构设计、使用方法、性能优化和监控策略。

## 架构设计

### 核心组件

```
_shared/
├── core/
│   ├── ICache.ts              # 缓存接口定义
│   ├── RedisCache.ts          # Redis 缓存实现
│   └── Container.ts           # DI 容器（集成缓存）
├── middleware/
│   └── cache.ts               # HTTP 缓存中间件
└── utils/
    └── cacheDecorator.ts      # 缓存装饰器
```

### 设计原则

1. **接口抽象**: 使用 `ICache` 接口，支持多种缓存实现
2. **依赖注入**: 通过 DI 容器管理缓存实例
3. **装饰器模式**: 提供 `@Cacheable` 和 `@CacheEvict` 装饰器
4. **中间件支持**: HTTP 层自动缓存响应
5. **失效策略**: TTL 过期 + LRU 淘汰 + 主动失效

## 快速开始

### 1. 环境配置

在 `.env` 文件中配置 Redis 连接：

```bash
# Redis 连接 URL
REDIS_URL=redis://:redis123@localhost:6379

# 或者分别配置
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=redis123
REDIS_DB=0

# 缓存默认 TTL（秒）
CACHE_TTL=300
```

### 2. 启动 Redis

使用 Docker Compose：

```bash
docker-compose up -d redis
```

验证连接：

```bash
redis-cli -h localhost -p 6379 -a redis123 ping
# 输出: PONG
```

### 3. 使用缓存

#### 方式一：通过 DI 容器

```typescript
import { Container } from "./_shared/core/Container.ts";

const container = Container.getInstance(supabase);
const cache = container.getCache();

// 设置缓存
await cache.set("user:123", { id: "123", name: "Alice" }, { ttl: 300 });

// 获取缓存
const user = await cache.get("user:123");

// 删除缓存
await cache.del("user:123");

// 批量删除
await cache.delPattern("user:*");
```

#### 方式二：使用装饰器

```typescript
import { Cacheable, CacheEvict } from "./_shared/utils/cacheDecorator.ts";

class UserService {
  constructor(private cache: ICache) {}

  @Cacheable(cache, { ttl: 300, prefix: "user" })
  async getUser(id: string) {
    // 自动缓存结果
    return await db.users.findById(id);
  }

  @CacheEvict(cache, "user:*")
  async updateUser(id: string, data: UpdateUserDto) {
    // 自动清除相关缓存
    return await db.users.update(id, data);
  }
}
```

#### 方式三：使用中间件

```typescript
import { createCacheMiddleware } from "./_shared/middleware/cache.ts";

const cacheMiddleware = createCacheMiddleware(cache, {
  ttl: 300,
  prefix: "http",
  shouldCache: (req, res) => {
    // 只缓存成功的 GET 请求
    return req.method === "GET" && res.status === 200;
  },
});

// 应用中间件
app.use(cacheMiddleware);
```

## 缓存策略

### TTL 配置

不同类型数据的推荐 TTL：

| 数据类型 | TTL | 说明 |
|---------|-----|------|
| 热门内容 | 300s (5分钟) | 高频访问，快速更新 |
| 用户信息 | 600s (10分钟) | 中频访问，较稳定 |
| 推荐列表 | 1800s (30分钟) | 计算密集，更新较慢 |
| 统计数据 | 3600s (1小时) | 低频更新，可长期缓存 |
| 配置信息 | 86400s (24小时) | 极少变化 |

### 缓存键命名规范

```
{prefix}:{resource}:{id}:{action}
```

示例：
- `user:123` - 用户信息
- `content:hot:50` - 热门内容（前50条）
- `recommendation:user:123` - 用户推荐
- `http:/api/v1/content/hot?limit=50` - HTTP 响应缓存

### 失效策略

#### 1. TTL 自动过期

```typescript
await cache.set("key", value, { ttl: 300 }); // 5分钟后自动过期
```

#### 2. LRU 淘汰

Redis 配置：

```bash
# redis.conf
maxmemory 256mb
maxmemory-policy allkeys-lru
```

#### 3. 主动失效

```typescript
// 数据更新时清除相关缓存
async updateContent(id: string, data: UpdateDto) {
  await db.contents.update(id, data);
  
  // 清除相关缓存
  await cache.del(`content:${id}`);
  await cache.delPattern("content:hot:*");
  await cache.delPattern("recommendation:*");
}
```

## 缓存预热

### 手动预热

```bash
# 运行预热脚本
./scripts/cache_warmup.sh
```

### 自动预热

在应用启动时自动预热：

```typescript
async function warmupCache(cache: ICache) {
  console.log("[Cache] Warming up...");
  
  // 预热热门内容
  const hotContents = await db.contents.findHot(50);
  await cache.set("content:hot:50", hotContents, { ttl: 300 });
  
  // 预热推荐列表
  const recommendations = await recommendationService.getTopRecommendations(20);
  await cache.set("recommendation:top:20", recommendations, { ttl: 1800 });
  
  console.log("[Cache] Warmup completed");
}
```

### 定时预热

使用 cron 定时预热：

```bash
# 每小时预热一次
0 * * * * /app/scripts/cache_warmup.sh
```

## 监控与调优

### 实时监控

```bash
# 运行监控脚本
./scripts/monitor_cache.sh
```

监控面板显示：
- 总键数
- 命中次数 / 未命中次数
- 命中率
- 内存使用
- 热键 Top 10

### 性能指标

#### 目标指标

- **命中率**: > 80%
- **响应时间**: < 10ms (P99)
- **内存使用**: < 80% 最大内存
- **键数量**: 根据业务需求

#### 查看统计

```bash
# 命中率
redis-cli INFO stats | grep keyspace

# 内存使用
redis-cli INFO memory | grep used_memory

# 键数量
redis-cli DBSIZE

# 慢查询
redis-cli SLOWLOG GET 10
```

### 性能优化

#### 1. 批量操作

```typescript
// 不推荐：逐个获取
for (const id of ids) {
  await cache.get(`user:${id}`);
}

// 推荐：批量获取
const keys = ids.map(id => `user:${id}`);
const users = await cache.mget(...keys);
```

#### 2. Pipeline

```typescript
// 使用 pipeline 减少网络往返
const pipeline = redis.pipeline();
pipeline.get("key1");
pipeline.get("key2");
pipeline.get("key3");
const results = await pipeline.exec();
```

#### 3. 压缩大对象

```typescript
import { compress, decompress } from "lz-string";

// 存储时压缩
const compressed = compress(JSON.stringify(largeObject));
await cache.set("large:key", compressed);

// 读取时解压
const compressed = await cache.get("large:key");
const largeObject = JSON.parse(decompress(compressed));
```

## 故障处理

### 连接失败

```typescript
try {
  await cache.connect();
} catch (error) {
  console.error("Redis connection failed:", error);
  // 降级到无缓存模式
  cache = null;
}
```

### 缓存穿透

使用空值缓存：

```typescript
async function getUser(id: string) {
  const cached = await cache.get(`user:${id}`);
  if (cached !== null) {
    return cached === "NULL" ? null : cached;
  }
  
  const user = await db.users.findById(id);
  
  if (user === null) {
    // 缓存空值，防止穿透
    await cache.set(`user:${id}`, "NULL", { ttl: 60 });
    return null;
  }
  
  await cache.set(`user:${id}`, user, { ttl: 300 });
  return user;
}
```

### 缓存雪崩

使用随机 TTL：

```typescript
const baseTTL = 300;
const randomTTL = baseTTL + Math.floor(Math.random() * 60);
await cache.set(key, value, { ttl: randomTTL });
```

### 缓存击穿

使用互斥锁：

```typescript
async function getHotContent(id: string) {
  const lockKey = `lock:content:${id}`;
  
  // 尝试获取锁
  const locked = await cache.set(lockKey, "1", { ttl: 10, nx: true });
  
  if (locked) {
    try {
      // 重新加载数据
      const content = await db.contents.findById(id);
      await cache.set(`content:${id}`, content, { ttl: 300 });
      return content;
    } finally {
      await cache.del(lockKey);
    }
  } else {
    // 等待锁释放后重试
    await new Promise(resolve => setTimeout(resolve, 100));
    return await getHotContent(id);
  }
}
```

## 最佳实践

### 1. 合理设置 TTL

- 根据数据更新频率设置 TTL
- 避免永久缓存（除非确实不变）
- 使用随机 TTL 防止雪崩

### 2. 缓存粒度

- 缓存计算结果，而非原始数据
- 避免缓存过大的对象
- 考虑分片存储大对象

### 3. 缓存更新

- 优先使用 TTL 自动过期
- 数据更新时主动失效
- 避免频繁更新缓存

### 4. 监控告警

- 监控命中率，低于 80% 时告警
- 监控内存使用，超过 80% 时告警
- 监控慢查询，及时优化

### 5. 降级方案

- 缓存不可用时降级到数据库
- 关键业务使用本地缓存兜底
- 设置合理的超时时间

## 常见问题

### Q: 如何清空所有缓存？

```bash
redis-cli FLUSHDB
```

或通过代码：

```typescript
await cache.flush();
```

### Q: 如何查看某个键的值？

```bash
redis-cli GET "key"
```

### Q: 如何查看键的过期时间？

```bash
redis-cli TTL "key"
```

### Q: 如何导出/导入缓存数据？

```bash
# 导出
redis-cli --rdb dump.rdb

# 导入
redis-cli --rdb dump.rdb --pipe
```

## 参考资料

- [Redis 官方文档](https://redis.io/documentation)
- [Redis 最佳实践](https://redis.io/topics/best-practices)
- [Deno Redis 客户端](https://deno.land/x/redis)
- [缓存设计模式](https://docs.microsoft.com/en-us/azure/architecture/patterns/cache-aside)

## 更新日志

- **2024-04-17**: 初始版本，实现 Redis 缓存基础功能
