# DaCong 系统架构可视化文档

> 使用 Mermaid 图表展示整体系统架构设计

---

## 1. 系统全景图 - 用户到数据的完整流程

```mermaid
graph TB
    %% 用户层
    subgraph Users["用户层"]
        WebUser["Web 用户<br/>(浏览器)"]
        iOSUser["iOS 用户<br/>(iPhone/iPad)"]
        AndroidUser["Android 用户<br/>(手机/平板)"]
    end
    
    %% 前端层
    subgraph Frontend["前端层 (Flutter)"]
        FlutterWeb["Flutter Web"]
        FlutteriOS["Flutter iOS"]
        FlutterAndroid["Flutter Android"]
    end
    
    %% CDN
    CDN["Supabase CDN<br/>(静态资源)"]
    
    %% API网关
    subgraph APIGateway["API 网关"]
        EdgeFunctions["Supabase Edge Functions<br/>(Deno Runtime)"]
    end
    
    %% 后端服务
    subgraph Backend["后端服务层"]
        ContentService["ContentService"]
        RecommendationService["RecommendationService"]
        FeedbackService["FeedbackService"]
        WeeklyReportService["WeeklyReportService"]
    end
    
    %% 数据库
    subgraph Database["数据库层 (PostgreSQL)"]
        RawData[("raw_data<br/>原始数据")]
        GeneratedContent[("generated_content<br/>AI生成内容")]
        PublishedContent[("published_content<br/>发布内容")]
        UserFeedback[("user_feedback<br/>用户反馈")]
    end
    
    %% 爬虫层
    subgraph Spider["数据采集层 (Python)"]
        GitHubSpider["GitHub Spider"]
        HuggingFaceSpider["HuggingFace Spider"]
        OpenRouterSpider["OpenRouter Spider"]
        RedditSpider["Reddit Spider"]
        HackerNewsSpider["HackerNews Spider"]
    end
    
    %% 外部数据源
    subgraph ExternalAPIs["外部数据源"]
        GitHub["GitHub API"]
        HuggingFace["HuggingFace API"]
        OpenRouter["OpenRouter API"]
        Reddit["Reddit API"]
        HackerNews["Hacker News API"]
    end
    
    %% AI服务
    Claude["Claude API<br/>(内容生成)"]
    
    %% 用户流程
    WebUser --> FlutterWeb
    iOSUser --> FlutteriOS
    AndroidUser --> FlutterAndroid
    
    FlutterWeb --> CDN
    FlutteriOS --> CDN
    FlutterAndroid --> CDN
    
    FlutterWeb --> EdgeFunctions
    FlutteriOS --> EdgeFunctions
    FlutterAndroid --> EdgeFunctions
    
    EdgeFunctions --> ContentService
    EdgeFunctions --> RecommendationService
    EdgeFunctions --> FeedbackService
    EdgeFunctions --> WeeklyReportService
    
    ContentService --> PublishedContent
    RecommendationService --> PublishedContent
    FeedbackService --> UserFeedback
    WeeklyReportService --> PublishedContent
    
    %% 数据采集流程
    GitHub --> GitHubSpider
    HuggingFace --> HuggingFaceSpider
    OpenRouter --> OpenRouterSpider
    Reddit --> RedditSpider
    HackerNews --> HackerNewsSpider
    
    GitHubSpider --> RawData
    HuggingFaceSpider --> RawData
    OpenRouterSpider --> RawData
    RedditSpider --> RawData
    HackerNewsSpider --> RawData
    
    %% AI处理流程
    RawData --> Claude
    Claude --> GeneratedContent
    GeneratedContent -.人工审核.-> PublishedContent
    
    %% 样式
    classDef userStyle fill:#e3f2fd,stroke:#0d47a1,stroke-width:2px
    classDef frontendStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef backendStyle fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    classDef dbStyle fill:#f3e5f5,stroke:#4a148c,stroke-width:3px
    classDef spiderStyle fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    classDef externalStyle fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    classDef aiStyle fill:#e1bee7,stroke:#6a1b9a,stroke-width:3px
    
    class WebUser,iOSUser,AndroidUser userStyle
    class FlutterWeb,FlutteriOS,FlutterAndroid frontendStyle
    class ContentService,RecommendationService,FeedbackService,WeeklyReportService backendStyle
    class RawData,GeneratedContent,PublishedContent,UserFeedback dbStyle
    class GitHubSpider,HuggingFaceSpider,OpenRouterSpider,RedditSpider,HackerNewsSpider spiderStyle
    class GitHub,HuggingFace,OpenRouter,Reddit,HackerNews externalStyle
    class Claude aiStyle
```

