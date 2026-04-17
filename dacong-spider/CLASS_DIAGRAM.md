# 类图设计文档

## 核心接口层 (Interfaces)

### 数据传输对象 (DTOs)

```python
@dataclass(frozen=True)
class RawData:
    """不可变的原始数据对象"""
    source: MetricSource
    data_type: DataType
    source_id: str
    title: str
    description: str
    url: str
    metadata: dict
    raw_content: str
    content_hash: str
    fetched_at: datetime

@dataclass(frozen=True)
class SpiderResult:
    """爬虫执行结果"""
    spider_name: str
    success: bool
    items_fetched: int
    items_written: int
    errors: list[str]
    duration_seconds: float
```

### 核心接口

```
┌─────────────────────────────────────────────────────────────┐
│                      IHttpClient                             │
├─────────────────────────────────────────────────────────────┤
│ + get(url, headers) -> str                                   │
│ + get_json(url, headers) -> dict                             │
│ + close()                                                    │
└─────────────────────────────────────────────────────────────┘
                          ▲
                          │ 实现
                          │
┌─────────────────────────────────────────────────────────────┐
│                      HttpClient                              │
├─────────────────────────────────────────────────────────────┤
│ - _client: AsyncClient                                       │
│ - timeout: int                                               │
│ - retry_strategy: IRetryStrategy                             │
├─────────────────────────────────────────────────────────────┤
│ + get(url, headers) -> str                                   │
│ + get_json(url, headers) -> dict                             │
│ + close()                                                    │
└─────────────────────────────────────────────────────────────┘
```

```
┌─────────────────────────────────────────────────────────────┐
│                    IDataProcessor                            │
├─────────────────────────────────────────────────────────────┤
│ + process(raw_data) -> RawData                               │
│ + generate_content_hash(data) -> str                         │
└─────────────────────────────────────────────────────────────┘
                          ▲
                          │ 实现
                          │
┌─────────────────────────────────────────────────────────────┐
│                  BaseDataProcessor                           │
├─────────────────────────────────────────────────────────────┤
│ - source: MetricSource                                       │
│ - data_type: DataType                                        │
├─────────────────────────────────────────────────────────────┤
│ + process(raw_data) -> RawData                               │
│ + generate_content_hash(data) -> str                         │
│ # _extract_source_id(data) -> str                            │
│ # _extract_title(data) -> str                                │
│ # _extract_description(data) -> str                          │
│ # _extract_url(data) -> str                                  │
│ # _extract_metadata(data) -> dict                            │
└─────────────────────────────────────────────────────────────┘
                          ▲
                          │ 继承
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│ GitHub        │ │ HuggingFace   │ │ OpenRouter    │
│ DataProcessor │ │ DataProcessor │ │ DataProcessor │
└───────────────┘ └───────────────┘ └───────────────┘
```

```
┌─────────────────────────────────────────────────────────────┐
│                     IDataStorage                             │
├─────────────────────────────────────────────────────────────┤
│ + save(data) -> bool                                         │
│ + save_batch(data_list) -> int                               │
│ + exists(source, source_id) -> bool                          │
│ + get_content_hash(source, source_id) -> str                 │
└─────────────────────────────────────────────────────────────┘
                          ▲
                          │ 实现
                          │
        ┌─────────────────┼─────────────────┐
        │                                   │
┌───────────────────┐            ┌──────────────────┐
│ SupabaseStorage   │            │ InMemoryStorage  │
├───────────────────┤            ├──────────────────┤
│ - client: Client  │            │ - data: dict     │
│ - table_name: str │            ├──────────────────┤
├───────────────────┤            │ + clear()        │
│ + save()          │            │ + count()        │
│ + save_batch()    │            └──────────────────┘
│ + exists()        │
│ + get_content_hash()│
└───────────────────┘
```

## 爬虫层次结构

