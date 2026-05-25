# Code Review Plan: dacong 近期变更

**计划文件:** `.omc/plans/code-review-plan.md`
**审查范围:** 37 个文件, +511/-427 行
**创建日期:** 2026/05/08

---

## RALPLAN-DR 结构摘要

### 指导原则 (Principles)

| # | 原则 | 说明 |
|---|------|------|
| P1 | **变更可追溯** | 每个文件改动都能追踪到具体动机和影响范围 |
| P2 | **安全无死角** | 认证、API、敏感数据处理必须严格审查 |
| P3 | **行为一致性** | Flutter/Dart 与 Next.js/React 的 API 迁移不应破坏现有功能 |
| P4 | **错误恢复健壮** | 所有新增的错误状态有对应的 UI 展示和用户引导 |
| P5 | **性能无退化** | 新增的 useCallback、withValues 等优化不得引入内存泄漏或性能回退 |

### 核心决策驱动 (Decision Drivers)

| 优先级 | 驱动因素 | 权重理由 |
|--------|----------|----------|
| D1 | **认证安全性** - emailNotVerified、emailRateLimit 新状态的处理逻辑 | 涉及用户注册/登录流程的核心安全路径 |
| D2 | **API 迁移完整性** - withOpacity -> withValues 的覆盖度 | 25 个文件涉及此迁移，任何遗漏都会导致运行时错误 |
| D3 | **错误上报链路的可靠性** - SentryConfig + PerformanceMonitor | 新增的 NoOpSentrySpan 和性能追踪需要验证在非初始化状态下不崩溃 |

### 审查方案对比 (Options)

#### 方案 A: 按技术栈分组建模 + 垂直切片审查 (推荐)

**思路:** 按 Flutter/Dart 和 Next.js/React 两条主线分组建模，每个模块内部按"变更动机 -> 代码检查 -> 集成验证"垂直切片。

| 优势 | 劣势 |
|------|------|
| 并行度高，两组可独立推进 | 需要跨组协调某些共享变更（如 auth_failure.dart 被双方引用） |
| 符合团队成员的技术栈分工 | - |
| 每个切片有明确的边界，审查员易于判断"完成" | - |

#### 方案 B: 按变更风险等级排序审查

**思路:** 先审查高风险（认证、API 路由、安全敏感），再审查中风险（UI 迁移、组件重构），最后审查低风险（测试文件）。

| 优势 | 劣势 |
|------|------|
| 优先保障核心路径安全 | 部分文件的审查结论依赖于共享类型（如 AuthFailure）的最终结果 |
| 高风险变更的问题可被早期发现 | 低风险变更可能被高风险审查的讨论淹没 |

> **决策:** 采用方案 A，但在共享类型（auth_failure.dart）上建立依赖屏障——该文件必须先于两条主线审查完成。

---

## ADR (Architecture Decision Record)

| 字段 | 内容 |
|------|------|
| **Decision** | 采用方案 A（按技术栈分组建模 + 垂直切片审查） |
| **Drivers** | 并行效率高、符合技术栈分工、边界清晰 |
| **Alternatives considered** | 方案 B（按风险等级排序）—— 劣势在于共享类型的审查依赖问题 |
| **Why chosen** | 本次变更多为局部修改（UI 迁移、状态扩展），跨文件影响有限，适合并行建模 |
| **Consequences** | 需要建立共享类型（auth_failure.dart, sentry_config.dart）的审查屏障，作为两条主线的输入 |
| **Follow-ups** | 审查完成后需确认：(1) withValues 迁移 100% 覆盖；(2) emailNotVerified 在 BLoC 和 UI 层都有对应处理 |

---

## 审查模块详细计划

### 模块 1: SentryConfig 改进

**文件:**
- `dacong-client/lib/core/config/sentry_config.dart`
- `dacong-client/lib/core/error/error_boundary.dart`
- `dacong-client/lib/core/performance/performance_monitor.dart`

**变更内容:**
1. 新增 `isInitialized` 静态 getter
2. 新增 `NoOpSentrySpan` 类及 `NoOpSentrySpanExtension` 扩展
3. `startTransaction()` 在未初始化时返回 `NoOpSentrySpan` 而非 null
4. 所有公开方法增加 `if (!_initialized) return` 守卫
5. `ErrorBoundary` 使用 `SentryConfig.captureException` 替代直接调用 Sentry
6. `PerformanceMonitor` 通过 `SentryConfig.startTransaction()` 上报性能数据

