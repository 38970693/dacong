# DaCong API - 架构可视化文档

> 使用 Mermaid 图表展示后端 API 模块的架构设计

---

## 1. 分层架构图 - API → Service → Repository → Domain

```mermaid
graph TB
    %% API层
    subgraph APILayer["API Layer (Edge Functions)"]
        direction LR
        API1["get-recommendations"]
        API2["get-content-detail"]
        API3["search-content"]
        API4["submit-feedback"]
        API5["get-weekly-report"]
    end
    
    %% Service层
    subgraph ServiceLayer["Service Layer (Business Logic)"]
        direction LR
        CS["ContentService"]
        RS["RecommendationService"]
        FS["FeedbackService"]
        WS["WeeklyReportService"]
    end
    
    %% Repository层
    subgraph RepositoryLayer["Repository Layer (Data Access)"]
        direction LR
        CR["IContentRepository"]
        RR["IRecommendationRepository"]
        FR["IFeedbackRepository"]
    end
    
    %% 实现层
    subgraph ImplementationLayer["Implementation Layer"]
        direction LR
        SCR["SupabaseContentRepository"]
        SRR["SupabaseRecommendationRepository"]
        SFR["SupabaseFeedbackRepository"]
    end
    
    %% Domain层
    subgraph DomainLayer["Domain Layer (Entities)"]
        direction LR
        Content["Content"]
        Recommendation["Recommendation"]
        Feedback["UserFeedback"]
        Scenario["Scenario"]
    end
    
    %% 数据库
    DB[("PostgreSQL<br/>Supabase")]
    
    %% 关系
    API1 --> RS
    API2 --> CS
    API3 --> CS
    API4 --> FS
    API5 --> WS
    
    CS --> CR
    RS --> RR
    FS --> FR
    WS --> CR
    
    CR -.implements.-> SCR
    RR -.implements.-> SRR
    FR -.implements.-> SFR
    
    SCR --> DB
    SRR --> DB
    SFR --> DB
    
    CS -.operates on.-> Content
    RS -.operates on.-> Recommendation
    FS -.operates on.-> Feedback
    RS -.operates on.-> Scenario
    
    %% 样式
    classDef apiStyle fill:#e3f2fd,stroke:#0d47a1,stroke-width:2px
    classDef serviceStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef repoStyle fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef implStyle fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    classDef domainStyle fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    classDef dbStyle fill:#fff9c4,stroke:#f57f17,stroke-width:3px
    
    class API1,API2,API3,API4,API5 apiStyle
    class CS,RS,FS,WS serviceStyle
    class CR,RR,FR repoStyle
    class SCR,SRR,SFR implStyle
    class Content,Recommendation,Feedback,Scenario domainStyle
    class DB dbStyle
```

---

## 2. 领域模型图 - 实体关系

```mermaid
erDiagram
    Content ||--o{ Recommendation : "generates"
    Content ||--o{ UserFeedback : "receives"
    Content }o--|| Scenario : "belongs to"
    Content }o--|| MetricSource : "from"
    
    Content {
        uuid id PK
        string title
        string description
        string content_type
        string source
        string source_id
        jsonb metadata
        timestamp created_at
        timestamp updated_at
    }
    
    Recommendation {
        uuid id PK
        uuid content_id FK
        string scenario_id FK
        int rank
        float score
        jsonb reasoning
        timestamp created_at
    }
    
    UserFeedback {
        uuid id PK
        uuid content_id FK
        string feedback_type
        string comment
        jsonb metadata
        timestamp created_at
    }
    
    Scenario {
        string id PK
        string name
        string description
        jsonb criteria
        int priority
    }
    
    MetricSource {
        string value PK
        string display_name
        string api_endpoint
        boolean enabled
    }
    
    WeeklyReport {
        uuid id PK
        string title
        jsonb content
        date week_start
        date week_end
        string status
        timestamp published_at
    }
    
    WeeklyReport ||--o{ Content : "includes"
```

---

## 3. API 调用流程图 - 请求到响应

```mermaid
sequenceDiagram
    participant Client as Flutter Client
    participant EdgeFunc as Edge Function
    participant Validator as Request Validator
    participant Service as Service Layer
    participant Repo as Repository
    participant DB as PostgreSQL
    participant Cache as Cache Layer
    
    Client->>EdgeFunc: HTTP Request
    activate EdgeFunc
    
    EdgeFunc->>Validator: validate request
    activate Validator
    alt 验证失败
        Validator-->>EdgeFunc: ValidationError
        EdgeFunc-->>Client: 400 Bad Request
    else 验证成功
        Validator-->>EdgeFunc: validated data
        deactivate Validator
        
        EdgeFunc->>Service: call business logic
        activate Service
        
        Service->>Cache: check cache
        activate Cache
        alt 缓存命中
            Cache-->>Service: cached data
        else 缓存未命中
            Cache-->>Service: null
            deactivate Cache
            
            Service->>Repo: query data
            activate Repo
            Repo->>DB: SQL query
            activate DB
            DB-->>Repo: result set
            deactivate DB
            Repo-->>Service: domain entities
            deactivate Repo
            
            Service->>Cache: update cache
            activate Cache
            Cache-->>Service: ok
            deactivate Cache
        end
        
        Service->>Service: apply business rules
        Service-->>EdgeFunc: result
        deactivate Service
        
        EdgeFunc->>EdgeFunc: format response
        EdgeFunc-->>Client: 200 OK + JSON
        deactivate EdgeFunc
    end
```