---

## 2. 部署架构图 - 各模块的部署方式

```mermaid
graph TB
    %% 用户
    Internet["Internet"]
    
    %% Supabase平台
    subgraph SupabasePlatform["Supabase 平台"]
        direction TB
        
        subgraph EdgeRuntime["Edge Runtime"]
            EdgeFunc1["get-recommendations"]
            EdgeFunc2["get-content-detail"]
            EdgeFunc3["search-content"]
            EdgeFunc4["submit-feedback"]
            EdgeFunc5["get-weekly-report"]
        end
        
        subgraph DatabaseCluster["Database Cluster"]
            Primary[("Primary DB<br/>PostgreSQL 15")]
            Replica1[("Replica 1")]
            Replica2[("Replica 2")]
        end
        
        subgraph AuthService["Auth Service"]
            JWT["JWT 验证"]
            RLS["Row Level Security"]
        end
        
        subgraph StorageService["Storage Service"]
            Images["图片存储"]
            Files["文件存储"]
        end
        
        CDN["Global CDN"]
    end
    
    %% 爬虫部署
    subgraph SpiderDeployment["爬虫部署 (Docker)"]
        direction TB
        
        subgraph K8s["Kubernetes Cluster"]
            CronJob1["GitHub Spider<br/>(CronJob)"]
            CronJob2["HuggingFace Spider<br/>(CronJob)"]
            CronJob3["OpenRouter Spider<br/>(CronJob)"]
            CronJob4["Reddit Spider<br/>(CronJob)"]
            CronJob5["HackerNews Spider<br/>(CronJob)"]
        end
        
        Scheduler["APScheduler<br/>(定时调度)"]
    end
    
    %% AI服务
    ClaudeAPI["Claude API<br/>(Anthropic)"]
    
    %% 监控
    subgraph Monitoring["监控与日志"]
        Logs["日志收集<br/>(Supabase Logs)"]
        Metrics["性能监控<br/>(Prometheus)"]
        Alerts["告警通知<br/>(Telegram/Email)"]
    end
    
    %% 流程
    Internet --> CDN
    CDN --> EdgeRuntime
    
    EdgeRuntime --> AuthService
    EdgeRuntime --> DatabaseCluster
    EdgeRuntime --> StorageService
    
    Primary --> Replica1
    Primary --> Replica2
    
    Scheduler --> K8s
    K8s --> Primary
    
    Primary --> ClaudeAPI
    
    EdgeRuntime --> Monitoring
    K8s --> Monitoring
    DatabaseCluster --> Monitoring
    
    %% 样式
    classDef supabaseStyle fill:#e8f5e9,stroke:#1b5e20,stroke-width:3px
    classDef spiderStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef aiStyle fill:#e1bee7,stroke:#6a1b9a,stroke-width:2px
    classDef monitorStyle fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    
    class SupabasePlatform supabaseStyle
    class SpiderDeployment spiderStyle
    class ClaudeAPI aiStyle
    class Monitoring monitorStyle
```

---

## 3. 数据流全景 - 从采集到展示