**审查要点:**

| 检查项 | 验证方法 | 预期结果 |
|--------|----------|----------|
| NoOpSentrySpan.noSuchMethod 返回 null | 静态分析：所有调用链不依赖返回值进行条件判断 | 不崩溃 |
| startTransaction 返回值链 | 检查所有调用 `startTransaction` 的地方是否处理了 NoOpSentrySpan | 不会因为返回值是 NoOpSentrySpan 而报错 |
| _initialized 状态一致性 | 检查 init 路径和所有设置方法 | 只在 SentryFlutter.init 成功后设为 true |
| ErrorBoundary.initState 中 FlutterError.onError 覆盖 | 检查是否在 dispose 时恢复原始 handler | 避免内存泄漏 |
| PerformanceMonitor._reportToSentry 在未初始化时的行为 | 查看第 182 行 `if (!SentryConfig.isInitialized) return;` | 不上报但不掉用 Sentry API |
| beforeSend 过滤 password/token/api_key | 检查 Map 类型的 data 是否被正确处理 | 敏感信息不上报 |
| 释放版本号硬编码 | 检查 `options.release = 'dacong-client@0.1.0'` | 应改为动态获取或环境变量 |

**风险点:**
- `NoOpSentrySpan` 使用 `noSuchMethod` 转发所有调用返回 null，可能在链式调用（如 `transaction.finish()`）时静默失败而不报错。**需要验证** `transaction.finish()` 在 NoOpSentrySpan 上调用时确实无副作用。

**审查员/检查器:** code-reviewer (opus) + security-reviewer (sonnet)

---

### 模块 2: 认证失败状态扩展

**文件:**
- `dacong-client/lib/core/error/auth_failure.dart`
- `dacong-client/lib/data/datasources/supabase_auth_data_source.dart`
- `dacong-client/lib/presentation/blocs/auth/auth_state.dart`
- `dacong-client/lib/presentation/blocs/auth/auth_bloc.dart`
- `dacong-client/lib/presentation/pages/auth/login_page.dart`

**变更内容:**
1. `auth_failure.dart` 新增 `emailNotVerified()` 和 `emailRateLimit()` 两个 freezed 联合类型
2. `supabase_auth_data_source.dart` 的 `_mapAuthException` 方法新增对 statusCode 422、429、rate limit 的处理
3. `auth_state.dart` 新增 `_EmailNotVerified` 状态
4. `auth_bloc.dart` 的 `_onEvent` 中对 `emailNotVerified` failure 特殊处理（emit `AuthState.emailNotVerified()`）
5. `login_page.dart` 新增 `_buildEmailNotVerifiedView` 方法展示邮箱验证提示 UI

**审查要点:**

| 检查项 | 验证方法 | 预期结果 |
|--------|----------|----------|
| 邮箱未验证判断逻辑 | 查看 `_mapAuthException` 中 `email not confirmed` 和 statusCode 422 的判断 | 正确映射到 emailNotVerified |
| 频率限制判断逻辑 | 查看 `_mapAuthException` 中 rate limit 相关判断 | 正确映射到 emailRateLimit |
| BLoC 中的 failure 类型匹配 | 查看 `failure is AuthFailure` 和 `failure.maybeWhen` 调用 | 所有 AuthFailure 子类型都有处理分支 |
| UI 层 emailNotVerified 状态渲染 | 查看 `maybeWhen(emailNotVerified: ...)` 分支 | 有对应的 View 组件 |
| emailRateLimit 的 UI 展示 | 在 login_page.dart 中搜索 "rateLimit" 或 "频率" | 有用户友好的提示 |
| 注册流程的 emailNotVerified 处理 | 查看 registerRequested 是否也处理了 emailNotVerified | 注册后也需要邮箱验证提示 |
| registerRequested 中的 session 语义 | 注册成功后返回 AuthSession 但用户未验证邮箱 | 检查是否允许未验证用户进入 authenticated 状态 |

**关键风险 - 注册流程语义问题:**

