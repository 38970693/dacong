# Flutter Clean Architecture - 架构可视化

## 整体架构图

```
┌─────────────────────────────────────────────────────────────────────┐
│                          用户界面 (UI)                               │
│                     Flutter Material Design                          │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
┌────────────────────────────────▼────────────────────────────────────┐
│                      Presentation Layer                              │
│                   (UI + BLoC + Widgets + Pages)                      │
│                                                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │   HomePage   │  │ ContentPage  │  │  SearchPage  │              │
│  │              │  │              │  │              │              │
│  │ - Scenario   │  │ - Detail     │  │ - Search     │              │
│  │   Selector   │  │ - Feedback   │  │ - Filter     │              │
│  │ - Recommend  │  │ - Related    │  │ - History    │              │
│  │   List       │  │              │  │              │              │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘              │
│         │                  │                  │                      │
│         └──────────────────┴──────────────────┘                      │
│                            │                                         │
│                  ┌─────────▼─────────┐                              │
│                  │  RecommendationBloc│                              │
│                  │  ContentBloc      │                              │
│                  │  SearchBloc       │                              │
│                  └─────────┬─────────┘                              │
│                            │ Events/States                           │
└────────────────────────────┼─────────────────────────────────────────┘
                             │
                             │ Use Cases
                             │
┌────────────────────────────▼─────────────────────────────────────────┐
│                         Domain Layer                                  │
│              (Entities + Use Cases + Repository Interfaces)           │
│                                                                        │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                        Entities                              │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │    │
│  │  │   Content    │  │Recommendation│  │   Scenario   │     │    │
│  │  │              │  │              │  │              │     │    │
│  │  │ - id         │  │ - id         │  │ - id         │     │    │
│  │  │ - name       │  │ - toolName   │  │ - name       │     │    │
│  │  │ - vendor     │  │ - description│  │ - description│     │    │
│  │  │ - features   │  │ - pros/cons  │  │ - icon       │     │    │
│  │  │ - priceInfo  │  │ - rating     │  │ - order      │     │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘     │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                        │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                       Use Cases                              │    │
│  │  ┌──────────────────┐  ┌──────────────────┐                │    │
│  │  │GetRecommendations│  │GetContentDetail  │                │    │
│  │  │                  │  │                  │                │    │
│  │  │ call(scenario)   │  │ call(contentId)  │                │    │
│  │  │ → List<Rec>      │  │ → Content        │                │    │
│  │  └──────────────────┘  └──────────────────┘                │    │
│  │                                                               │    │
│  │  ┌──────────────────┐  ┌──────────────────┐                │    │
│  │  │  SearchContent   │  │ SubmitFeedback   │                │    │
│  │  │                  │  │                  │                │    │
│  │  │ call(query)      │  │ call(feedback)   │                │    │
│  │  │ → List<Content>  │  │ → void           │                │    │
│  │  └──────────────────┘  └──────────────────┘                │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                        │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                  Repository Interfaces                       │    │
│  │  ┌──────────────────────────────────────────────────────┐  │    │
│  │  │         IContentRepository                            │  │    │
│  │  │  - getRecommendationsByScenario(scenario)            │  │    │
│  │  │  - getContentById(id)                                │  │    │
│  │  │  - getRelatedContent(id)                             │  │    │
│  │  │  - searchContent(query)                              │  │    │
│  │  └──────────────────────────────────────────────────────┘  │    │
│  └─────────────────────────────────────────────────────────────┘    │
└────────────────────────────┬───────────────────────────────────────┘
                             │
                             │ Repository Implementation
                             │
┌────────────────────────────▼───────────────────────────────────────┐
│                          Data Layer                                 │
│         (Models + Repository Impl + Data Sources + Network)         │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │                Repository Implementations                   │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │      ContentRepositoryImpl                            │ │   │
│  │  │                                                        │ │   │
│  │  │  implements IContentRepository                        │ │   │
│  │  │                                                        │ │   │
│  │  │  - RemoteDataSource _remoteDataSource                │ │   │
│  │  │                                                        │ │   │
│  │  │  getRecommendationsByScenario(scenario) {            │ │   │
│  │  │    try {                                              │ │   │
│  │  │      models = await _remoteDataSource.get...()       │ │   │
│  │  │      entities = models.map(m => m.toEntity())        │ │   │
│  │  │      return Right(entities)                          │ │   │
│  │  │    } on ServerException catch (e) {                  │ │   │
│  │  │      return Left(ServerFailure(e.message))           │ │   │
│  │  │    }                                                  │ │   │
│  │  │  }                                                    │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │                      Data Sources                           │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │         RemoteDataSource (Supabase)                   │ │   │
│  │  │                                                        │ │   │
│  │  │  - SupabaseClient _client                            │ │   │
│  │  │                                                        │ │   │
│  │  │  getRecommendationsByScenario(scenario) async {      │ │   │
│  │  │    final response = await _client                    │ │   │
│  │  │      .from('scenario_recommendations')               │ │   │
│  │  │      .select('*')                                     │ │   │
│  │  │      .eq('scenario', scenario)                       │ │   │
│  │  │      .order('rank');                                 │ │   │
│  │  │    return response.map(RecommendationModel.fromJson) │ │   │
│  │  │  }                                                    │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │                         Models                              │   │
│  │  ┌──────────────────────────────────────────────────────┐ │   │
│  │  │      RecommendationModel extends Recommendation       │ │   │
│  │  │                                                        │ │   │
│  │  │  @freezed                                             │ │   │
│  │  │  factory RecommendationModel.fromJson(json)          │ │   │
│  │  │  Recommendation toEntity() => Recommendation(...)    │ │   │
│  │  └──────────────────────────────────────────────────────┘ │   │
│  └────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

## 数据流图

```
┌─────────────┐
│    User     │
│   Action    │
└──────┬──────┘
       │ 1. 用户点击"写代码"场景
       ▼
