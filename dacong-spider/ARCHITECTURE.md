# DaCong Spider - 面向对象架构设计

## 架构概述

本项目采用**面向对象设计**，严格遵循 **SOLID 原则**，实现了一个可扩展、可测试、易维护的爬虫系统。

## 核心设计原则

### 1. 单一职责原则 (SRP)

每个类只负责一个职责：

- `IHttpClient` - 只负责 HTTP 请求
- `IDataProcessor` - 只负责数据处理
- `IDataStorage` - 只负责数据存储
- `IDeduplicator` - 只负责去重
- `ISpider` - 只负责爬取逻辑

### 2. 开闭原则 (OCP)

对扩展开放，对修改关闭：

- 新增爬虫：继承 `BaseSpider` 或 `ApiSpider`，无需修改现有代码
- 新增存储：实现 `IDataStorage` 接口，无需修改爬虫代码
- 新增重试策略：实现 `IRetryStrategy` 接口

### 3. 里氏替换原则 (LSP)

子类可以替换父类：

- 所有爬虫都可以替换 `ISpider` 接口
- `InMemoryStorage` 和 `SupabaseStorage` 可以互换使用

### 4. 接口隔离原则 (ISP)

接口小而专注：

- `IHttpClient` - 只定义 HTTP 操作
- `IDataStorage` - 只定义存储操作
- `IDeduplicator` - 只定义去重操作

### 5. 依赖倒置原则 (DIP)

依赖抽象而非具体实现：

- 爬虫依赖 `IHttpClient` 接口，而非具体的 `HttpClient` 类
- 所有依赖通过构造函数注入

## 设计模式

### 1. 模板方法模式 (Template Method)

`BaseSpider.run()` 定义了爬虫执行的标准流程：

```python
async def run(self) -> SpiderResult:
    await self.on_start()          # 钩子
    raw_items = await self.fetch() # 抓取（子类实现）
    processed = process(raw_items)  # 处理
    unique = deduplicate(processed) # 去重
    save(unique)                    # 保存
    await self.on_end()            # 钩子
    return result
```

### 2. 策略模式 (Strategy)

不同的爬虫是不同的策略：

- `GitHubSpider` - GitHub 抓取策略
- `HuggingFaceSpider` - HuggingFace 抓取策略
- `RedditSpider` - Reddit 抓取策略

### 3. 工厂模式 (Factory)

`SpiderFactory` 负责创建和配置爬虫实例：

```python
factory = SpiderFactory()
spider = factory.create_github_spider()
```

### 4. 注册表模式 (Registry)

`SpiderRegistry` 管理所有可用的爬虫：

```python
registry = create_default_registry()
spider = registry.get("github")
```

### 5. 依赖注入 (Dependency Injection)

所有依赖通过构造函数注入：

```python
spider = GitHubSpider(
    http_client=http_client,
    data_processor=processor,
    storage=storage,
    deduplicator=deduplicator,
    logger=logger
)
```

## 类图设计

```
┌─────────────────────────────────────────────────────────┐
│                    核心接口层                              │
├─────────────────────────────────────────────────────────┤
│ IHttpClient      - HTTP 请求接口                         │
│ IDataProcessor   - 数据处理接口                          │
│ IDataStorage     - 数据存储接口                          │
│ IDeduplicator    - 去重接口                              │
│ IRetryStrategy   - 重试策略接口                          │
│ ISpider          - 爬虫接口                              │
│ IScheduler       - 调度器接口                            │
│ ILogger          - 日志接口                              │
└─────────────────────────────────────────────────────────┘
                          ▲
                          │ 实现
                          │
┌─────────────────────────────────────────────────────────┐
│                    实现层                                 │
├─────────────────────────────────────────────────────────┤
│ HttpClient              - httpx 实现                     │
│ BaseDataProcessor       - 数据处理基类                   │
│ SupabaseStorage         - Supabase 存储                 │
│ InMemoryStorage         - 内存存储（测试用）              │
│ ContentHashDeduplicator - 内容哈希去重                   │
│ ExponentialBackoffRetry - 指数退避重试                   │
│ SpiderLogger            - 日志记录器                     │
└─────────────────────────────────────────────────────────┘
                          ▲
                          │ 继承
                          │
┌─────────────────────────────────────────────────────────┐
│                    爬虫基类                               │
├─────────────────────────────────────────────────────────┤
│ BaseSpider    - 爬虫基类（模板方法）                      │
│ ApiSpider     - API 爬虫基类                             │
│ HtmlSpider    - HTML 爬虫基类                            │
└─────────────────────────────────────────────────────────┘
                          ▲
                          │ 继承
                          │
┌─────────────────────────────────────────────────────────┐
│                    具体爬虫                               │
├─────────────────────────────────────────────────────────┤
│ GitHubSpider       - GitHub 爬虫                         │
│ HuggingFaceSpider  - HuggingFace 爬虫                    │
│ OpenRouterSpider   - OpenRouter 爬虫                     │
│ RedditSpider       - Reddit 爬虫                         │
│ HackerNewsSpider   - Hacker News 爬虫                    │
└─────────────────────────────────────────────────────────┘
```