---

## 4. 依赖注入图 - Container 管理

```mermaid
graph TB
    %% Container
    Container["DI Container<br/>(Singleton)"]
    
    %% 配置
    Config["Environment Config"]
    
    %% 基础设施
    subgraph Infrastructure["Infrastructure"]
        SupabaseClient["Supabase Client"]
        Logger["Logger"]
        Cache["Cache Manager"]
    end
    
    %% Repository实现
    subgraph Repositories["Repository Implementations"]
        ContentRepo["SupabaseContentRepository"]
        RecommendationRepo["SupabaseRecommendationRepository"]
        FeedbackRepo["SupabaseFeedbackRepository"]
    end
    
    %% Services
    subgraph Services["Services"]
        ContentService["ContentService"]
        RecommendationService["RecommendationService"]
        FeedbackService["FeedbackService"]
        WeeklyReportService["WeeklyReportService"]
    end
    
    %% Edge Functions
    subgraph EdgeFunctions["Edge Functions"]
        GetRec["get-recommendations"]
        GetDetail["get-content-detail"]
        Search["search-content"]
        SubmitFB["submit-feedback"]
        GetReport["get-weekly-report"]
    end
    
    %% 依赖关系
    Config --> Container
    
    Container --> SupabaseClient
    Container --> Logger
    Container --> Cache
    
    SupabaseClient --> ContentRepo
    SupabaseClient --> RecommendationRepo
    SupabaseClient --> FeedbackRepo
    
    Logger --> ContentRepo
    Logger --> RecommendationRepo
    Logger --> FeedbackRepo
    
    ContentRepo --> ContentService
    RecommendationRepo --> RecommendationService
    FeedbackRepo --> FeedbackService
    ContentRepo --> WeeklyReportService
    
    Cache --> ContentService
    Cache --> RecommendationService
    
    ContentService --> GetDetail
    ContentService --> Search
    RecommendationService --> GetRec
    FeedbackService --> SubmitFB
    WeeklyReportService --> GetReport
    
    %% 样式
    classDef containerStyle fill:#fff9c4,stroke:#f57f17,stroke-width:3px
    classDef infraStyle fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    classDef repoStyle fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef serviceStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef apiStyle fill:#e3f2fd,stroke:#0d47a1,stroke-width:2px
    
    class Container containerStyle
    class SupabaseClient,Logger,Cache infraStyle
    class ContentRepo,RecommendationRepo,FeedbackRepo repoStyle
    class ContentService,RecommendationService,FeedbackService,WeeklyReportService serviceStyle
    class GetRec,GetDetail,Search,SubmitFB,GetReport apiStyle
```

---

## 5. 推荐算法流程图

```mermaid
flowchart TD
    Start([用户请求推荐])
    
    GetScenario[获取场景信息]
    GetContent[查询已发布内容]
    
    Filter{应用过滤条件}
    FilterByType[按内容类型过滤]
    FilterBySource[按数据源过滤]
    FilterByDate[按时间范围过滤]
    
    Score{计算推荐分数}
    PopularityScore[热度分数<br/>views + likes]
    RecencyScore[时效性分数<br/>发布时间]
    QualityScore[质量分数<br/>内容完整度]
    RelevanceScore[相关性分数<br/>场景匹配度]
    
    Combine[加权组合分数]
    Sort[按分数排序]
    Paginate[分页返回]
    
    Cache[更新缓存]
    End([返回推荐结果])
    
    Start --> GetScenario
    GetScenario --> GetContent
    GetContent --> Filter
    
    Filter --> FilterByType
    Filter --> FilterBySource
    Filter --> FilterByDate
    
    FilterByType --> Score
    FilterBySource --> Score
    FilterByDate --> Score
    
    Score --> PopularityScore
    Score --> RecencyScore
    Score --> QualityScore
    Score --> RelevanceScore
    
    PopularityScore --> Combine
    RecencyScore --> Combine
    QualityScore --> Combine
    RelevanceScore --> Combine
    
    Combine --> Sort
    Sort --> Paginate
    Paginate --> Cache
    Cache --> End
    
    %% 样式
    classDef filterStyle fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    classDef scoreStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef processStyle fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    
    class FilterByType,FilterBySource,FilterByDate filterStyle
    class PopularityScore,RecencyScore,QualityScore,RelevanceScore scoreStyle
    class Combine,Sort,Paginate,Cache processStyle
```

