# Flutter Clean Architecture - DaCong Client

## 架构概览

本项目采用 **Clean Architecture + BLoC** 模式，严格遵循 SOLID 原则，实现了高度解耦、可测试、可维护的代码结构。

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│              (UI + BLoC + Widgets + Pages)                   │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   HomePage   │  │ ContentPage  │  │  SearchPage  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
│                          │                                   │
│                    ┌─────▼─────┐                            │
│                    │   BLoC    │                            │
│                    └─────┬─────┘                            │
└──────────────────────────┼──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                     Domain Layer                             │
│         (Entities + Use Cases + Repository Interfaces)       │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Entities   │  │  Use Cases   │  │ Repositories │      │
│  │  (Immutable) │  │ (Business    │  │ (Interfaces) │      │
│  │              │  │   Logic)     │  │              │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                      Data Layer                              │
│    (Models + Repository Impl + Data Sources + Network)       │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │    Models    │  │ Repositories │  │ Data Sources │      │
│  │ (Serializable│  │     Impl     │  │ (Remote/     │      │
│  │   Entities)  │  │              │  │  Local)      │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└───────────────────────────────────────────────────────────────┘
```

## SOLID 原则应用

### 1. 单一职责原则 (SRP)
每个类只负责一个职责：
- **Use Case**: 只负责一个业务逻辑（如 `GetRecommendations`）
- **Repository**: 只负责数据访问
- **BLoC**: 只负责状态管理
- **Widget**: 只负责 UI 展示

### 2. 开闭原则 (OCP)
对扩展开放，对修改关闭：
- 通过接口定义行为（`IContentRepository`）
- 新增数据源无需修改现有代码
- 新增 Use Case 不影响其他业务逻辑

### 3. 里氏替换原则 (LSP)
子类可以替换父类：
- `ContentRepositoryImpl` 实现 `IContentRepository`
- 任何实现了接口的类都可以替换使用

### 4. 接口隔离原则 (ISP)
接口应该小而专注：
- `IContentRepository`: 只定义内容相关操作
- `IFeedbackRepository`: 只定义反馈相关操作
- `IScenarioRepository`: 只定义场景相关操作

### 5. 依赖倒置原则 (DIP)
依赖抽象而非具体实现：
- Use Case 依赖 Repository 接口，不依赖具体实现
- BLoC 依赖 Use Case，不直接访问数据层
- 使用依赖注入（get_it + injectable）

## 目录结构

```
lib/
├── core/                           # 核心层
│   ├── domain/                     # 领域层
│   │   ├── entities/               # 领域实体（不可变）
│   │   │   ├── content.dart        # 内容实体
│   │   │   ├── recommendation.dart # 推荐实体
│   │   │   ├── scenario.dart       # 场景实体
│   │   │   └── feedback.dart       # 反馈实体
│   │   ├── repositories/           # 仓储接口
│   │   │   ├── i_content_repository.dart
│   │   │   ├── i_feedback_repository.dart
│   │   │   └── i_scenario_repository.dart
│   │   └── usecases/               # 用例（业务逻辑）
│   │       ├── get_recommendations.dart
│   │       ├── get_content_detail.dart
│   │       ├── search_content.dart
│   │       ├── submit_feedback.dart
│   │       └── get_all_scenarios.dart
│   ├── error/                      # 错误处理
│   │   ├── exceptions.dart         # 异常定义
│   │   └── failures.dart           # 失败类型
│   ├── network/                    # 网络层
│   │   └── api_client.dart         # HTTP 客户端
│   └── di/                         # 依赖注入
│       └── injection.dart          # DI 配置
│
├── data/                           # 数据层
│   ├── models/                     # 数据模型（可序列化）
│   │   ├── content_model.dart
│   │   ├── recommendation_model.dart
│   │   └── scenario_model.dart
│   ├── repositories/               # 仓储实现
│   │   └── content_repository_impl.dart
│   └── datasources/                # 数据源
│       └── remote_data_source.dart # 远程数据源（Supabase）
│
├── presentation/                   # 表现层
│   ├── blocs/                      # BLoC 状态管理
│   │   └── recommendation/
│   │       ├── recommendation_bloc.dart
│   │       ├── recommendation_event.dart
│   │       └── recommendation_state.dart
│   ├── pages/                      # 页面
│   │   └── home/
│   │       └── home_page.dart      # 首页
│   └── widgets/                    # 可复用组件
│       ├── recommendation_card.dart
│       └── scenario_selector.dart
│
└── main.dart                       # 应用入口
```

## 核心概念

### 1. Entity（实体）
不可变的业务对象，使用 `freezed` 生成：

```dart
@freezed
class Content with _$Content {
  const factory Content({
    required String id,
    required String name,
    // ...
  }) = _Content;
}
```

### 2. Use Case（用例）
封装单一业务逻辑：

```dart
@injectable
class GetRecommendations {
  final IContentRepository _repository;