## 目录结构

```
dacong-spider/
├── core/                      # 核心模块
│   ├── interfaces.py          # 接口定义（DIP）
│   ├── implementations.py     # 基础实现
│   ├── spider_base.py         # 爬虫基类（模板方法）
│   ├── storage.py             # 存储实现
│   └── factory.py             # 工厂和注册表
│
├── spiders/                   # 具体爬虫
│   ├── github_spider.py       # GitHub 爬虫
│   ├── huggingface_spider.py  # HuggingFace 爬虫
│   ├── openrouter_spider.py   # OpenRouter 爬虫
│   ├── reddit_spider.py       # Reddit 爬虫
│   ├── hackernews_spider.py   # Hacker News 爬虫
│   └── processors.py          # 数据处理器注册表
│
├── schedulers/                # 调度器
│   └── scheduler.py           # APScheduler 实现
│
├── tests/                     # 单元测试
│   ├── test_core.py           # 核心组件测试
│   └── test_spiders.py        # 爬虫测试
│
├── config.py                  # 配置文件
├── main.py                    # 主入口
└── requirements.txt           # 依赖
```

## 数据流

```
┌──────────┐
│ 数据源    │ (GitHub, HuggingFace, etc.)
└────┬─────┘
     │
     ▼
┌──────────┐
│ ISpider  │ fetch() - 抓取原始数据
└────┬─────┘
     │
     ▼
┌──────────────┐
│ IDataProcessor│ process() - 清洗、转换
└────┬─────────┘
     │
     ▼
┌──────────────┐
│ IDeduplicator │ filter_duplicates() - 去重
└────┬─────────┘
     │
     ▼
┌──────────────┐
│ IDataStorage  │ save_batch() - 持久化
└──────────────┘
```

## 扩展指南

### 添加新爬虫

1. 创建爬虫类，继承 `ApiSpider` 或 `HtmlSpider`
2. 实现必需的属性和方法：
   - `name` - 爬虫名称
   - `source` - 数据源
   - `fetch()` - 抓取逻辑

3. 创建数据处理器，实现 `IDataProcessor`
4. 在 `processors.py` 中注册处理器
5. 在 `factory.py` 中添加工厂方法

示例：

```python
class NewSpider(ApiSpider):
    @property
    def name(self) -> str:
        return "New Spider"

    @property
    def source(self) -> MetricSource:
        return MetricSource.NEW_SOURCE

    @property
    def api_base_url(self) -> str:
        return "https://api.example.com"

    async def fetch(self) -> list[dict]:
        data = await self.fetch_json("endpoint")
        return data
```

### 添加新存储

实现 `IDataStorage` 接口：

```python
class RedisStorage(IDataStorage):
    async def save(self, data: RawData) -> bool:
        # 实现 Redis 存储逻辑
        pass

    async def save_batch(self, data_list: list[RawData]) -> int:
        pass

    async def exists(self, source: MetricSource, source_id: str) -> bool:
        pass

    async def get_content_hash(self, source: MetricSource, source_id: str) -> Optional[str]:
        pass
```

### 添加新重试策略

实现 `IRetryStrategy` 接口：

```python
class CustomRetry(IRetryStrategy):
    def should_retry(self, attempt: int, error: Exception) -> bool:
        # 自定义重试逻辑
        pass

    def get_delay(self, attempt: int) -> float:
        # 自定义延迟计算
        pass
```

## 测试策略

### 单元测试

- 使用 `InMemoryStorage` 进行测试
- Mock HTTP 客户端
- 测试每个组件的单一职责

### 集成测试

- 使用真实的 Supabase 测试环境
- 测试完整的数据流

### 运行测试

```bash
pytest tests/ -v --cov=core --cov=spiders
```

## 性能优化

1. **连接池复用** - `HttpClient` 复用连接
2. **批量写入** - `save_batch()` 减少数据库往返
3. **异步并发** - 使用 `asyncio` 并发执行
4. **内容哈希去重** - 避免重复处理相同数据

## 优势总结

### 可扩展性
- 新增爬虫无需修改现有代码
- 新增存储、重试策略等组件即插即用

### 可测试性
- 所有依赖都是接口，易于 Mock
- 提供内存存储用于测试

### 可维护性
- 职责清晰，每个类只做一件事
- 代码结构清晰，易于理解

### 可靠性
- 重试机制处理网络故障
- 去重机制避免重复数据
- 异常隔离，单个爬虫失败不影响其他

### 性能
- 异步并发提高吞吐量
- 连接池复用减少开销
- 批量操作提高效率