---

## 6. 数据库表结构图

```mermaid
graph TB
    %% 原始数据表
    subgraph RawData["原始数据层"]
        RawTable[("raw_data<br/>爬虫采集的原始数据")]
    end
    
    %% 生成内容表
    subgraph GeneratedData["生成内容层"]
        GenTable[("generated_content<br/>AI生成的内容")]
    end
    
    %% 发布内容表
    subgraph PublishedData["发布内容层"]
        PubTable[("published_content<br/>审核通过的内容")]
    end
    
    %% 推荐表
    subgraph RecommendationData["推荐层"]
        RecTable[("recommendations<br/>推荐结果")]
    end
    
    %% 反馈表
    subgraph FeedbackData["反馈层"]
        FBTable[("user_feedback<br/>用户反馈")]
    end
    
    %% 场景表
    subgraph ScenarioData["场景配置"]
        ScenarioTable[("scenarios<br/>使用场景")]
    end
    
    %% 周报表
    subgraph ReportData["周报层"]
        ReportTable[("weekly_reports<br/>精选周报")]
    end
    
    %% 数据流
    RawTable -->|AI处理| GenTable
    GenTable -->|人工审核| PubTable
    PubTable -->|计算推荐| RecTable
    PubTable -->|用户反馈| FBTable
    ScenarioTable -->|场景匹配| RecTable
    PubTable -->|精选汇总| ReportTable
    
    %% 样式
    classDef rawStyle fill:#ffebee,stroke:#c62828,stroke-width:2px
    classDef genStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef pubStyle fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    classDef recStyle fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    classDef fbStyle fill:#f3e5f5,stroke:#6a1b9a,stroke-width:2px
    classDef scenarioStyle fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    classDef reportStyle fill:#e0f2f1,stroke:#00695c,stroke-width:2px
    
    class RawTable rawStyle
    class GenTable genStyle
    class PubTable pubStyle
    class RecTable recStyle
    class FBTable fbStyle
    class ScenarioTable scenarioStyle
    class ReportTable reportStyle
```

---

## 7. 错误处理架构

```mermaid
flowchart TD
    Request[HTTP Request]
    
    Validate{请求验证}
    ValidationError[400 Bad Request<br/>参数错误]
    
    Auth{身份验证}
    AuthError[401 Unauthorized<br/>未授权]
    
    Permission{权限检查}
    PermissionError[403 Forbidden<br/>无权限]
    
    Business{业务逻辑}
    NotFound[404 Not Found<br/>资源不存在]
    Conflict[409 Conflict<br/>数据冲突]
    BusinessError[422 Unprocessable<br/>业务错误]
    
    Database{数据库操作}
    DBError[500 Internal Error<br/>数据库错误]
    
    Success[200 OK<br/>成功响应]
    
    Logger[日志记录]
    Monitor[监控告警]
    
    Request --> Validate
    Validate -->|失败| ValidationError
    Validate -->|成功| Auth
    
    Auth -->|失败| AuthError
    Auth -->|成功| Permission
    
    Permission -->|失败| PermissionError
    Permission -->|成功| Business
    
    Business -->|资源不存在| NotFound
    Business -->|数据冲突| Conflict
    Business -->|业务错误| BusinessError
    Business -->|成功| Database
    
    Database -->|失败| DBError
    Database -->|成功| Success
    
    ValidationError --> Logger
    AuthError --> Logger
    PermissionError --> Logger
    NotFound --> Logger
    Conflict --> Logger
    BusinessError --> Logger
    DBError --> Logger
    DBError --> Monitor
    
    %% 样式
    classDef errorStyle fill:#ffcdd2,stroke:#c62828,stroke-width:2px
    classDef successStyle fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    classDef monitorStyle fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    
    class ValidationError,AuthError,PermissionError,NotFound,Conflict,BusinessError,DBError errorStyle
    class Success successStyle
    class Logger,Monitor monitorStyle
```

---

## 8. 缓存策略架构

