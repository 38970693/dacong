# DaCong Client - 架构可视化文档

> 使用 Mermaid 图表展示 Flutter 前端模块的架构设计

---

## 1. Clean Architecture 分层图

```mermaid
graph TB
    %% Presentation Layer
    subgraph PresentationLayer["Presentation Layer (UI + State)"]
        direction TB
        
        subgraph Pages["Pages"]
            HomePage["HomePage"]
            DetailPage["ContentDetailPage"]
            SearchPage["SearchPage"]
            ReportPage["WeeklyReportPage"]
        end
        
        subgraph Widgets["Widgets"]
            ContentCard["ContentCard"]
            RecommendationList["RecommendationList"]
            SearchBar["SearchBar"]
            FilterPanel["FilterPanel"]
        end
        
        subgraph BLoCs["BLoC (State Management)"]
            RecommendationBloc["RecommendationBloc"]
            ContentBloc["ContentBloc"]
            SearchBloc["SearchBloc"]
            FeedbackBloc["FeedbackBloc"]
        end
    end
    
    %% Domain Layer
    subgraph DomainLayer["Domain Layer (Business Logic)"]
        direction TB
        
        subgraph Entities["Entities"]
            Content["Content"]
            Recommendation["Recommendation"]
            Scenario["Scenario"]
            Feedback["UserFeedback"]
        end
        
        subgraph UseCases["Use Cases"]
            GetRecommendations["GetRecommendations"]
            GetContentDetail["GetContentDetail"]
            SearchContent["SearchContent"]
            SubmitFeedback["SubmitFeedback"]
            GetWeeklyReport["GetWeeklyReport"]
        end
        
        subgraph Repositories["Repository Interfaces"]
            IContentRepo["IContentRepository"]
            IScenarioRepo["IScenarioRepository"]
            IFeedbackRepo["IFeedbackRepository"]
        end
    end
    
    %% Data Layer
    subgraph DataLayer["Data Layer (Data Access)"]
        direction TB
        
        subgraph Models["Models"]
            ContentModel["ContentModel"]
            RecommendationModel["RecommendationModel"]
            ScenarioModel["ScenarioModel"]
        end
        
        subgraph RepoImpl["Repository Implementations"]
            ContentRepoImpl["ContentRepositoryImpl"]
            ScenarioRepoImpl["ScenarioRepositoryImpl"]
            FeedbackRepoImpl["FeedbackRepositoryImpl"]
        end
        
        subgraph DataSources["Data Sources"]
            RemoteDS["RemoteDataSource"]
            LocalDS["LocalDataSource"]
        end
    end
    
    %% External
    API["Supabase API<br/>(Edge Functions)"]
    Cache["Local Cache<br/>(Hive/SharedPreferences)"]
    
    %% 依赖关系
    Pages --> BLoCs
    Widgets --> BLoCs
    
    BLoCs --> UseCases
    
    UseCases --> Repositories
    UseCases --> Entities
    
    Repositories -.implements.-> RepoImpl
    
    RepoImpl --> DataSources
    RepoImpl --> Models
    
    Models -.maps to.-> Entities
    
    RemoteDS --> API
    LocalDS --> Cache
    
    %% 样式
    classDef presentationStyle fill:#e3f2fd,stroke:#0d47a1,stroke-width:2px
    classDef domainStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef dataStyle fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    classDef externalStyle fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    
    class Pages,Widgets,BLoCs presentationStyle
    class Entities,UseCases,Repositories domainStyle
    class Models,RepoImpl,DataSources dataStyle
    class API,Cache externalStyle
```

---

## 2. BLoC 状态流转图