```mermaid
flowchart LR
    %% 数据采集
    subgraph Collection["1. 数据采集"]
        direction TB
        Sources["外部数据源<br/>GitHub/HF/OR/Reddit/HN"]
        Spiders["Python 爬虫<br/>(定时执行)"]
        RawDB[("raw_data")]
    end
    
    %% AI处理
    subgraph AIProcessing["2. AI 处理"]
        direction TB
        ClaudeAPI["Claude API"]
        GenDB[("generated_content")]
    end
    
    %% 人工审核
    subgraph Review["3. 人工审核"]
        direction TB
        Console["管理后台<br/>(待开发)"]
        PubDB[("published_content")]
    end
    
    %% 推荐计算
    subgraph Recommendation["4. 推荐计算"]
        direction TB
        RecService["RecommendationService"]
        RecDB[("recommendations")]
    end
    
    %% 用户展示
    subgraph Display["5. 用户展示"]
        direction TB
        API["Edge Functions"]
        Flutter["Flutter App"]
        Users["用户"]
    end
    
    %% 用户反馈
    subgraph Feedback["6. 用户反馈"]
        direction TB
        FeedbackAPI["submit-feedback"]
        FeedbackDB[("user_feedback")]
    end
    
    %% 流程
    Sources --> Spiders
    Spiders --> RawDB
    
    RawDB --> ClaudeAPI
    ClaudeAPI --> GenDB
    
    GenDB --> Console
    Console --> PubDB
    
    PubDB --> RecService
    RecService --> RecDB
    
    RecDB --> API
    API --> Flutter
    Flutter --> Users
    
    Users --> FeedbackAPI
    FeedbackAPI --> FeedbackDB
    FeedbackDB -.影响排序.-> RecService
    
    %% 样式
    classDef collectionStyle fill:#ffebee,stroke:#c62828,stroke-width:2px
    classDef aiStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef reviewStyle fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    classDef recStyle fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    classDef displayStyle fill:#f3e5f5,stroke:#6a1b9a,stroke-width:2px
    classDef feedbackStyle fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    
    class Collection collectionStyle
    class AIProcessing aiStyle
    class Review reviewStyle
    class Recommendation recStyle
    class Display displayStyle
    class Feedback feedbackStyle
```

---

## 4. 技术栈全景图

```mermaid
mindmap
  root((DaCong<br/>技术栈))
    前端
      Flutter 3.x
        Dart 3.x
        flutter_bloc
        get_it + injectable
        dio
        freezed
        dartz
      平台
        Web
        iOS
        Android
    后端
      Supabase
        Edge Functions
        PostgreSQL 15
        Auth & RLS
        Storage
        Realtime
      TypeScript 5.x
        Deno Runtime
        Zod 验证
        依赖注入
    爬虫
      Python 3.11
        asyncio
        httpx
        APScheduler
        Supabase Client
      设计模式
        SOLID 原则
        工厂模式
        策略模式
        模板方法
    AI
      Claude 3.5 Sonnet
        内容生成
        摘要提取
        标签分类
    部署
      Docker
        Dockerfile
        docker-compose
      Kubernetes
        CronJob
        ConfigMap
        Secret
      CI/CD
        GitLab CI
        GitHub Actions
    监控
      日志
        Supabase Logs
        Python logging
      指标
        Prometheus
        Grafana
      告警
        Telegram Bot
        Email
```

---

## 5. 安全架构图

```mermaid
graph TB
    %% 用户请求
    UserRequest["用户请求"]
    
    %% 安全层
    subgraph SecurityLayers["安全层"]
        direction TB
        
        HTTPS["HTTPS/TLS<br/>(传输加密)"]
        
        subgraph WAF["Web Application Firewall"]
            RateLimit["速率限制"]
            IPFilter["IP 过滤"]
            DDoSProtection["DDoS 防护"]
        end
        
        subgraph Authentication["身份验证"]
            JWTValidation["JWT 验证"]
            TokenRefresh["Token 刷新"]
            OAuth["OAuth 2.0"]
        end
        
        subgraph Authorization["权限控制"]
            RLS["Row Level Security"]
            RBAC["基于角色的访问控制"]
            PolicyEngine["策略引擎"]
        end
        
        subgraph DataSecurity["数据安全"]
            Encryption["数据加密<br/>(AES-256)"]
            Hashing["密码哈希<br/>(bcrypt)"]
            Sanitization["输入清理"]
        end
        
        subgraph APIValidation["API 验证"]
            SchemaValidation["Schema 验证<br/>(Zod)"]
            InputValidation["输入验证"]
            OutputValidation["输出验证"]
        end
    end
    
    %% 后端服务
    Backend["后端服务"]
    
    %% 数据库
    Database[("数据库")]
    
    %% 审计日志
    AuditLog["审计日志"]
    
    %% 流程
    UserRequest --> HTTPS
    HTTPS --> WAF
    WAF --> Authentication
    Authentication --> Authorization
    Authorization --> APIValidation
    APIValidation --> DataSecurity
    DataSecurity --> Backend
    Backend --> Database
    
    Authentication --> AuditLog
    Authorization --> AuditLog
    Backend --> AuditLog
    
    %% 样式
    classDef securityStyle fill:#ffcdd2,stroke:#c62828,stroke-width:2px
    classDef authStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef dataStyle fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    classDef auditStyle fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    
    class HTTPS,WAF securityStyle
    class Authentication,Authorization authStyle
    class DataSecurity,APIValidation dataStyle
    class AuditLog auditStyle
```