查看 `auth_bloc.dart` 第 72-82 行：
```dart
registerRequested: (email, password, username) async {
  emit(const AuthState.loading());
  final result = await _registerUseCase(...);
  result.fold(
    (failure) => emit(AuthState.error(_mapFailureToMessage(failure))),
    (session) => emit(AuthState.authenticated(session.user)),  // <-- 问题：注册后直接 authenticated
  );
},
```

**问题:** Supabase 注册成功后返回 session，但此时邮箱尚未验证。如果直接 emit `authenticated`，未验证邮箱的用户可以正常登录。**需要确认**这个行为是否符合预期，或者应该 emit `emailNotVerified` 状态。

**审查员/检查器:** code-reviewer (opus) + security-reviewer (sonnet) + tdd-guide (sonnet)

---

### 模块 3: Flutter withOpacity -> withValues API 迁移

**文件 (25 个文件):**

涉及 widget 文件：
- `dacong-client/lib/presentation/widgets/cards/news_card.dart`
- `dacong-client/lib/presentation/widgets/cards/model_card.dart`
- `dacong-client/lib/presentation/widgets/content_card.dart`
- `dacong-client/lib/presentation/widgets/content_detail/alternatives_list.dart`
- `dacong-client/lib/presentation/widgets/content_detail/content_header.dart`
- `dacong-client/lib/presentation/widgets/content_detail/feedback_section.dart`
- `dacong-client/lib/presentation/widgets/comment/comment_input.dart`
- `dacong-client/lib/presentation/pages/news/news_page.dart`
- `dacong-client/lib/presentation/pages/community/community_page.dart`
- `dacong-client/lib/presentation/pages/empower/empower_page.dart`
- `dacong-client/lib/presentation/pages/notifications/notifications_page.dart`
- `dacong-client/lib/presentation/pages/weekly/weekly_page.dart`
- `dacong-client/lib/presentation/pages/user/user_center_page.dart`
- `dacong-client/lib/presentation/pages/user/settings_page.dart`
- `dacong-client/lib/presentation/widgets/recommendation_card.dart`
- `dacong-client/lib/presentation/widgets/loading_animations.dart`
- `dacong-client/lib/presentation/widgets/accessible_content_card.dart`
- `dacong-client/lib/presentation/widgets/accessible_recommendation_card.dart`
- `dacong-client/lib/presentation/pages/user/favorites_page.dart`
- `dacong-client/lib/core/utils/toast_helper.dart`
- `dacong-client/lib/core/accessibility/focus_manager.dart`
- `dacong-client/scripts/check_contrast.dart`

admin 相关文件：
- `dacong-admin/lib/widgets/batch_selection_widget.dart`
- `dacong-admin/lib/pages/dashboard_page.dart`
- `dacong-admin/lib/widgets/charts/pie_chart.dart`
- `dacong-admin/lib/widgets/charts/bar_chart.dart`
- `dacong-admin/lib/widgets/charts/line_chart.dart`

**变更内容:**
`Color.withOpacity(value)` → `Color.withValues(alpha: value)`

**审查要点:**

| 检查项 | 验证方法 | 预期结果 |
|--------|----------|----------|
| 迁移覆盖度 | 全文搜索 `withOpacity` | 零结果（已完全迁移） |
| 参数正确性 | 随机抽查 10 个文件，确认 `withValues(alpha: X)` 而非 `withValues( alpha: X)` 或其他参数名 | alpha 参数正确 |
| 语义等价性 | 对比迁移前后的 alpha 值 | 0.05 → alpha: 0.05, 0.1 → alpha: 0.1 等语义一致 |
| 类型安全性 | 确认 withValues 的 alpha 参数类型是 double | 编译器类型检查通过 |
| 潜在运行时问题 | 检查是否有链式调用如 `color.withOpacity(0.5).withOpacity(0.3)` 的情况 | 确认没有破坏性的嵌套调用 |

**抽样策略:** 由于文件数量多（25 个），采用分层抽样：
- 抽取 3 个代表性 widget 文件进行完整审查（news_card, model_card, feedback_section）
- 抽查 5 个 page 文件的边界情况
- 其余文件进行 `withOpacity` 零残留验证

**审查员/检查器:** code-reviewer (opus) — 重点验证迁移的完整性和正确性