┌─────────────────────────────┐
│  ScenarioSelector Widget    │
│  onScenarioSelected('coding')│
└──────┬──────────────────────┘
       │ 2. 触发回调
       ▼
┌─────────────────────────────┐
│    HomePage State           │
│  context.read<Bloc>().add() │
└──────┬──────────────────────┘
       │ 3. 发送事件
       ▼
┌─────────────────────────────┐
│   RecommendationBloc        │
│  LoadRecommendations Event  │
└──────┬──────────────────────┘
       │ 4. 调用 Use Case
       ▼
┌─────────────────────────────┐
│   GetRecommendations        │
│  call('coding')             │
└──────┬──────────────────────┘
       │ 5. 调用 Repository
       ▼
┌─────────────────────────────┐
│  IContentRepository         │
│  (Interface)                │
└──────┬──────────────────────┘
       │ 6. 实现调用
       ▼
┌─────────────────────────────┐
│  ContentRepositoryImpl      │
│  getRecommendations...()    │
└──────┬──────────────────────┘
       │ 7. 调用数据源
       ▼
┌─────────────────────────────┐
│   RemoteDataSource          │
│  Supabase Query             │
└──────┬──────────────────────┘
       │ 8. 返回 JSON
       ▼
┌─────────────────────────────┐
│  RecommendationModel        │
│  fromJson() → toEntity()    │
└──────┬──────────────────────┘
       │ 9. 返回 Entity
       ▼
┌─────────────────────────────┐
│  Either<Failure, List<Rec>> │
│  Right(recommendations)     │
└──────┬──────────────────────┘
       │ 10. 返回结果
       ▼
┌─────────────────────────────┐
│   RecommendationBloc        │
│  emit(RecommendationLoaded) │
└──────┬──────────────────────┘
       │ 11. 发送状态
       ▼
┌─────────────────────────────┐
│    BlocBuilder              │
│  builder: (context, state)  │
└──────┬──────────────────────┘
       │ 12. 重建 UI
       ▼
┌─────────────────────────────┐
│   ListView.builder          │
│  RecommendationCard(...)    │
└─────────────────────────────┘
       │ 13. 显示推荐列表
       ▼