```mermaid
stateDiagram-v2
    [*] --> Initial: 创建BLoC
    
    Initial --> Loading: LoadRecommendations事件
    
    Loading --> Loaded: 数据加载成功
    Loading --> Error: 加载失败
    
    Loaded --> Refreshing: RefreshRecommendations事件
    Loaded --> LoadingMore: LoadMoreRecommendations事件
    Loaded --> Filtering: FilterChanged事件
    
    Refreshing --> Loaded: 刷新成功
    Refreshing --> Error: 刷新失败
    
    LoadingMore --> Loaded: 加载更多成功
    LoadingMore --> Error: 加载更多失败
    
    Filtering --> Loaded: 过滤完成
    
    Error --> Loading: RetryLoad事件
    Error --> Initial: Reset事件
    
    Loaded --> [*]: BLoC销毁
    Error --> [*]: BLoC销毁
    
    note right of Initial
        初始状态
        无数据
    end note
    
    note right of Loading
        显示加载指示器
        禁用交互
    end note
    
    note right of Loaded
        显示数据列表
        启用交互
        支持下拉刷新
    end note
    
    note right of Error
        显示错误信息
        提供重试按钮
    end note
```

---

## 3. 数据流图 - UI → Use Case → Repository → API

```mermaid
sequenceDiagram
    participant UI as HomePage
    participant BLoC as RecommendationBloc
    participant UseCase as GetRecommendations
    participant Repo as IScenarioRepository
    participant RepoImpl as ScenarioRepositoryImpl
    participant Remote as RemoteDataSource
    participant API as Supabase API
    participant Local as LocalDataSource
    
    UI->>BLoC: LoadRecommendations事件
    activate BLoC
    
    BLoC->>BLoC: emit(Loading)
    
    BLoC->>UseCase: call(scenarioId)
    activate UseCase
    
    UseCase->>Repo: getRecommendations(scenarioId)
    activate Repo
    
    Repo->>Local: getCachedRecommendations()
    activate Local
    alt 缓存有效
        Local-->>Repo: cached data
        Repo-->>UseCase: Right(recommendations)
    else 缓存过期或不存在
        Local-->>Repo: null
        deactivate Local
        
        Repo->>Remote: fetchRecommendations(scenarioId)
        activate Remote
        Remote->>API: GET /get-recommendations
        activate API
        
        alt API成功
            API-->>Remote: 200 OK + JSON
            deactivate API
            Remote-->>Repo: RecommendationModel[]
            deactivate Remote
            
            Repo->>Local: cacheRecommendations(data)
            activate Local
            Local-->>Repo: ok
            deactivate Local
            
            Repo->>Repo: map to entities
            Repo-->>UseCase: Right(recommendations)
        else API失败
            API-->>Remote: Error
            Remote-->>Repo: Exception
            Repo-->>UseCase: Left(Failure)
        end
    end
    
    deactivate Repo
    
    UseCase-->>BLoC: Either<Failure, List<Recommendation>>
    deactivate UseCase
    
    alt 成功
        BLoC->>BLoC: emit(Loaded(recommendations))
        BLoC-->>UI: 更新UI
    else 失败
        BLoC->>BLoC: emit(Error(message))
        BLoC-->>UI: 显示错误
    end
    
    deactivate BLoC
```

---

## 4. 页面导航图

```mermaid
graph TB
    %% 主页面
    Home["HomePage<br/>(场景选择)"]
    
    %% 推荐页面
    Recommendations["RecommendationsPage<br/>(推荐列表)"]
    
    %% 详情页面
    Detail["ContentDetailPage<br/>(内容详情)"]
    
    %% 搜索页面
    Search["SearchPage<br/>(搜索)"]
    
    %% 周报页面
    Report["WeeklyReportPage<br/>(精选周报)"]
    
    %% 设置页面
    Settings["SettingsPage<br/>(设置)"]
    
    %% 导航流程
    Home -->|选择场景| Recommendations
    Home -->|点击搜索| Search
    Home -->|查看周报| Report
    Home -->|打开设置| Settings
    
    Recommendations -->|点击卡片| Detail
    Recommendations -->|返回| Home
    
    Search -->|点击结果| Detail
    Search -->|返回| Home
    
    Report -->|点击内容| Detail
    Report -->|返回| Home
    
    Detail -->|返回| Recommendations
    Detail -->|返回| Search
    Detail -->|返回| Report
    
    Settings -->|返回| Home
    
    %% 样式
    classDef homeStyle fill:#e3f2fd,stroke:#0d47a1,stroke-width:3px
    classDef listStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef detailStyle fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    classDef utilStyle fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    
    class Home homeStyle
    class Recommendations,Search,Report listStyle
    class Detail detailStyle
    class Settings utilStyle
```