---

## 6. 性能优化架构

```mermaid
graph TB
    %% 前端优化
    subgraph FrontendOpt["前端优化"]
        direction TB
        LazyLoad["图片懒加载"]
        CodeSplit["代码分割"]
        TreeShaking["Tree Shaking"]
        Minify["代码压缩"]
        LocalCache["本地缓存<br/>(Hive)"]
    end
    
    %% CDN优化
    subgraph CDNOpt["CDN 优化"]
        direction TB
        GlobalCDN["全球 CDN"]
        EdgeCache["边缘缓存"]
        Compression["Gzip/Brotli 压缩"]
        HTTP2["HTTP/2"]
    end
    
    %% API优化
    subgraph APIOpt["API 优化"]
        direction TB
        ResponseCache["响应缓存<br/>(5分钟)"]
        Pagination["分页加载"]
        FieldSelection["字段选择"]
        BatchRequest["批量请求"]
    end
    
    %% 数据库优化
    subgraph DBOpt["数据库优化"]
        direction TB
        Indexing["索引优化"]
        QueryOpt["查询优化"]
        ConnectionPool["连接池"]
        ReadReplica["读写分离"]
    end
    
    %% 爬虫优化
    subgraph SpiderOpt["爬虫优化"]
        direction TB
        AsyncIO["异步并发"]
        ConnReuse["连接复用"]
        BatchWrite["批量写入"]
        Incremental["增量更新"]
    end
    
    %% 性能指标
    subgraph Metrics["性能指标"]
        direction TB
        FCP["FCP < 1.5s"]
        LCP["LCP < 2.5s"]
        TTI["TTI < 3.5s"]
        API_RT["API RT < 200ms"]
        DB_RT["DB RT < 50ms"]
    end
    
    %% 关系
    FrontendOpt --> FCP
    CDNOpt --> FCP
    APIOpt --> API_RT
    DBOpt --> DB_RT
    SpiderOpt --> DB_RT
    
    FrontendOpt --> LCP
    CDNOpt --> LCP
    
    FrontendOpt --> TTI
    APIOpt --> TTI
    
    %% 样式
    classDef optStyle fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    classDef metricStyle fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    
    class FrontendOpt,CDNOpt,APIOpt,DBOpt,SpiderOpt optStyle
    class Metrics metricStyle
```

---

## 7. 监控与告警架构

```mermaid
graph TB
    %% 数据采集
    subgraph DataCollection["数据采集"]
        direction TB
        AppLogs["应用日志"]
        AccessLogs["访问日志"]
        ErrorLogs["错误日志"]
        Metrics["性能指标"]
    end
    
    %% 日志聚合
    subgraph LogAggregation["日志聚合"]
        direction TB
        LogCollector["日志收集器"]
        LogParser["日志解析器"]
        LogStorage["日志存储"]
    end
    
    %% 指标监控
    subgraph MetricsMonitoring["指标监控"]
        direction TB
        Prometheus["Prometheus"]
        Grafana["Grafana"]
        Dashboard["监控面板"]
    end
    
    %% 告警系统
    subgraph AlertSystem["告警系统"]
        direction TB
        AlertRules["告警规则"]
        AlertManager["告警管理器"]
        Notification["通知渠道"]
    end
    
    %% 通知渠道
    subgraph NotificationChannels["通知渠道"]
        direction TB
        Telegram["Telegram Bot"]
        Email["Email"]
        Slack["Slack"]
    end
    
    %% 流程
    AppLogs --> LogCollector
    AccessLogs --> LogCollector
    ErrorLogs --> LogCollector
    
    LogCollector --> LogParser
    LogParser --> LogStorage
    
    Metrics --> Prometheus
    Prometheus --> Grafana
    Grafana --> Dashboard
    
    LogStorage --> AlertRules
    Prometheus --> AlertRules
    
    AlertRules --> AlertManager
    AlertManager --> Notification
    
    Notification --> Telegram
    Notification --> Email
    Notification --> Slack
    
    %% 样式
    classDef collectionStyle fill:#e3f2fd,stroke:#0d47a1,stroke-width:2px
    classDef aggregationStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef monitoringStyle fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    classDef alertStyle fill:#ffcdd2,stroke:#c62828,stroke-width:2px
    classDef notifyStyle fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    
    class DataCollection collectionStyle
    class LogAggregation aggregationStyle
    class MetricsMonitoring monitoringStyle
    class AlertSystem alertStyle
    class NotificationChannels notifyStyle
```

