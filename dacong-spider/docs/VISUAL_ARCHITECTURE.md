# DaCong Spider - 架构可视化文档

> 使用 Mermaid 图表展示爬虫模块的架构设计

---

## 1. 类图 - 接口与实现层次

```mermaid
classDiagram
    %% 接口层
    class ISpider {
        <<interface>>
        +name: str
        +source: MetricSource
        +run() SpiderResult
        +on_start() void
        +on_end() void
    }
    
    class IHttpClient {
        <<interface>>
        +get(url, headers) Response
        +post(url, data, headers) Response
    }
    
    class IDataProcessor {
        <<interface>>
        +process(raw_data) ProcessedData
        +validate(data) bool
    }
    
    class IDataStorage {
        <<interface>>
        +save(data) bool
        +save_batch(data_list) int
        +exists(source, source_id) bool
    }
    
    class IDeduplicator {
        <<interface>>
        +filter_duplicates(items) list
        +is_duplicate(item) bool
    }
    
    class IRetryStrategy {
        <<interface>>
        +should_retry(attempt, error) bool
        +get_delay(attempt) float
    }
    
    class IScheduler {
        <<interface>>
        +add_job(spider, cron) void
        +start() void
        +stop() void
    }
    
    class ILogger {
        <<interface>>
        +info(msg) void
        +error(msg) void
        +warning(msg) void
    }
    
    %% 基类层
    class BaseSpider {
        <<abstract>>
        #http_client: IHttpClient
        #processor: IDataProcessor
        #storage: IDataStorage
        #deduplicator: IDeduplicator
        #logger: ILogger
        +run() SpiderResult
        #fetch() list~dict~
        #on_start() void
        #on_end() void
    }
    
    class ApiSpider {
        <<abstract>>
        #api_base_url: str
        #fetch_json(endpoint) dict
        #fetch_paginated(endpoint) list
    }
    
    class HtmlSpider {
        <<abstract>>
        #parse_html(html) BeautifulSoup
        #extract_data(soup) list
    }
    
    %% 具体实现层
    class GitHubSpider {
        +name: "GitHub Trending"
        +source: GITHUB
        +fetch() list~dict~
    }
    
    class HuggingFaceSpider {
        +name: "HuggingFace Models"
        +source: HUGGINGFACE
        +fetch() list~dict~
    }
    
    class OpenRouterSpider {
        +name: "OpenRouter Models"
        +source: OPENROUTER
        +fetch() list~dict~
    }
    
    class RedditSpider {
        +name: "Reddit AI"
        +source: REDDIT
        +fetch() list~dict~
    }
    
    class HackerNewsSpider {
        +name: "Hacker News"
        +source: HACKERNEWS
        +fetch() list~dict~
    }
    
    %% 实现类
    class HttpClient {
        -session: httpx.AsyncClient
        +get(url, headers) Response
        +post(url, data, headers) Response
    }
    
    class SupabaseStorage {
        -client: SupabaseClient
        +save(data) bool
        +save_batch(data_list) int
        +exists(source, source_id) bool
    }
    
    class ContentHashDeduplicator {
        -storage: IDataStorage
        +filter_duplicates(items) list
        +is_duplicate(item) bool
    }
    
    class ExponentialBackoffRetry {
        -max_attempts: int
        -base_delay: float
        +should_retry(attempt, error) bool
        +get_delay(attempt) float
    }
    
    class SpiderScheduler {
        -scheduler: APScheduler
        -registry: SpiderRegistry
        +add_job(spider, cron) void
        +start() void
        +stop() void
    }
    
    %% 工厂和注册表
    class SpiderFactory {
        +create_github_spider() GitHubSpider
        +create_huggingface_spider() HuggingFaceSpider
        +create_openrouter_spider() OpenRouterSpider
        +create_reddit_spider() RedditSpider
        +create_hackernews_spider() HackerNewsSpider
    }
    
    class SpiderRegistry {
        -spiders: dict
        +register(name, spider) void
        +get(name) ISpider
        +list_all() list
    }
    
    %% 关系
    ISpider <|.. BaseSpider
    BaseSpider <|-- ApiSpider
    BaseSpider <|-- HtmlSpider
    ApiSpider <|-- GitHubSpider
    ApiSpider <|-- HuggingFaceSpider
    ApiSpider <|-- OpenRouterSpider
    ApiSpider <|-- RedditSpider
    HtmlSpider <|-- HackerNewsSpider
    
    IHttpClient <|.. HttpClient
    IDataStorage <|.. SupabaseStorage
    IDeduplicator <|.. ContentHashDeduplicator
    IRetryStrategy <|.. ExponentialBackoffRetry
    IScheduler <|.. SpiderScheduler
    
    BaseSpider --> IHttpClient
    BaseSpider --> IDataProcessor
    BaseSpider --> IDataStorage
    BaseSpider --> IDeduplicator
    BaseSpider --> ILogger
    
    SpiderFactory ..> GitHubSpider : creates
    SpiderFactory ..> HuggingFaceSpider : creates
    SpiderFactory ..> OpenRouterSpider : creates
    SpiderFactory ..> RedditSpider : creates
    SpiderFactory ..> HackerNewsSpider : creates
    
    SpiderRegistry o-- ISpider
    SpiderScheduler --> SpiderRegistry
```