---

## 5. 依赖注入架构

```mermaid
graph TB
    %% 入口
    Main["main.dart<br/>应用入口"]
    
    %% DI容器
    DI["Dependency Injection<br/>(get_it + injectable)"]
    
    %% 外部依赖
    subgraph External["External Dependencies"]
        Dio["Dio<br/>(HTTP Client)"]
        Hive["Hive<br/>(Local Storage)"]
        SharedPrefs["SharedPreferences<br/>(Config)"]
    end
    
    %% Data Sources
    subgraph DataSources["Data Sources"]
        RemoteDS["RemoteDataSource"]
        LocalDS["LocalDataSource"]
    end
    
    %% Repositories
    subgraph Repositories["Repositories"]
        ContentRepo["ContentRepositoryImpl"]
        ScenarioRepo["ScenarioRepositoryImpl"]
        FeedbackRepo["FeedbackRepositoryImpl"]
    end
    
    %% Use Cases
    subgraph UseCases["Use Cases"]
        GetRec["GetRecommendations"]
        GetDetail["GetContentDetail"]
        SearchContent["SearchContent"]
        SubmitFB["SubmitFeedback"]
        GetReport["GetWeeklyReport"]
    end
    
    %% BLoCs
    subgraph BLoCs["BLoCs"]
        RecBloc["RecommendationBloc"]
        ContentBloc["ContentBloc"]
        SearchBloc["SearchBloc"]
        FeedbackBloc["FeedbackBloc"]
    end
    
    %% 依赖关系
    Main --> DI
    
    DI --> Dio
    DI --> Hive
    DI --> SharedPrefs
    
    Dio --> RemoteDS
    Hive --> LocalDS
    SharedPrefs --> LocalDS
    
    RemoteDS --> ContentRepo
    RemoteDS --> ScenarioRepo
    RemoteDS --> FeedbackRepo
    LocalDS --> ContentRepo
    LocalDS --> ScenarioRepo
    
    ContentRepo --> GetDetail
    ContentRepo --> SearchContent
    ScenarioRepo --> GetRec
    FeedbackRepo --> SubmitFB
    ContentRepo --> GetReport
    
    GetRec --> RecBloc
    GetDetail --> ContentBloc
    SearchContent --> SearchBloc
    SubmitFB --> FeedbackBloc
    GetReport --> ContentBloc
    
    %% 样式
    classDef diStyle fill:#fff9c4,stroke:#f57f17,stroke-width:3px
    classDef externalStyle fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    classDef dsStyle fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef repoStyle fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    classDef usecaseStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef blocStyle fill:#e3f2fd,stroke:#0d47a1,stroke-width:2px
    
    class DI diStyle
    class Dio,Hive,SharedPrefs externalStyle
    class RemoteDS,LocalDS dsStyle
    class ContentRepo,ScenarioRepo,FeedbackRepo repoStyle
    class GetRec,GetDetail,SearchContent,SubmitFB,GetReport usecaseStyle
    class RecBloc,ContentBloc,SearchBloc,FeedbackBloc blocStyle
```

---

## 6. 错误处理架构