```mermaid
graph TB
    Request[API Request]
    
    subgraph CacheLayer["缓存层"]
        CacheCheck{检查缓存}
        CacheHit[缓存命中]
        CacheMiss[缓存未命中]
        CacheUpdate[更新缓存]
    end
    
    subgraph ServiceLayer["服务层"]
        Service[Business Logic]
    end
    
    subgraph DataLayer["数据层"]
        DB[(PostgreSQL)]
    end
    
    Response[API Response]
    
    Request --> CacheCheck
    
    CacheCheck -->|命中| CacheHit
    CacheCheck -->|未命中| CacheMiss
    
    CacheHit --> Response
    
    CacheMiss --> Service
    Service --> DB
    DB --> Service
    Service --> CacheUpdate
    CacheUpdate --> Response
    
    %% 缓存策略标注
    CacheHit -.TTL: 5分钟.-> CacheHit
    CacheUpdate -.推荐结果缓存.-> CacheUpdate
    
    %% 样式
    classDef cacheStyle fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    classDef serviceStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef dataStyle fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    
    class CacheCheck,CacheHit,CacheMiss,CacheUpdate cacheStyle
    class Service serviceStyle
    class DB dataStyle
```

---

## 9. 部署架构图

```mermaid
graph TB
    %% 客户端
    Client[Flutter Client<br/>Web/iOS/Android]
    
    %% CDN
    CDN[Supabase CDN]
    
    %% Edge Functions
    subgraph EdgeRuntime["Supabase Edge Runtime (Deno)"]
        direction TB
        EF1["get-recommendations"]
        EF2["get-content-detail"]
        EF3["search-content"]
        EF4["submit-feedback"]
        EF5["get-weekly-report"]
    end
    
    %% 数据库
    subgraph Database["Supabase Database"]
        PG[(PostgreSQL 15)]
        RLS[Row Level Security]
        Realtime[Realtime Subscriptions]
    end
    
    %% 认证
    subgraph Auth["Supabase Auth"]
        JWT[JWT Tokens]
        OAuth[OAuth Providers]
    end
    
    %% 存储
    subgraph Storage["Supabase Storage"]
        Images[图片存储]
        Files[文件存储]
    end
    
    %% 监控
    subgraph Monitoring["监控与日志"]
        Logs[Edge Function Logs]
        Metrics[性能指标]
        Alerts[告警通知]
    end
    
    %% 流程
    Client --> CDN
    CDN --> EdgeRuntime
    
    EdgeRuntime --> Auth
    Auth --> JWT
    Auth --> OAuth
    
    EdgeRuntime --> Database
    Database --> RLS
    Database --> Realtime
    
    EdgeRuntime --> Storage
    
    EdgeRuntime --> Monitoring
    Database --> Monitoring
    
    %% 样式
    classDef clientStyle fill:#e3f2fd,stroke:#0d47a1,stroke-width:2px
    classDef edgeStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef dbStyle fill:#e8f5e9,stroke:#1b5e20,stroke-width:3px
    classDef authStyle fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    classDef storageStyle fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef monitorStyle fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    
    class Client clientStyle
    class EdgeRuntime edgeStyle
    class Database dbStyle
    class Auth authStyle
    class Storage storageStyle
    class Monitoring monitorStyle
```

---

## 10. API 响应格式标准

```mermaid
classDiagram
    class ApiResponse~T~ {
        +boolean success
        +T data
        +string error
        +ResponseMetadata metadata
        +toJSON() object
    }
    
    class ResponseMetadata {
        +number timestamp
        +string requestId
        +number duration
        +PaginationInfo pagination
    }
    
    class PaginationInfo {
        +number total
        +number page
        +number limit
        +number totalPages
        +boolean hasNext
        +boolean hasPrev
    }
    
    class ContentResponse {
        +string id
        +string title
        +string description
        +string contentType
        +MetricSource source
        +object metadata
        +string createdAt
    }
    
    class RecommendationResponse {
        +string id
        +ContentResponse content
        +number rank
        +number score
        +object reasoning
        +string scenarioId
    }
    
    class ErrorResponse {
        +string code
        +string message
        +object details
        +string[] stack
    }
    
    ApiResponse --> ResponseMetadata
    ResponseMetadata --> PaginationInfo
    ApiResponse --> ContentResponse : data
    ApiResponse --> RecommendationResponse : data
    ApiResponse --> ErrorResponse : error
```

---

## 总结

### 架构特点

1. **分层清晰**：API → Service → Repository → Domain，职责明确
2. **依赖倒置**：服务层依赖接口，不依赖具体实现
3. **易于测试**：所有依赖可 Mock，单元测试覆盖率高
4. **类型安全**：TypeScript 强类型，Zod 运行时验证
5. **高性能**：缓存策略、批量查询、索引优化

### SOLID 原则体现

- **SRP**：每个服务只负责一个业务领域
- **OCP**：通过接口实现对扩展开放
- **LSP**：所有仓储实现可以无缝替换
- **ISP**：接口小而专注
- **DIP**：服务层依赖仓储接口

### 设计模式应用

- **Repository 模式**：隔离数据访问逻辑
- **Service 模式**：封装业务逻辑
- **DTO 模式**：数据传输对象
- **依赖注入**：Container 管理依赖
- **策略模式**：不同的推荐算法