---

## 2. 数据流图 - 从采集到存储

```mermaid
flowchart TB
    %% 数据源
    subgraph DataSources["数据源"]
        GitHub["GitHub API<br/>trending repos"]
        HuggingFace["HuggingFace API<br/>models"]
        OpenRouter["OpenRouter API<br/>models"]
        Reddit["Reddit API<br/>r/artificial"]
        HackerNews["Hacker News API<br/>AI posts"]
    end
    
    %% 爬虫层
    subgraph SpiderLayer["爬虫层 (ISpider)"]
        GS["GitHubSpider"]
        HFS["HuggingFaceSpider"]
        ORS["OpenRouterSpider"]
        RS["RedditSpider"]
        HNS["HackerNewsSpider"]
    end
    
    %% HTTP客户端
    HttpClient["HTTP Client<br/>(httpx + retry)"]
    
    %% 处理层
    subgraph ProcessLayer["处理层"]
        Processor["Data Processor<br/>(validate + transform)"]
        Dedup["Deduplicator<br/>(content hash)"]
    end
    
    %% 存储层
    subgraph StorageLayer["存储层"]
        Storage["Supabase Storage"]
        DB[("PostgreSQL<br/>raw_data table")]
    end
    
    %% 调度器
    Scheduler["Scheduler<br/>(APScheduler)"]
    
    %% 数据流
    GitHub --> HttpClient
    HuggingFace --> HttpClient
    OpenRouter --> HttpClient
    Reddit --> HttpClient
    HackerNews --> HttpClient
    
    HttpClient --> GS
    HttpClient --> HFS
    HttpClient --> ORS
    HttpClient --> RS
    HttpClient --> HNS
    
    GS --> Processor
    HFS --> Processor
    ORS --> Processor
    RS --> Processor
    HNS --> Processor
    
    Processor --> Dedup
    Dedup --> Storage
    Storage --> DB
    
    Scheduler -.控制.-> GS
    Scheduler -.控制.-> HFS
    Scheduler -.控制.-> ORS
    Scheduler -.控制.-> RS
    Scheduler -.控制.-> HNS
    
    %% 样式
    classDef sourceStyle fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    classDef spiderStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef processStyle fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef storageStyle fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    
    class GitHub,HuggingFace,OpenRouter,Reddit,HackerNews sourceStyle
    class GS,HFS,ORS,RS,HNS spiderStyle
    class Processor,Dedup processStyle
    class Storage,DB storageStyle
```

---

## 3. 时序图 - 爬虫执行流程

```mermaid
sequenceDiagram
    participant Scheduler
    participant Spider as GitHubSpider
    participant HttpClient
    participant Processor as DataProcessor
    participant Dedup as Deduplicator
    participant Storage as SupabaseStorage
    participant DB as PostgreSQL
    
    Scheduler->>Spider: trigger run()
    activate Spider
    
    Spider->>Spider: on_start()
    Note over Spider: 初始化、日志记录
    
    Spider->>HttpClient: fetch data
    activate HttpClient
    HttpClient->>HttpClient: retry logic
    HttpClient-->>Spider: raw response
    deactivate HttpClient
    
    Spider->>Processor: process(raw_data)
    activate Processor
    Processor->>Processor: validate schema
    Processor->>Processor: transform fields
    Processor-->>Spider: processed items
    deactivate Processor
    
    Spider->>Dedup: filter_duplicates(items)
    activate Dedup
    loop for each item
        Dedup->>Storage: get_content_hash(source, id)
        Storage->>DB: SELECT content_hash
        DB-->>Storage: existing hash
        Storage-->>Dedup: hash or None
        Dedup->>Dedup: compare hashes
    end
    Dedup-->>Spider: unique items
    deactivate Dedup
    
    Spider->>Storage: save_batch(unique_items)
    activate Storage
    Storage->>DB: INSERT INTO raw_data
    DB-->>Storage: success count
    Storage-->>Spider: saved count
    deactivate Storage
    
    Spider->>Spider: on_end()
    Note over Spider: 清理、统计、日志
    
    Spider-->>Scheduler: SpiderResult
    deactivate Spider
```