  GetRecommendations(this._repository);

  Future<Either<Failure, List<Recommendation>>> call(String scenario) {
    return _repository.getRecommendationsByScenario(scenario);
  }
}
```

### 3. Repository（仓储）
数据访问抽象层：

```dart
abstract class IContentRepository {
  Future<Either<Failure, List<Recommendation>>> getRecommendationsByScenario(String scenario);
}
```

### 4. BLoC（业务逻辑组件）
状态管理：

```dart
@injectable
class RecommendationBloc extends Bloc<RecommendationEvent, RecommendationState> {
  final GetRecommendations _getRecommendations;

  RecommendationBloc(this._getRecommendations) : super(RecommendationInitial()) {
    on<LoadRecommendations>(_onLoadRecommendations);
  }
}
```

## 数据流

```
User Action (UI)
    ↓
Event (BLoC)
    ↓
Use Case (Domain)
    ↓
Repository Interface (Domain)
    ↓
Repository Implementation (Data)
    ↓
Data Source (Remote/Local)
    ↓
Model → Entity
    ↓
State (BLoC)
    ↓
UI Update
```

## 错误处理

使用 `Either<Failure, Success>` 处理结果：

```dart
final result = await _getRecommendations(scenario);

result.fold(
  (failure) => emit(RecommendationError(failure.message)),
  (recommendations) => emit(RecommendationLoaded(recommendations)),
);
```

## 依赖注入

使用 `get_it` + `injectable`：

```dart
// 注册
@injectable
class GetRecommendations { ... }

// 使用
final useCase = getIt<GetRecommendations>();
```

## 测试策略

### 1. Unit Tests（单元测试）
- Domain Layer: 测试 Use Cases
- Data Layer: 测试 Repository 实现

### 2. Widget Tests（组件测试）
- Presentation Layer: 测试 UI 组件

### 3. Integration Tests（集成测试）
- 测试完整用户流程

## 开发流程

### 1. 安装依赖
```bash
cd dacong-client
flutter pub get
```

### 2. 生成代码
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. 运行应用
```bash
flutter run
```

### 4. 运行测试
```bash
flutter test
```

## 技术栈

- **Flutter**: 3.3.0+
- **State Management**: flutter_bloc 8.1.3
- **Dependency Injection**: get_it 7.6.4 + injectable 2.3.2
- **Functional Programming**: dartz 0.10.1
- **Code Generation**: freezed 2.4.6 + json_serializable 6.7.1
- **Network**: dio 5.4.0 + supabase_flutter 2.5.0
- **Routing**: go_router 14.0.0

## 最佳实践

1. **不可变性**: 所有实体使用 `freezed` 确保不可变
2. **错误处理**: 使用 `Either` 类型处理错误
3. **依赖注入**: 所有依赖通过构造函数注入
4. **单一职责**: 每个类只负责一个职责
5. **接口隔离**: 接口小而专注
6. **测试优先**: 编写可测试的代码

## 扩展指南

### 添加新功能

1. **Domain Layer**: 定义 Entity、Repository Interface、Use Case
2. **Data Layer**: 实现 Model、Repository Implementation
3. **Presentation Layer**: 实现 BLoC、Page、Widget

### 添加新数据源

1. 创建新的 Data Source 类
2. 在 Repository Implementation 中使用
3. 无需修改 Domain Layer

## 参考资料

- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter BLoC Pattern](https://bloclibrary.dev/)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