```
┌─────────────────────────────────────────────────────────────┐
│                        ISpider                               │
├─────────────────────────────────────────────────────────────┤
│ + name: str                                                  │
│ + source: MetricSource                                       │
│ + fetch() -> list[dict]                                      │
│ + run() -> SpiderResult                                      │
└─────────────────────────────────────────────────────────────┘
                          ▲
                          │ 实现
                          │
┌─────────────────────────────────────────────────────────────┐
│                      BaseSpider                              │
│                   (模板方法模式)                              │
├─────────────────────────────────────────────────────────────┤
│ - http_client: IHttpClient                                   │
│ - data_processor: IDataProcessor                             │
│ - storage: IDataStorage                                      │
│ - deduplicator: IDeduplicator                                │
│ - logger: ILogger                                            │
├─────────────────────────────────────────────────────────────┤
│ + run() -> SpiderResult          [模板方法]                  │
│ # fetch() -> list[dict]          [抽象方法]                  │
│ # on_start()                     [钩子]                      │
│ # on_end(result)                 [钩子]                      │
│ # on_error(error)                [钩子]                      │
└─────────────────────────────────────────────────────────────┘
                          ▲
                          │ 继承
                          │
        ┌─────────────────┼─────────────────┐
        │                                   │
┌───────────────────┐            ┌──────────────────┐
│    ApiSpider      │            │   HtmlSpider     │
├───────────────────┤            ├──────────────────┤
│ + api_base_url    │            │ + fetch_html()   │
│ + get_headers()   │            └──────────────────┘
│ + fetch_json()    │
└───────────────────┘
        ▲
        │ 继承
        │
┌───────┴────────────────────────────────────────┐
│                                                 │
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ GitHub       │  │ HuggingFace  │  │ OpenRouter   │
│ Spider       │  │ Spider       │  │ Spider       │
├──────────────┤  ├──────────────┤  ├──────────────┤
│ + name       │  │ + name       │  │ + name       │
│ + source     │  │ + source     │  │ + source     │
│ + fetch()    │  │ + fetch()    │  │ + fetch()    │
└──────────────┘  └──────────────┘  └──────────────┘

┌──────────────┐  ┌──────────────┐
│ Reddit       │  │ HackerNews   │
│ Spider       │  │ Spider       │
├──────────────┤  ├──────────────┤
│ + name       │  │ + name       │
│ + source     │  │ + source     │
│ + fetch()    │  │ + fetch()    │
└──────────────┘  └──────────────┘
```

## 工厂和注册表

```
┌─────────────────────────────────────────────────────────────┐
│                     SpiderFactory                            │
│                    (工厂模式)                                 │
├─────────────────────────────────────────────────────────────┤
│ - http_client: IHttpClient                                   │
│ - storage: IDataStorage                                      │
│ - deduplicator: IDeduplicator                                │
├─────────────────────────────────────────────────────────────┤
│ + create_spider(spider_class, **kwargs) -> ISpider           │
│ + create_github_spider() -> GitHubSpider                     │
│ + create_huggingface_spider() -> HuggingFaceSpider           │
│ + create_openrouter_spider() -> OpenRouterSpider             │
│ + create_reddit_spider() -> RedditSpider                     │
│ + create_hackernews_spider() -> HackerNewsSpider             │
│ + cleanup()                                                  │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ 使用
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    SpiderRegistry                            │
│                   (注册表模式)                                │
├─────────────────────────────────────────────────────────────┤
│ - factory: SpiderFactory                                     │
│ - _registry: dict[str, tuple[type, dict]]                    │
├─────────────────────────────────────────────────────────────┤
│ + register(name, spider_class, config)                       │
│ + get(name) -> ISpider                                       │
│ + get_all() -> list[ISpider]                                 │
│ + list_names() -> list[str]                                  │
└─────────────────────────────────────────────────────────────┘
```

## 调度器