---

## 4. 组件交互图 - Factory、Scheduler、Spider

```mermaid
graph TB
    %% 入口
    Main["main.py<br/>程序入口"]
    
    %% 工厂
    Factory["SpiderFactory<br/>创建爬虫实例"]
    
    %% 注册表
    Registry["SpiderRegistry<br/>管理所有爬虫"]
    
    %% 调度器
    Scheduler["SpiderScheduler<br/>定时调度"]
    
    %% 爬虫实例
    subgraph Spiders["爬虫实例"]
        S1["GitHubSpider"]
        S2["HuggingFaceSpider"]
        S3["OpenRouterSpider"]
        S4["RedditSpider"]
        S5["HackerNewsSpider"]
    end
    
    %% 依赖组件
    subgraph Dependencies["依赖组件"]
        HTTP["HttpClient"]
        Proc["DataProcessor"]
        Store["SupabaseStorage"]
        Dedup["Deduplicator"]
        Logger["SpiderLogger"]
    end
    
    %% 配置
    Config["config.py<br/>配置文件"]
    
    %% 流程
    Main --> Factory
    Main --> Config
    
    Factory --> HTTP
    Factory --> Proc
    Factory --> Store
    Factory --> Dedup
    Factory --> Logger
    
    Factory -.创建.-> S1
    Factory -.创建.-> S2
    Factory -.创建.-> S3
    Factory -.创建.-> S4
    Factory -.创建.-> S5
    
    S1 --> Registry
    S2 --> Registry
    S3 --> Registry
    S4 --> Registry
    S5 --> Registry
    
    Registry --> Scheduler
    
    Scheduler -.定时触发.-> S1
    Scheduler -.定时触发.-> S2
    Scheduler -.定时触发.-> S3
    Scheduler -.定时触发.-> S4
    Scheduler -.定时触发.-> S5
    
    S1 --> HTTP
    S1 --> Proc
    S1 --> Store
    S1 --> Dedup
    S1 --> Logger
    
    Config -.配置.-> Factory
    Config -.配置.-> Scheduler
    
    %% 样式
    classDef factoryStyle fill:#fff9c4,stroke:#f57f17,stroke-width:3px
    classDef spiderStyle fill:#ffccbc,stroke:#bf360c,stroke-width:2px
    classDef depStyle fill:#c5cae9,stroke:#283593,stroke-width:2px
    classDef schedStyle fill:#b2dfdb,stroke:#004d40,stroke-width:3px
    
    class Factory factoryStyle
    class S1,S2,S3,S4,S5 spiderStyle
    class HTTP,Proc,Store,Dedup,Logger depStyle
    class Scheduler schedStyle
```

---

## 5. 状态机图 - 爬虫生命周期

```mermaid
stateDiagram-v2
    [*] --> Idle: 创建实例
    
    Idle --> Starting: Scheduler触发
    Starting --> Fetching: on_start()完成
    
    Fetching --> Processing: 数据获取成功
    Fetching --> Retrying: 网络错误
    Fetching --> Failed: 重试次数耗尽
    
    Retrying --> Fetching: 延迟后重试
    
    Processing --> Deduplicating: 数据处理完成
    Processing --> Failed: 处理错误
    
    Deduplicating --> Saving: 去重完成
    Deduplicating --> Failed: 去重错误
    
    Saving --> Completed: 保存成功
    Saving --> Failed: 保存失败
    
    Completed --> Idle: on_end()完成
    Failed --> Idle: 错误处理完成
    
    Idle --> [*]: 程序退出
    
    note right of Fetching
        使用 IHttpClient
        支持重试策略
    end note
    
    note right of Processing
        使用 IDataProcessor
        验证和转换数据
    end note
    
    note right of Deduplicating
        使用 IDeduplicator
        基于内容哈希
    end note
    
    note right of Saving
        使用 IDataStorage
        批量写入数据库
    end note
```

---

## 6. 部署架构图