┌─────────────┐
│    User     │
│   Sees UI   │
└─────────────┘
```

## 依赖注入图

```
┌─────────────────────────────────────────────────────────┐
│                    get_it Container                      │
│                  (Service Locator)                       │
└────────────────────────┬────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  Use Cases  │  │Repositories │  │Data Sources │
│             │  │             │  │             │
│ @injectable │  │@LazySingleton│ │@lazySingleton│
└─────────────┘  └─────────────┘  └─────────────┘
         │               │               │
         │               │               │
         ▼               ▼               ▼
┌─────────────────────────────────────────────────────────┐
│              Dependency Graph                            │
│                                                           │
│  RecommendationBloc                                      │
│    ↓ depends on                                          │
│  GetRecommendations                                      │
│    ↓ depends on                                          │
│  IContentRepository (interface)                          │
│    ↓ implemented by                                      │
│  ContentRepositoryImpl                                   │
│    ↓ depends on                                          │
│  RemoteDataSource                                        │
│    ↓ depends on                                          │
│  SupabaseClient                                          │
└─────────────────────────────────────────────────────────┘
```

## 错误处理流程

```
┌─────────────────────────────────────────────────────────┐
│                  Error Handling Flow                     │
└─────────────────────────────────────────────────────────┘

Data Source Layer:
┌─────────────────────────────────────────────────────────┐
│  try {                                                   │
│    final response = await _client.from('table').select()│
│    return models;                                        │
│  } catch (e) {                                           │
│    throw ServerException('Error: $e');                   │
│  }                                                       │
└────────────────────────┬────────────────────────────────┘
                         │ throws Exception
                         ▼
Repository Layer:
┌─────────────────────────────────────────────────────────┐
│  try {                                                   │
│    final models = await _dataSource.get();              │
│    return Right(models.map(m => m.toEntity()));         │
│  } on ServerException catch (e) {                       │
│    return Left(ServerFailure(e.message));               │
│  } on NetworkException catch (e) {                      │
│    return Left(NetworkFailure(e.message));              │
│  }                                                       │
└────────────────────────┬────────────────────────────────┘
                         │ returns Either<Failure, Success>
                         ▼
Use Case Layer:
┌─────────────────────────────────────────────────────────┐
│  Future<Either<Failure, List<Rec>>> call(String s) {   │
│    return _repository.getRecommendations(s);            │
│  }                                                       │
└────────────────────────┬────────────────────────────────┘
                         │ returns Either
                         ▼
BLoC Layer:
┌─────────────────────────────────────────────────────────┐
│  final result = await _useCase(scenario);               │
│  result.fold(                                            │
│    (failure) => emit(Error(failure.message)),           │
│    (data) => emit(Loaded(data)),                        │
│  );                                                      │
└────────────────────────┬────────────────────────────────┘
                         │ emits State
                         ▼
UI Layer:
┌─────────────────────────────────────────────────────────┐
│  BlocBuilder<Bloc, State>(                              │
│    builder: (context, state) {                          │
│      if (state is Error) {                              │
│        return ErrorWidget(state.message);               │
│      }                                                   │
│      // ...                                             │
│    }                                                     │
│  )                                                       │
└─────────────────────────────────────────────────────────┘
```

## 文件依赖关系

```
main.dart
  ├─> injection.dart (DI配置)
  │     ├─> @injectable Use Cases
  │     ├─> @LazySingleton Repositories
  │     └─> @lazySingleton Data Sources
  │
  ├─> HomePage
  │     ├─> ScenarioSelector (Widget)
  │     ├─> RecommendationCard (Widget)
  │     └─> RecommendationBloc
  │           └─> GetRecommendations (Use Case)
  │                 └─> IContentRepository (Interface)
  │                       └─> ContentRepositoryImpl
  │                             └─> RemoteDataSource
  │                                   └─> SupabaseClient
  │
  └─> GoRouter
        ├─> HomePage (/)
        ├─> ContentDetailPage (/content/:id)
        └─> SearchPage (/search)
```

---

**说明**:
- 实线箭头 (→) 表示依赖关系
- 虚线箭头 (⇢) 表示数据流
- 方框表示组件/类
- 圆角方框表示层次