---

## 8. 扩展性架构

```mermaid
graph TB
    %% 当前架构
    subgraph Current["当前架构"]
        direction TB
        CurrentFrontend["Flutter App"]
        CurrentAPI["Edge Functions"]
        CurrentDB["PostgreSQL"]
        CurrentSpider["Python Spiders"]
    end
    
    %% 水平扩展
    subgraph HorizontalScaling["水平扩展"]
        direction TB
        
        subgraph FrontendScale["前端扩展"]
            CDN["全球 CDN"]
            MultiRegion["多区域部署"]
        end
        
        subgraph APIScale["API 扩展"]
            AutoScale["自动扩展"]
            LoadBalancer["负载均衡"]
        end
        
        subgraph DBScale["数据库扩展"]
            ReadReplicas["读副本"]
            Sharding["分片"]
        end
        
        subgraph SpiderScale["爬虫扩展"]
            MultiInstance["多实例部署"]
            DistributedQueue["分布式队列"]
        end
    end
    
    %% 垂直扩展
    subgraph VerticalScaling["垂直扩展"]
        direction TB
        
        subgraph NewFeatures["新功能"]
            AIChat["AI 对话助手"]
            Personalization["个性化推荐"]
            Analytics["数据分析"]
        end
        
        subgraph NewDataSources["新数据源"]
            Twitter["Twitter/X"]
            ProductHunt["Product Hunt"]
            ArXiv["arXiv"]
        end
        
        subgraph NewPlatforms["新平台"]
            Desktop["桌面应用"]
            CLI["命令行工具"]
            API["开放 API"]
        end
    end
    
    %% 关系
    CurrentFrontend --> FrontendScale
    CurrentAPI --> APIScale
    CurrentDB --> DBScale
    CurrentSpider --> SpiderScale
    
    Current --> NewFeatures
    Current --> NewDataSources
    Current --> NewPlatforms
    
    %% 样式
    classDef currentStyle fill:#e3f2fd,stroke:#0d47a1,stroke-width:2px
    classDef hScaleStyle fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    classDef vScaleStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    
    class Current currentStyle
    class HorizontalScaling hScaleStyle
    class VerticalScaling vScaleStyle
```

---

## 9. 开发流程架构

```mermaid
flowchart LR
    %% 开发阶段
    subgraph Development["开发阶段"]
        direction TB
        LocalDev["本地开发"]
        UnitTest["单元测试"]
        CodeReview["代码审查"]
    end
    
    %% 构建阶段
    subgraph Build["构建阶段"]
        direction TB
        Compile["编译构建"]
        IntegrationTest["集成测试"]
        SecurityScan["安全扫描"]
    end
    
    %% 测试阶段
    subgraph Testing["测试阶段"]
        direction TB
        E2ETest["E2E 测试"]
        PerformanceTest["性能测试"]
        UAT["用户验收测试"]
    end
    
    %% 部署阶段
    subgraph Deployment["部署阶段"]
        direction TB
        Staging["预发布环境"]
        Production["生产环境"]
        Rollback["回滚机制"]
    end
    
    %% 监控阶段
    subgraph Monitoring["监控阶段"]
        direction TB
        HealthCheck["健康检查"]
        Metrics["指标监控"]
        Alerts["告警通知"]
    end
    
    %% 流程
    Development --> Build
    Build --> Testing
    Testing --> Deployment
    Deployment --> Monitoring
    Monitoring -.问题反馈.-> Development
    
    %% 样式
    classDef devStyle fill:#e3f2fd,stroke:#0d47a1,stroke-width:2px
    classDef buildStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef testStyle fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    classDef deployStyle fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef monitorStyle fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    
    class Development devStyle
    class Build buildStyle
    class Testing testStyle
    class Deployment deployStyle
    class Monitoring monitorStyle
```