```mermaid
flowchart TD
    Start([用户操作])
    
    UI[UI Layer]
    BLoC[BLoC Layer]
    UseCase[Use Case Layer]
    Repo[Repository Layer]
    DataSource[Data Source Layer]
    
    NetworkCheck{网络检查}
    NetworkError[NetworkFailure]
    
    APICall{API调用}
    ServerError[ServerFailure]
    TimeoutError[TimeoutFailure]
    
    Parse{数据解析}
    ParseError[ParseFailure]
    
    Cache{缓存操作}
    CacheError[CacheFailure]
    
    Success[Success]
    
    ShowError[显示错误提示]
    ShowRetry[显示重试按钮]
    ShowCached[显示缓存数据]
    
    Start --> UI
    UI --> BLoC
    BLoC --> UseCase
    UseCase --> Repo
    Repo --> DataSource
    
    DataSource --> NetworkCheck
    NetworkCheck -->|无网络| NetworkError
    NetworkCheck -->|有网络| APICall
    
    APICall -->|5xx错误| ServerError
    APICall -->|超时| TimeoutError
    APICall -->|成功| Parse
    
    Parse -->|失败| ParseError
    Parse -->|成功| Cache
    
    Cache -->|失败| CacheError
    Cache -->|成功| Success
    
    NetworkError --> ShowCached
    ServerError --> ShowRetry
    TimeoutError --> ShowRetry
    ParseError --> ShowError
    CacheError --> ShowError
    
    ShowCached --> UI
    ShowRetry --> UI
    ShowError --> UI
    Success --> UI
    
    %% 样式
    classDef errorStyle fill:#ffcdd2,stroke:#c62828,stroke-width:2px
    classDef successStyle fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    classDef uiStyle fill:#e3f2fd,stroke:#0d47a1,stroke-width:2px
    
    class NetworkError,ServerError,TimeoutError,ParseError,CacheError errorStyle
    class Success successStyle
    class ShowError,ShowRetry,ShowCached uiStyle
```

---

## 7. 缓存策略架构

```mermaid
graph TB
    Request[数据请求]
    
    subgraph CacheLayer["缓存层"]
        CheckCache{检查本地缓存}
        ValidCache{缓存是否有效}
        ReturnCache[返回缓存数据]
        UpdateCache[更新缓存]
    end
    
    subgraph NetworkLayer["网络层"]
        CheckNetwork{检查网络}
        FetchRemote[请求远程API]
        NetworkError[网络错误]
    end
    
    subgraph UILayer["UI层"]
        ShowData[显示数据]
        ShowError[显示错误]
        ShowCached[显示缓存+提示]
    end
    
    Request --> CheckCache
    
    CheckCache -->|有缓存| ValidCache
    CheckCache -->|无缓存| CheckNetwork
    
    ValidCache -->|有效| ReturnCache
    ValidCache -->|过期| CheckNetwork
    
    ReturnCache --> ShowData
    
    CheckNetwork -->|有网络| FetchRemote
    CheckNetwork -->|无网络| NetworkError
    
    FetchRemote -->|成功| UpdateCache
    FetchRemote -->|失败| NetworkError
    
    UpdateCache --> ShowData
    
    NetworkError -->|有过期缓存| ShowCached
    NetworkError -->|无缓存| ShowError
    
    %% 缓存策略标注
    ValidCache -.TTL: 5分钟.-> ValidCache
    UpdateCache -.推荐列表缓存.-> UpdateCache
    UpdateCache -.内容详情缓存.-> UpdateCache
    
    %% 样式
    classDef cacheStyle fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    classDef networkStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef uiStyle fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    classDef errorStyle fill:#ffcdd2,stroke:#c62828,stroke-width:2px
    
    class CheckCache,ValidCache,ReturnCache,UpdateCache cacheStyle
    class CheckNetwork,FetchRemote networkStyle
    class ShowData,ShowCached uiStyle
    class NetworkError,ShowError errorStyle
```

---

## 8. 响应式UI架构

```mermaid
graph TB
    %% BLoC
    BLoC["RecommendationBloc"]
    
    %% 状态流
    subgraph States["States (Stream)"]
        Initial["Initial"]
        Loading["Loading"]
        Loaded["Loaded"]
        Error["Error"]
    end
    
    %% UI组件
    subgraph UIComponents["UI Components"]
        Builder["BlocBuilder"]
        Listener["BlocListener"]
        Consumer["BlocConsumer"]
    end
    
    %% UI元素
    subgraph UIElements["UI Elements"]
        LoadingIndicator["CircularProgressIndicator"]
        ListView["ListView.builder"]
        ErrorWidget["ErrorWidget"]
        EmptyWidget["EmptyStateWidget"]
    end
    
    %% 用户交互
    UserAction["用户操作"]
    
    %% 流程
    UserAction -->|dispatch event| BLoC
    
    BLoC -->|emit state| Initial
    BLoC -->|emit state| Loading
    BLoC -->|emit state| Loaded
    BLoC -->|emit state| Error
    
    Initial --> Builder
    Loading --> Builder
    Loaded --> Builder
    Error --> Builder
    
    Builder -->|state is Loading| LoadingIndicator
    Builder -->|state is Loaded| ListView
    Builder -->|state is Error| ErrorWidget
    Builder -->|state is Loaded + empty| EmptyWidget
    
    Error --> Listener
    Listener -.show snackbar.-> Listener
    
    %% 样式
    classDef blocStyle fill:#e3f2fd,stroke:#0d47a1,stroke-width:3px
    classDef stateStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef builderStyle fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef widgetStyle fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    
    class BLoC blocStyle
    class Initial,Loading,Loaded,Error stateStyle
    class Builder,Listener,Consumer builderStyle
    class LoadingIndicator,ListView,ErrorWidget,EmptyWidget widgetStyle
```