---

### 模块 4: Next.js API 路由和组件改进

**文件:**
- `dacong-console/src/app/api/models/route.ts`
- `dacong-console/src/app/api/search/route.ts`
- `dacong-console/src/app/api/test/route.ts`
- `dacong-console/src/app/api/tags/route.ts`
- `dacong-console/src/app/debug/page.tsx`
- `dacong-console/src/components/TagCloud.tsx`

**变更内容:**
1. `debug/page.tsx` 新增 ErrorBoundary 组件、`useCallback` 优化的 `addDebug`、requestAnimationFrame 防抖、cancelled flag 防内存泄漏
2. `tags/route.ts` 新增 POST 方法（创建标签）、slug 生成函数、颜色预设、重复检测
3. `models/route.ts`、`search/route.ts`、`test/route.ts` 的错误处理改进

**审查要点:**

| 检查项 | 验证方法 | 预期结果 |
|--------|----------|----------|
| debug/page.tsx 的 useCallback 依赖 | 查看第 50-54 行 addDebug 的 deps | 只包含 [] 或稳定引用 |
| requestAnimationFrame 防抖 | 查看第 57-64 行 useEffect | 正确清理 timerId |
| cancelled flag 防内存泄漏 | 查看第 67 行和第 86、99、104 行 | 在 async 函数和 finally 中正确使用 |
| ErrorBoundary 恢复机制 | 查看 ErrorBoundary 的生命周期 | 有 getDerivedStateFromError 和正确的 state 初始化 |
| tags/route.ts 的输入验证 | 查看 POST 方法中的 name 验证 | trim 后长度检查，且类型验证为 string |
| tags/route.ts 的 slug 唯一性检查 | 查看第 63-74 行 | 先查询再插入，防止重复 |
| tags/route.ts slug 生成函数 | 查看第 10-16 行 | 中文保留，非字母数字转横线 |
| API 路由的一致性错误格式 | 查看所有 route.ts 的 catch 块 | 都返回 `{ success: false, error: '...' }` |
| console.log 残留 | 全文搜索所有 console.log | debug/page.tsx 允许 debug 日志，其他 route.ts 应无 console.log |

**风险点:**
- `debug/page.tsx` 中有多处 `console.log`（第 53 行）和 `addDebug` 输出。需要确认这些是否应该在生产环境保留或移除。
- tags/route.ts 的 slug 生成函数中 `[一-龥]` 是 Unicode 范围，兼容性需验证（Node.js 版本要求）。

**审查员/检查器:** code-reviewer (opus) + security-reviewer (sonnet)

---

### 模块 5: dacong-admin 测试文件

**文件:**
- `dacong-admin/test/widget_test.dart`
- `dacong-admin/test/widgets/charts/line_chart_test.dart`

**审查要点:**

| 检查项 | 验证方法 | 预期结果 |
|--------|----------|----------|
| 测试文件语法正确性 | 运行 `flutter test` | 无编译错误 |
| widget_test.dart 的测试目标 | 查看文件内容 | 测试的是有意义的 widget 而非占位符 |
| line_chart_test.dart 的测试覆盖 | 查看测试用例数量和覆盖的代码路径 | 有基本的渲染和交互测试 |
| 测试隔离性 | 检查是否有 mock 依赖 | 不依赖真实网络或数据库 |

**审查员/检查器:** code-reviewer (opus) — 主要确保测试文件可以正常编译运行

---

## 审查流程

```
阶段 1: 共享类型审查屏障
  └─ auth_failure.dart + sentry_config.dart (模块 1 & 2)
       ↓ 完成后解锁

阶段 2: 并行审查 (两条主线)
  ├─ Flutter/Dart 线 (模块 1 延续 + 模块 2 + 模块 3)
  └─ Next.js/React 线 (模块 4)
       ↓ 完成后汇总

阶段 3: 跨栈验证
  └─ 模块 5 (测试文件) + 集成验证

阶段 4: 审查报告输出
  └─ 汇总所有问题，按严重程度分级 (CRITICAL/HIGH/MEDIUM/LOW)
```

---

## 验收标准 (Acceptance Criteria)

以下条件**全部满足**时，审查视为"通过"：

