# Sentry 错误监控设置指南

本文档提供 DaCong 项目 Sentry 错误监控的完整设置指南。

## 目录

- [前置准备](#前置准备)
- [创建 Sentry 项目](#创建-sentry-项目)
- [配置各子系统](#配置各子系统)
- [告警配置](#告警配置)
- [团队协作](#团队协作)
- [最佳实践](#最佳实践)

## 前置准备

### 1. 注册 Sentry 账号

1. 访问 [sentry.io](https://sentry.io)
2. 注册账号或使用 GitHub 登录
3. 创建组织（Organization）

### 2. 选择计划

- **开发/测试**: 免费计划（每月 5,000 事件）
- **生产环境**: 根据流量选择付费计划

## 创建 Sentry 项目

### 为每个子系统创建独立项目

建议为每个子系统创建独立的 Sentry 项目，便于管理和追踪：

1. **dacong-client** (Flutter)
2. **dacong-admin** (Flutter)
3. **dacong-api** (Deno/Edge Functions)
4. **dacong-spider** (Python)

### 创建步骤

1. 登录 Sentry Dashboard
2. 点击 "Create Project"
3. 选择平台：
   - Flutter (客户端和管理后台)
   - JavaScript (API)
   - Python (爬虫)
4. 输入项目名称
5. 选择团队
6. 点击 "Create Project"
7. 复制 DSN（Data Source Name）

## 配置各子系统

### 1. 前端客户端 (dacong-client)

#### 安装依赖

```bash
cd dacong-client
flutter pub add sentry_flutter
```

#### 配置环境变量

```bash
# 开发环境
flutter run --dart-define=SENTRY_DSN=https://your-dsn@sentry.io/project-id

# 生产构建
flutter build apk --dart-define=SENTRY_DSN=https://your-dsn@sentry.io/project-id
flutter build ios --dart-define=SENTRY_DSN=https://your-dsn@sentry.io/project-id
```

#### 验证集成

```bash
# 运行应用并触发测试错误
flutter run --dart-define=SENTRY_DSN=your_dsn_here

# 在应用中手动触发错误
throw Exception('Test Sentry integration');
```

#### 配置文件

参考 `dacong-client/lib/core/config/SENTRY_README.md`

### 2. 管理后台 (dacong-admin)

配置方式与前端客户端相同：

```bash
cd dacong-admin
flutter pub add sentry_flutter
flutter run --dart-define=SENTRY_DSN=your_dsn_here
```

### 3. 后端 API (dacong-api)

#### 配置 Supabase Secrets

```bash
cd dacong-api

# 设置 Sentry DSN
supabase secrets set SENTRY_DSN=https://your-dsn@sentry.io/project-id

# 设置环境
supabase secrets set ENVIRONMENT=production

# 查看已设置的 secrets
supabase secrets list
```

#### 验证集成

```bash
# 本地测试
supabase functions serve get-content-detail --env-file .env.local

# 部署到 Supabase
supabase functions deploy get-content-detail

# 测试 API 并检查 Sentry
curl https://your-project.supabase.co/functions/v1/get-content-detail?id=test
```

#### 配置文件

参考 `dacong-api/supabase/functions/_shared/utils/SENTRY_README.md`

### 4. 爬虫系统 (dacong-spider)

#### 安装依赖

```bash
cd dacong-spider
pip install sentry-sdk
```

#### 配置环境变量

在 `.env` 文件中添加：

```bash
SENTRY_DSN=https://your-dsn@sentry.io/project-id
ENVIRONMENT=production
```

#### 验证集成

```bash
# 运行爬虫并检查 Sentry
python main.py --spider github --debug

# 触发测试错误
python -c "from core.sentry_config import capture_exception; capture_exception(Exception('Test'))"
```

#### 配置文件

参考 `dacong-spider/core/SENTRY_README.md`

## 告警配置

### 1. 配置告警规则

在 Sentry Dashboard 中：

1. 进入项目设置
2. 点击 "Alerts"
3. 点击 "Create Alert Rule"
4. 选择告警类型：
   - Issue Alert（错误告警）
   - Metric Alert（指标告警）
5. 配置触发条件
6. 设置通知渠道

### 2. 推荐的告警规则

参考 [SENTRY_ALERTS.md](./SENTRY_ALERTS.md) 中的详细配置。

### 3. 集成通知渠道

#### Slack 集成

1. 在 Sentry 项目设置中找到 "Integrations"
2. 搜索并添加 "Slack"
3. 授权 Slack workspace
4. 选择通知频道
5. 配置告警规则关联到 Slack

#### Email 通知

1. 在项目设置中找到 "Alerts"
2. 配置 Email 通知
3. 添加接收人
4. 设置通知频率

## 团队协作

### 1. 邀请团队成员

1. 进入组织设置
2. 点击 "Members"
3. 点击 "Invite Member"
4. 输入邮箱地址
5. 选择角色：
   - Owner（所有权限）
   - Manager（管理权限）
   - Admin（管理项目）
   - Member（查看和评论）
   - Billing（账单管理）

### 2. 配置团队权限

1. 创建团队（Team）
2. 分配项目到团队
3. 设置团队成员
4. 配置团队告警规则

### 3. Issue 分配流程

1. 新 Issue 自动分配给团队
2. 团队成员认领 Issue
3. 标记 Issue 状态（Resolved/Ignored）
4. 关联 GitHub Issue 或 PR

## 环境配置

### 开发环境

```bash
# 前端
SENTRY_DSN=https://dev-dsn@sentry.io/project-id

# 后端
SENTRY_DSN=https://dev-dsn@sentry.io/project-id
ENVIRONMENT=development

# 爬虫
SENTRY_DSN=https://dev-dsn@sentry.io/project-id
ENVIRONMENT=development
```

### 生产环境

```bash
# 前端
SENTRY_DSN=https://prod-dsn@sentry.io/project-id

# 后端
SENTRY_DSN=https://prod-dsn@sentry.io/project-id
ENVIRONMENT=production

# 爬虫
SENTRY_DSN=https://prod-dsn@sentry.io/project-id
ENVIRONMENT=production
```

## 性能监控配置

### 1. 启用性能追踪

在 Sentry 项目设置中：

1. 进入 "Performance"
2. 启用性能监控
3. 配置采样率：
   - 开发环境：100%
   - 生产环境：20%

### 2. 配置事务追踪

各子系统已自动配置事务追踪：

- **前端**: 页面加载、网络请求
- **后端**: API 请求、数据库查询
- **爬虫**: 爬取任务、数据处理

### 3. 性能阈值设置

在 Sentry Dashboard 中配置性能阈值：

- P95 响应时间 > 3s 触发告警
- 慢事务自动标记
- 性能趋势分析

## 数据保留策略

### 1. 事件保留

- 免费计划：30 天
- 付费计划：90 天或更长

### 2. 性能数据保留

- 免费计划：7 天
- 付费计划：30 天或更长

### 3. 数据采样

生产环境建议配置：

- 错误事件：100%（所有错误都记录）
- 性能追踪：20%（采样 20% 的事务）
- 会话重放：5%（采样 5% 的会话）

## 最佳实践

### 1. 错误分组

- 使用有意义的错误消息
- 添加上下文信息
- 使用标签分类错误

### 2. 敏感信息过滤

所有子系统已配置敏感信息过滤：

- 密码
- Token
- API Key
- Authorization Header

### 3. 面包屑使用

在关键操作前添加面包屑：

```dart
// Flutter
SentryConfig.addBreadcrumb(
  message: '用户点击登录按钮',
  category: 'user-action',
);
```

```typescript
// Deno
addBreadcrumb({
  message: 'API 请求开始',
  category: 'http',
});
```

```python
# Python
add_breadcrumb(
  message='开始爬取数据',
  category='spider',
)
```

### 4. 用户上下文

登录后设置用户上下文：

```dart
// Flutter
SentryConfig.setUser(
  id: user.id,
  email: user.email,
);
```

### 5. 发布追踪

配置发布版本：

- 前端：`dacong-client@version`
- 后端：`dacong-api@version`
- 爬虫：`dacong-spider@version`

## 故障排查

### 问题：事件未上报

1. 检查 DSN 配置是否正确
2. 检查网络连接
3. 查看本地日志
4. 验证 Sentry SDK 版本

### 问题：性能数据缺失

1. 确认性能监控已启用
2. 检查采样率配置
3. 验证事务是否正确创建

### 问题：告警未触发

1. 检查告警规则配置
2. 验证触发条件
3. 检查通知渠道设置
4. 查看告警历史

## 监控仪表板

### 推荐的仪表板配置

1. **错误概览**
   - 错误率趋势
   - 新错误数量
   - 受影响用户数

2. **性能监控**
   - P95 响应时间
   - 慢事务列表
   - 吞吐量趋势

3. **用户影响**
   - 崩溃率
   - 受影响用户
   - 用户反馈

## 定期维护

### 每周任务

- 审查新错误
- 处理高优先级 Issue
- 检查告警规则

### 每月任务

- 分析错误趋势
- 优化告警阈值
- 更新团队配置
- 审查性能指标

### 每季度任务

- 评估 Sentry 计划
- 更新最佳实践
- 团队培训
- 文档更新

## 相关资源

- [Sentry 官方文档](https://docs.sentry.io/)
- [Flutter SDK 文档](https://docs.sentry.io/platforms/flutter/)
- [JavaScript SDK 文档](https://docs.sentry.io/platforms/javascript/)
- [Python SDK 文档](https://docs.sentry.io/platforms/python/)
- [告警规则配置](./SENTRY_ALERTS.md)

## 支持

如有问题，请联系：

- 技术负责人：[your-email@example.com]
- Sentry 支持：[support@sentry.io]
- 项目文档：[项目 Wiki]
