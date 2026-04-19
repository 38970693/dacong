# 测试覆盖率提升计划

## 当前状态
- 测试通过：80 个
- 测试失败：15 个（freezed 代码生成问题）
- 当前覆盖率：38.57%
- 目标覆盖率：80%

## 问题分析
freezed 生成的代码格式有问题（所有属性在一行），导致编译错误。这影响了：
- 所有使用 @freezed 的实体类测试
- 依赖这些实体的 BLoC 测试

## 提升策略

### 阶段 1：补充不依赖 freezed 的测试（预计提升 20%）

#### 1.1 服务层测试
- [ ] `lib/data/services/comment_service.dart`
- [ ] `lib/data/services/community_service.dart`
- [ ] `lib/data/services/notification_service.dart`

#### 1.2 Repository 测试（使用 Mock）
- [ ] `lib/data/repositories/auth_repository.dart`
- [ ] `lib/data/repositories/user_repository_impl.dart`
- [ ] `lib/data/repositories/community_repository.dart`
- [ ] `lib/data/repositories/notification_repository_impl.dart`

#### 1.3 工具类测试
- [ ] `lib/core/utils/date_formatter.dart`
- [ ] `lib/core/utils/validators.dart`
- [ ] `lib/core/network/api_client.dart`
- [ ] `lib/core/cache/cache_manager.dart`

#### 1.4 Widget 测试
- [ ] `lib/presentation/widgets/loading_indicator.dart`
- [ ] `lib/presentation/widgets/error_view.dart`
- [ ] `lib/presentation/widgets/empty_state.dart`
- [ ] `lib/presentation/widgets/custom_button.dart`

### 阶段 2：修复 freezed 问题（预计提升 15%）

两个选择：
1. **升级 freezed 版本**：尝试新版本是否修复了格式问题
2. **替换 freezed**：使用手动实现或其他代码生成工具

### 阶段 3：补充集成测试（预计提升 10%）

- [ ] 用户登录流程测试
- [ ] 内容浏览流程测试
- [ ] 搜索功能测试
- [ ] 评论功能测试

## 立即行动

### 优先级 1：创建 5 个高价值测试文件
1. `test/core/utils/validators_test.dart` - 输入验证测试
2. `test/core/utils/date_formatter_test.dart` - 日期格式化测试
3. `test/presentation/widgets/error_view_test.dart` - 错误视图测试
4. `test/presentation/widgets/empty_state_test.dart` - 空状态测试
5. `test/presentation/widgets/loading_indicator_test.dart` - 加载指示器测试

### 优先级 2：补充 Repository 测试
使用 Mockito 创建 Mock 对象，避免依赖 freezed 实体。

### 优先级 3：解决 freezed 问题
研究 freezed 配置或升级版本。

## 预期结果
- 阶段 1 完成后：覆盖率 ~58%
- 阶段 2 完成后：覆盖率 ~73%
- 阶段 3 完成后：覆盖率 ~83%（达标）

## 时间估算
- 阶段 1：4-6 小时
- 阶段 2：2-3 小时
- 阶段 3：2-3 小时
- **总计：8-12 小时**