---

## 10. 成本优化架构

```mermaid
graph TB
    %% 成本分析
    subgraph CostAnalysis["成本分析"]
        direction TB
        
        subgraph Infrastructure["基础设施成本"]
            SupabaseCost["Supabase<br/>$25/月 (Pro)"]
            K8sCost["Kubernetes<br/>$50/月"]
            CDNCost["CDN<br/>$10/月"]
        end
        
        subgraph API["API 调用成本"]
            ClaudeCost["Claude API<br/>按使用量"]
            ExternalAPICost["外部 API<br/>免费层"]
        end
        
        subgraph Storage["存储成本"]
            DBStorage["数据库存储<br/>8GB 免费"]
            FileStorage["文件存储<br/>100GB 免费"]
        end
    end
    
    %% 优化策略
    subgraph Optimization["优化策略"]
        direction TB
        
        subgraph CacheStrategy["缓存策略"]
            LocalCache["本地缓存"]
            EdgeCache["边缘缓存"]
            DBCache["数据库缓存"]
        end
        
        subgraph ResourceOpt["资源优化"]
            AutoScale["自动扩缩容"]
            SpotInstance["竞价实例"]
            Reserved["预留实例"]
        end
        
        subgraph DataOpt["数据优化"]
            Compression["数据压缩"]
            Deduplication["去重"]
            Archiving["归档"]
        end
    end
    
    %% 预期成本
    TotalCost["总成本<br/>~$100/月"]
    
    %% 关系
    Infrastructure --> TotalCost
    API --> TotalCost
    Storage --> TotalCost
    
    CacheStrategy -.减少 API 调用.-> API
    ResourceOpt -.减少基础设施.-> Infrastructure
    DataOpt -.减少存储.-> Storage
    
    %% 样式
    classDef costStyle fill:#ffcdd2,stroke:#c62828,stroke-width:2px
    classDef optStyle fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    classDef totalStyle fill:#fff9c4,stroke:#f57f17,stroke-width:3px
    
    class Infrastructure,API,Storage costStyle
    class CacheStrategy,ResourceOpt,DataOpt optStyle
    class TotalCost totalStyle
```

---

## 总结

### 系统特点

1. **微服务架构**：前端、后端、爬虫独立部署，松耦合
2. **云原生**：基于 Supabase 和 Kubernetes，自动扩展
3. **高可用**：数据库主从复制，API 自动扩展，CDN 加速
4. **安全可靠**：多层安全防护，审计日志，数据加密
5. **可观测性**：完善的日志、指标、告警体系

### 技术优势

- **Flutter**：一套代码，三端部署（Web/iOS/Android）
- **Supabase**：开箱即用的后端服务，降低开发成本
- **Python**：丰富的爬虫生态，易于扩展
- **Claude API**：高质量的内容生成
- **PostgreSQL**：强大的关系型数据库，支持复杂查询

### 扩展能力

- **水平扩展**：所有组件都支持水平扩展
- **垂直扩展**：易于添加新功能、新数据源、新平台
- **成本可控**：按需付费，自动扩缩容
- **性能优化**：多层缓存，CDN 加速，数据库优化

### 运维保障

- **自动化部署**：CI/CD 流程，一键部署
- **监控告警**：实时监控，及时告警
- **日志审计**：完整的日志记录，便于排查问题
- **灾难恢复**：数据备份，快速回滚

---

**文档版本**：v1.0  
**最后更新**：2026-04-17  
**维护者**：DaCong Team