---

## 9. 国际化架构

```mermaid
graph TB
    %% 应用入口
    App["MaterialApp"]
    
    %% 国际化配置
    subgraph I18nConfig["国际化配置"]
        L10n["l10n.yaml"]
        ARB["*.arb 文件"]
        Generated["生成的代码"]
    end
    
    %% 语言文件
    subgraph Languages["语言文件"]
        EN["app_en.arb<br/>(英文)"]
        ZH["app_zh.arb<br/>(中文)"]
    end
    
    %% 生成的类
    subgraph GeneratedClasses["生成的类"]
        AppLocalizations["AppLocalizations"]
        AppLocalizationsEn["AppLocalizations_en"]
        AppLocalizationsZh["AppLocalizations_zh"]
    end
    
    %% UI组件
    subgraph UIComponents["UI组件"]
        Widget["Widget"]
        Context["BuildContext"]
    end
    
    %% 使用
    Usage["AppLocalizations.of(context)"]
    
    %% 流程
    L10n --> ARB
    ARB --> EN
    ARB --> ZH
    
    EN --> Generated
    ZH --> Generated
    
    Generated --> AppLocalizations
    AppLocalizations --> AppLocalizationsEn
    AppLocalizations --> AppLocalizationsZh
    
    App --> AppLocalizations
    
    Widget --> Context
    Context --> Usage
    Usage --> AppLocalizations
    
    %% 样式
    classDef configStyle fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    classDef langStyle fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    classDef genStyle fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef uiStyle fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    
    class L10n,ARB configStyle
    class EN,ZH langStyle
    class AppLocalizations,AppLocalizationsEn,AppLocalizationsZh genStyle
    class Widget,Context,Usage uiStyle
```

---

## 10. 主题切换架构

```mermaid
stateDiagram-v2
    [*] --> SystemDefault: 应用启动
    
    SystemDefault --> Light: 系统为亮色
    SystemDefault --> Dark: 系统为暗色
    
    Light --> Dark: 用户切换到暗色
    Dark --> Light: 用户切换到亮色
    
    Light --> SystemDefault: 用户选择跟随系统
    Dark --> SystemDefault: 用户选择跟随系统
    
    note right of SystemDefault
        ThemeMode.system
        跟随系统设置
    end note
    
    note right of Light
        ThemeMode.light
        亮色主题
        白色背景
    end note
    
    note right of Dark
        ThemeMode.dark
        暗色主题
        深色背景
    end note
```

---

## 11. 性能优化架构