| # | 验收标准 | 验证方法 |
|---|----------|----------|
| AC1 | `withOpacity` 在 Flutter 代码中零残留 | `grep -r "withOpacity" dacong-client/` 无结果 |
| AC2 | `emailNotVerified` 状态在 BLoC 和 UI 层都有处理路径 | 代码审查确认两条路径存在 |
| AC3 | `NoOpSentrySpan` 不引发运行时异常 | 静态分析 + 关键路径手动追踪 |
| AC4 | 所有 API 路由返回一致的错误格式 `{ success, error }` | 抽样验证 3 个 route.ts 文件 |
| AC5 | tags/route.ts 的 slug 生成和唯一性检查逻辑正确 | 代码审查 + 边界测试 |
| AC6 | debug/page.tsx 的 useCallback 依赖数组正确 | 代码审查依赖链 |
| AC7 | 注册流程的邮箱验证语义已明确（authenticated vs emailNotVerified） | 决策文档化，如需修改则列入后续任务 |
| AC8 | 无硬编码敏感信息（密钥、DSN 模式除外） | 审查所有新增代码 |
| AC9 | `dacong-admin/test/` 可正常编译运行 | `flutter test` 无错误 |
| AC10 | 所有 CRITICAL 和 HIGH 问题已修复或已建立后续任务 | 审查报告确认 |

---

## 潜在问题清单 (Pre-mortem)

### 场景 1: withValues 迁移不完整
**触发条件:** 存在 `withOpacity` 遗漏导致运行时错误
**影响范围:** 涉及 UI 渲染的所有页面
**缓解措施:** 全局搜索验证 + Flutter analyze 检查

### 场景 2: 注册流程未验证邮箱的用户进入 authenticated 状态
**触发条件:** 用户注册后绕过邮箱验证直接访问受保护路由
**影响范围:** 认证安全性
**缓解措施:** 明确决策并修复，或添加 middleware 守卫

### 场景 3: Sentry 未初始化时性能监控静默失败
**触发条件:** NoOpSentrySpan 的链式调用（如 finish()）返回 null 但调用方未检查
**影响范围:** 性能数据丢失，但不影响用户体验
**缓解措施:** 验证 NoOpSentrySpan 的所有方法都是安全的（返回 this 或 null）

---

## 待审查文件清单

### 高优先级 (核心认证与安全)
- [ ] `dacong-client/lib/core/config/sentry_config.dart`
- [ ] `dacong-client/lib/core/error/auth_failure.dart`
- [ ] `dacong-client/lib/data/datasources/supabase_auth_data_source.dart`
- [ ] `dacong-client/lib/presentation/blocs/auth/auth_bloc.dart`
- [ ] `dacong-client/lib/presentation/blocs/auth/auth_state.dart`
- [ ] `dacong-client/lib/presentation/pages/auth/login_page.dart`

### 高优先级 (Flutter withValues 迁移)
- [ ] `dacong-client/lib/presentation/widgets/content_detail/feedback_section.dart`
- [ ] `dacong-client/lib/presentation/widgets/comment/comment_input.dart`
- [ ] 其余 23 个涉及 withValues 的文件（分层抽样验证）

### 中优先级 (Next.js/React)
- [ ] `dacong-console/src/app/debug/page.tsx`
- [ ] `dacong-console/src/app/api/tags/route.ts`
- [ ] `dacong-console/src/app/api/models/route.ts`
- [ ] `dacong-console/src/app/api/search/route.ts`
- [ ] `dacong-console/src/app/api/test/route.ts`

### 低优先级 (测试文件)
- [ ] `dacong-admin/test/widget_test.dart`
- [ ] `dacong-admin/test/widgets/charts/line_chart_test.dart`

---

## 审查输出模板

每个模块审查完成后填写：

```
### 模块 X 审查结果

**审查员:** [agent]
**完成时间:** [date]

#### 问题列表
| 严重程度 | 文件 | 行号 | 问题描述 | 建议修复 |
|----------|------|------|----------|----------|
| CRITICAL | ... | ... | ... | ... |

#### 通过项
- [ ] ...

#### 待决策项 (Open Questions)
- [ ] ...
```

---

*Plan generated by planner agent on 2026/05/08*
*Mode: SHORT (standard review scope, not DELIBERATE)*