```
┌─────────────────────────────────────────────────────────────┐
│                      IScheduler                              │
├─────────────────────────────────────────────────────────────┤
│ + register_spider(spider, interval_hours)                    │
│ + start()                                                    │
│ + stop()                                                     │
└─────────────────────────────────────────────────────────────┘
                          ▲
                          │ 实现
                          │
┌─────────────────────────────────────────────────────────────┐
│                   SpiderScheduler                            │
├─────────────────────────────────────────────────────────────┤
│ - registry: SpiderRegistry                                   │
│ - scheduler: AsyncIOScheduler                                │
├─────────────────────────────────────────────────────────────┤
│ + register_spider(spider, interval_hours)                    │
│ + register_spider_by_name(name, interval_hours)              │
│ + start()                                                    │
│ + stop()                                                     │
│ + run_now(spider_name)                                       │
│ + list_jobs() -> list[dict]                                  │
└─────────────────────────────────────────────────────────────┘
```

## 辅助组件

```
┌─────────────────────────────────────────────────────────────┐
│                    IDeduplicator                             │
├─────────────────────────────────────────────────────────────┤
│ + filter_duplicates(data_list, storage) -> list[RawData]    │
└─────────────────────────────────────────────────────────────┘
                          ▲
                          │ 实现
                          │
┌─────────────────────────────────────────────────────────────┐
│              ContentHashDeduplicator                         │
├─────────────────────────────────────────────────────────────┤
│ + filter_duplicates(data_list, storage) -> list[RawData]    │
└─────────────────────────────────────────────────────────────┘
```

```
┌─────────────────────────────────────────────────────────────┐
│                   IRetryStrategy                             │
├─────────────────────────────────────────────────────────────┤
│ + should_retry(attempt, error) -> bool                       │
│ + get_delay(attempt) -> float                                │
└─────────────────────────────────────────────────────────────┘
                          ▲
                          │ 实现
                          │
        ┌─────────────────┼─────────────────┐
        │                                   │
┌───────────────────────┐      ┌──────────────────┐
│ ExponentialBackoff    │      │ FixedDelayRetry  │
│ Retry                 │      │                  │
├───────────────────────┤      ├──────────────────┤
│ - max_retries: int    │      │ - max_retries    │
│ - base_delay: float   │      │ - delay: float   │
├───────────────────────┤      ├──────────────────┤
│ + should_retry()      │      │ + should_retry() │
│ + get_delay()         │      │ + get_delay()    │
│   (指数增长)           │      │   (固定值)        │
└───────────────────────┘      └──────────────────┘
```

## 依赖关系图

```
┌──────────────┐
│    main.py   │
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│ SpiderScheduler  │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ SpiderRegistry   │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ SpiderFactory    │
└──────┬───────────┘
       │
       ├─────────────────────────────────┐
       │                                 │
       ▼                                 ▼
┌──────────────┐              ┌──────────────────┐
│  ISpider     │◄─────────────│ IHttpClient      │
│  实现类       │              │ IDataProcessor   │
│              │              │ IDataStorage     │
│              │              │ IDeduplicator    │
│              │              │ ILogger          │
└──────────────┘              └──────────────────┘
```

## SOLID 原则体现

### 单一职责原则 (SRP)
- `HttpClient` - 只负责 HTTP 请求
- `DataProcessor` - 只负责数据处理
- `Storage` - 只负责数据存储
- `Deduplicator` - 只负责去重

### 开闭原则 (OCP)
- 新增爬虫：继承 `BaseSpider`，无需修改现有代码
- 新增存储：实现 `IDataStorage`，无需修改爬虫

### 里氏替换原则 (LSP)
- 所有 `ISpider` 实现都可以互换
- `InMemoryStorage` 和 `SupabaseStorage` 可以互换

### 接口隔离原则 (ISP)
- 接口小而专注，每个接口只定义必要的方法

### 依赖倒置原则 (DIP)
- 高层模块（爬虫）依赖抽象（接口）
- 低层模块（具体实现）也依赖抽象
- 通过依赖注入实现松耦合