```mermaid
graph TB
    %% 定时触发
    Cron["Cron Job / K8s CronJob"]
    
    %% 爬虫容器
    subgraph Container["Docker Container"]
        Main["main.py"]
        Scheduler["APScheduler"]
        Spiders["5个爬虫实例"]
    end
    
    %% 外部API
    subgraph ExternalAPIs["外部API"]
        GitHub["GitHub API"]
        HF["HuggingFace API"]
        OR["OpenRouter API"]
        Reddit["Reddit API"]
        HN["Hacker News API"]
    end
    
    %% 数据库
    subgraph Supabase["Supabase"]
        PG[("PostgreSQL<br/>raw_data")]
        Auth["Auth & RLS"]
    end
    
    %% 监控
    subgraph Monitoring["监控"]
        Logs["日志收集"]
        Metrics["指标监控"]
        Alerts["告警"]
    end
    
    %% 流程
    Cron --> Main
    Main --> Scheduler
    Scheduler --> Spiders
    
    Spiders --> GitHub
    Spiders --> HF
    Spiders --> OR
    Spiders --> Reddit
    Spiders --> HN
    
    Spiders --> Auth
    Auth --> PG
    
    Spiders --> Logs
    Spiders --> Metrics
    Metrics --> Alerts
    
    %% 样式
    classDef cronStyle fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    classDef containerStyle fill:#e3f2fd,stroke:#0d47a1,stroke-width:3px
    classDef apiStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef dbStyle fill:#e8f5e9,stroke:#1b5e20,stroke-width:3px
    classDef monitorStyle fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    
    class Cron cronStyle
    class Container containerStyle
    class GitHub,HF,OR,Reddit,HN apiStyle
    class Supabase dbStyle
    class Monitoring monitorStyle
```

---

## 7. 错误处理流程图

```mermaid
flowchart TD
    Start([开始执行爬虫])
    
    Fetch{HTTP请求}
    NetworkError[网络错误]
    CheckRetry{检查重试次数}
    Retry[延迟重试]
    
    Process{数据处理}
    ValidationError[验证错误]
    
    Dedupe{去重}
    
    Save{保存数据}
    SaveError[保存失败]
    
    Success([执行成功])
    Failed([执行失败])
    
    Start --> Fetch
    
    Fetch -->|成功| Process
    Fetch -->|失败| NetworkError
    
    NetworkError --> CheckRetry
    CheckRetry -->|未超限| Retry
    CheckRetry -->|超限| Failed
    Retry --> Fetch
    
    Process -->|成功| Dedupe
    Process -->|失败| ValidationError
    ValidationError --> Failed
    
    Dedupe --> Save
    
    Save -->|成功| Success
    Save -->|失败| SaveError
    SaveError --> Failed
    
    %% 样式
    classDef errorStyle fill:#ffcdd2,stroke:#c62828,stroke-width:2px
    classDef successStyle fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    
    class NetworkError,ValidationError,SaveError,Failed errorStyle
    class Success successStyle
```

---

## 8. 性能优化架构

```mermaid
graph LR
    %% 输入
    Input["5个数据源"]
    
    %% 并发层
    subgraph Concurrency["异步并发层"]
        direction TB
        Pool["连接池<br/>(httpx.AsyncClient)"]
        Semaphore["信号量<br/>(限制并发数)"]
    end
    
    %% 处理层
    subgraph Processing["处理层"]
        direction TB
        Cache["内容哈希缓存<br/>(避免重复查询)"]
        Batch["批量操作<br/>(减少DB往返)"]
    end
    
    %% 输出
    Output["PostgreSQL"]
    
    %% 流程
    Input --> Concurrency
    Concurrency --> Processing
    Processing --> Output
    
    %% 优化点标注
    Pool -.复用连接.-> Pool
    Semaphore -.控制并发.-> Semaphore
    Cache -.减少查询.-> Cache
    Batch -.批量写入.-> Batch
    
    %% 样式
    classDef optStyle fill:#e1bee7,stroke:#6a1b9a,stroke-width:2px
    class Pool,Semaphore,Cache,Batch optStyle
```

---

## 总结

### 架构特点

1. **高度解耦**：接口层 → 基类层 → 实现层，职责清晰
2. **易于扩展**：新增爬虫只需继承基类，实现 `fetch()` 方法
3. **可测试性**：所有依赖都是接口，易于 Mock
4. **可靠性**：重试机制、去重机制、异常隔离
5. **高性能**：异步并发、连接池复用、批量操作

### SOLID 原则体现

- **SRP**：每个类只负责一个职责
- **OCP**：对扩展开放，对修改关闭
- **LSP**：子类可以替换父类
- **ISP**：接口小而专注
- **DIP**：依赖抽象，使用依赖注入

### 设计模式应用

- **模板方法模式**：BaseSpider 定义执行流程
- **策略模式**：不同爬虫是不同策略
- **工厂模式**：SpiderFactory 创建实例
- **注册表模式**：SpiderRegistry 管理爬虫
- **依赖注入**：构造函数注入所有依赖