```mermaid
graph TB
    %% 优化策略
    subgraph Optimization["性能优化策略"]
        direction TB
        
        subgraph ListOptimization["列表优化"]
            ListView["ListView.builder<br/>(按需构建)"]
            Pagination["分页加载"]
            CachedImage["CachedNetworkImage<br/>(图片缓存)"]
        end
        
        subgraph StateOptimization["状态优化"]
            BlocSelector["BlocSelector<br/>(精确重建)"]
            EquatableState["Equatable<br/>(状态比较)"]
            ConstWidget["const Widget<br/>(避免重建)"]
        end
        
        subgraph DataOptimization["数据优化"]
            LocalCache["本地缓存"]
            Debounce["防抖搜索"]
            Prefetch["预加载数据"]
        end
        
        subgraph RenderOptimization["渲染优化"]
            RepaintBoundary["RepaintBoundary<br/>(隔离重绘)"]
            AutomaticKeepAlive["AutomaticKeepAlive<br/>(保持状态)"]
            Lazy["延迟加载"]
        end
    end
    
    %% 性能指标
    subgraph Metrics["性能指标"]
        FPS["60 FPS"]
        LoadTime["加载时间 < 1s"]
        MemoryUsage["内存占用 < 100MB"]
    end
    
    %% 关系
    ListView --> FPS
    BlocSelector --> FPS
    RepaintBoundary --> FPS
    
    LocalCache --> LoadTime
    Prefetch --> LoadTime
    
    CachedImage --> MemoryUsage
    AutomaticKeepAlive --> MemoryUsage
    
    %% 样式
    classDef optStyle fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    classDef metricStyle fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    
    class ListView,Pagination,CachedImage,BlocSelector,EquatableState,ConstWidget,LocalCache,Debounce,Prefetch,RepaintBoundary,AutomaticKeepAlive,Lazy optStyle
    class FPS,LoadTime,MemoryUsage metricStyle
```

---

## 12. 测试架构

```mermaid
graph TB
    %% 测试层次
    subgraph TestLayers["测试层次"]
        direction TB
        
        subgraph UnitTests["单元测试"]
            EntityTest["Entity Tests"]
            UseCaseTest["Use Case Tests"]
            RepoTest["Repository Tests"]
            BlocTest["BLoC Tests"]
        end
        
        subgraph WidgetTests["Widget 测试"]
            PageTest["Page Tests"]
            WidgetTest["Widget Tests"]
            InteractionTest["Interaction Tests"]
        end
        
        subgraph IntegrationTests["集成测试"]
            E2ETest["E2E Tests"]
            FlowTest["User Flow Tests"]
        end
    end
    
    %% Mock工具
    subgraph MockTools["Mock 工具"]
        Mockito["Mockito<br/>(Mock依赖)"]
        BlocTestPkg["bloc_test<br/>(测试BLoC)"]
        HttpMock["http_mock_adapter<br/>(Mock API)"]
    end
    
    %% 测试覆盖率
    Coverage["测试覆盖率<br/>目标: 80%+"]
    
    %% 关系
    Mockito --> UseCaseTest
    Mockito --> RepoTest
    BlocTestPkg --> BlocTest
    HttpMock --> RepoTest
    
    UnitTests --> Coverage
    WidgetTests --> Coverage
    IntegrationTests --> Coverage
    
    %% 样式
    classDef unitStyle fill:#e3f2fd,stroke:#0d47a1,stroke-width:2px
    classDef widgetStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef integrationStyle fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    classDef mockStyle fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef coverageStyle fill:#c8e6c9,stroke:#2e7d32,stroke-width:3px
    
    class EntityTest,UseCaseTest,RepoTest,BlocTest unitStyle
    class PageTest,WidgetTest,InteractionTest widgetStyle
    class E2ETest,FlowTest integrationStyle
    class Mockito,BlocTestPkg,HttpMock mockStyle
    class Coverage coverageStyle
```

---

## 总结

### 架构特点

1. **Clean Architecture**：清晰的分层，依赖方向单一
2. **BLoC 模式**：响应式状态管理，UI 与业务逻辑分离
3. **依赖注入**：使用 get_it + injectable，易于测试
4. **类型安全**：Dart 强类型，编译时错误检查
5. **高性能**：列表优化、缓存策略、精确重建

### SOLID 原则体现

- **SRP**：每个 Use Case 只负责一个业务逻辑
- **OCP**：通过接口定义行为，扩展无需修改现有代码
- **LSP**：Repository 实现可以替换接口
- **ISP**：每个 Repository 接口只定义相关操作
- **DIP**：Use Case 依赖接口，使用依赖注入

### 设计模式应用

- **BLoC 模式**：状态管理
- **Repository 模式**：数据访问抽象
- **Use Case 模式**：业务逻辑封装
- **依赖注入**：get_it + injectable
- **观察者模式**：Stream 响应式编程
