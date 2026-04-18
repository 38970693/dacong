# 大葱项目测试文档

## 测试概览

本文档描述了大葱（DaCong）Flutter 客户端的测试策略和测试覆盖情况。

## 测试文件统计

总测试文件数：**33 个**

### 新增测试文件（本次任务）

1. **BLoC 测试**
   - `test/presentation/blocs/auth/auth_bloc_test.dart` - 认证 BLoC 测试（15+ 测试用例）
   - `test/presentation/blocs/user/user_bloc_test.dart` - 用户 BLoC 测试（20+ 测试用例）

2. **Repository 测试**
   - `test/data/repositories/scenario_repository_test.dart` - 场景仓储测试
   - `test/data/repositories/content_repository_test.dart` - 内容仓储测试（12+ 测试用例）

### 现有测试文件

#### BLoC 测试
- `test/presentation/blocs/comment/comment_bloc_test.dart`
- `test/presentation/blocs/content_detail_bloc_test.dart`
- `test/presentation/blocs/recommendation_bloc_test.dart`
- `test/presentation/blocs/search/search_bloc_test.dart`
- `test/presentation/blocs/weekly_bloc_test.dart`

#### Widget 测试
- `test/presentation/pages/home_page_test.dart`
- `test/presentation/pages/settings/settings_page_test.dart`
- `test/presentation/pages/weekly_page_test.dart`
- `test/presentation/widgets/comment/comment_section_test.dart`
- `test/presentation/widgets/content_header_test.dart`
- `test/presentation/widgets/content_info_test.dart`
- `test/presentation/widgets/pros_cons_list_test.dart`
- `test/presentation/widgets/recommendation_card_test.dart`
- `test/presentation/widgets/scenario_selector_test.dart`

#### Service 测试
- `test/core/analytics/analytics_service_test.dart`
- `test/data/services/search_service_test.dart`

#### Model 测试
- `test/data/models/comment_model_test.dart`
- `test/data/models/user_profile_model_test.dart`

#### 其他测试
- `test/accessibility/accessibility_utils_test.dart`
- `test/core/theme/theme_cubit_test.dart`
- `test/data/datasources/local_data_source_test.dart`

## 测试运行

### 运行所有测试

```bash
cd dacong-client
flutter test
```

### 运行特定测试文件

```bash
flutter test test/presentation/blocs/auth/auth_bloc_test.dart
```

### 生成测试覆盖率报告

```bash
flutter test --coverage
```

覆盖率报告将生成在 `coverage/lcov.info`

### 查看覆盖率报告（需要安装 lcov）

```bash
# 安装 lcov (macOS)
brew install lcov

# 安装 lcov (Ubuntu/Debian)
sudo apt-get install lcov

# 生成 HTML 报告
genhtml coverage/lcov.info -o coverage/html

# 打开报告
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
start coverage/html/index.html  # Windows
```

## 测试策略

### 1. 单元测试（Unit Tests）

**目标覆盖率：80%+**

- **BLoC 测试**：测试业务逻辑层，验证状态转换和事件处理
- **Repository 测试**：测试数据访问层，使用 Mock 隔离外部依赖
- **Service 测试**：测试服务层逻辑
- **Model 测试**：测试数据模型的序列化和转换

### 2. Widget 测试

**目标覆盖率：70%+**

- 测试 UI 组件的渲染
- 测试用户交互（点击、输入等）
- 测试状态变化对 UI 的影响

### 3. 集成测试（Integration Tests）

**目标：覆盖关键用户流程**

- 认证流程（注册 → 登录 → 退出）
- 推荐流程（场景选择 → 推荐列表 → 详情页）
- 收藏流程（添加收藏 → 查看收藏列表）

## 测试工具和依赖

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4      # Mock 框架
  mocktail: ^1.0.3     # 另一个 Mock 框架（更简洁）
  bloc_test: ^10.0.0   # BLoC 测试工具
```

## 测试最佳实践

### 1. AAA 模式

所有测试遵循 AAA 模式：

```dart
test('description', () {
  // Arrange - 准备测试数据和环境
  final repository = MockRepository();
  when(() => repository.getData()).thenAnswer((_) async => testData);
  
  // Act - 执行被测试的操作
  final result = await useCase.execute();
  
  // Assert - 验证结果
  expect(result, equals(expectedResult));
  verify(() => repository.getData()).called(1);
});
```

### 2. 测试命名

测试名称应清晰描述预期行为：

```dart
// 好的命名
test('returns user when login succeeds', () { ... });
test('emits error when network fails', () { ... });

// 不好的命名
test('test login', () { ... });
test('test1', () { ... });
```

### 3. 使用 Mock 隔离依赖

```dart
class MockAuthRepository extends Mock implements IAuthRepository {}

setUp(() {
  mockAuthRepository = MockAuthRepository();
  bloc = AuthBloc(mockAuthRepository);
});
```

### 4. BLoC 测试使用 blocTest

```dart
blocTest<AuthBloc, AuthState>(
  'emits [loading, authenticated] when login succeeds',
  build: () {
    when(() => mockLoginUseCase(email: any, password: any))
        .thenAnswer((_) async => Right(session));
    return bloc;
  },
  act: (bloc) => bloc.add(LoginRequested(email: 'test@example.com', password: 'password')),
  expect: () => [
    AuthState.loading(),
    AuthState.authenticated(user),
  ],
);
```

## 当前测试状态

### 通过的测试

- ✅ 80 个测试通过
- ✅ 核心 BLoC 逻辑已覆盖
- ✅ 主要 Widget 已测试
- ✅ Repository 层已测试

### 已知问题

- ⚠️ 15 个测试失败（主要是 freezed 代码生成问题）
- ⚠️ 部分测试文件存在编译错误，需要修复 freezed 生成的代码

### 待改进项

1. **提高覆盖率**
   - 目标：客户端 80%，管理后台 70%，API 85%
   - 当前：需要运行覆盖率报告确认

2. **修复编译错误**
   - 修复 freezed 代码生成问题
   - 确保所有测试文件可以编译通过

3. **添加集成测试**
   - 创建端到端测试场景
   - 测试完整用户流程

4. **持续集成**
   - 配置 CI/CD 自动运行测试
   - 设置覆盖率门槛

## 测试维护

### 添加新测试

1. 在 `test/` 目录下创建对应的测试文件
2. 遵循现有的测试结构和命名约定
3. 使用 Mock 隔离外部依赖
4. 确保测试独立且可重复运行

### 更新测试

当修改业务逻辑时：

1. 先更新测试用例
2. 运行测试确保失败（TDD 红灯）
3. 修改实现代码
4. 运行测试确保通过（TDD 绿灯）
5. 重构代码（TDD 重构）

## 参考资源

- [Flutter 测试文档](https://docs.flutter.dev/testing)
- [BLoC 测试指南](https://bloclibrary.dev/#/testing)
- [Mockito 文档](https://pub.dev/packages/mockito)
- [Mocktail 文档](https://pub.dev/packages/mocktail)
