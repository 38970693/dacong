# Sentry 告警规则配置

本文档定义了 DaCong 项目的 Sentry 告警规则，用于及时发现和响应系统问题。

## 告警规则概览

| 规则名称 | 触发条件 | 严重级别 | 通知渠道 |
|---------|---------|---------|---------|
| 高错误率告警 | 错误率 > 5% | Critical | Email + Slack |
| 新错误告警 | 新类型错误出现 | High | Slack |
| 性能下降告警 | P95 响应时间 > 3s | Medium | Slack |
| 崩溃率告警 | 崩溃率 > 1% | Critical | Email + Slack |
| 数据库错误 | 数据库操作失败 | High | Slack |
| API 错误率 | API 错误率 > 10% | High | Email + Slack |

## 详细规则配置

### 1. 高错误率告警

**目的**: 检测系统整体错误率异常升高

**配置**:
```yaml
name: 高错误率告警
condition: 
  - metric: error_rate
  - threshold: 5%
  - time_window: 5分钟
  - comparison: greater_than
action:
  - notify: email
  - notify: slack
  - severity: critical
filter:
  - environment: production
```

**响应流程**:
1. 立即检查 Sentry 错误详情
2. 识别错误来源（前端/后端/爬虫）
3. 评估影响范围
4. 启动应急响应流程

### 2. 新错误告警

**目的**: 及时发现新引入的错误

**配置**:
```yaml
name: 新错误告警
condition:
  - type: new_issue
  - first_seen: true
action:
  - notify: slack
  - severity: high
filter:
  - environment: production
  - level: [error, fatal]
```

**响应流程**:
1. 查看错误堆栈和上下文
2. 确认是否为新部署引入
3. 评估是否需要回滚
4. 创建修复任务

### 3. 性能下降告警

**目的**: 监控系统性能指标

**配置**:
```yaml
name: 性能下降告警
condition:
  - metric: transaction_duration
  - percentile: p95
  - threshold: 3000ms
  - time_window: 10分钟
  - comparison: greater_than
action:
  - notify: slack
  - severity: medium
filter:
  - environment: production
  - transaction: [api.*, spider.*]
```

**响应流程**:
1. 检查性能追踪详情
2. 识别慢操作（数据库查询、外部 API 调用）
3. 分析是否为流量激增导致
4. 优化慢操作或扩容

### 4. 崩溃率告警

**目的**: 监控应用崩溃情况

**配置**:
```yaml
name: 崩溃率告警
condition:
  - metric: crash_rate
  - threshold: 1%
  - time_window: 15分钟
  - comparison: greater_than
action:
  - notify: email
  - notify: slack
  - severity: critical
filter:
  - environment: production
  - platform: [flutter, android, ios]
```

**响应流程**:
1. 查看崩溃堆栈
2. 识别受影响的设备和版本
3. 评估是否需要紧急修复
4. 发布热修复或回滚

### 5. 数据库错误告警

**目的**: 监控数据库操作异常

**配置**:
```yaml
name: 数据库错误告警
condition:
  - tag: category = database
  - count: > 10
  - time_window: 5分钟
action:
  - notify: slack
  - severity: high
filter:
  - environment: production
```

**响应流程**:
1. 检查数据库连接状态
2. 查看慢查询日志
3. 检查数据库资源使用情况
4. 优化查询或扩容

### 6. API 错误率告警

**目的**: 监控 API 端点健康状况

**配置**:
```yaml
name: API 错误率告警
condition:
  - metric: error_rate
  - threshold: 10%
  - time_window: 5分钟
  - comparison: greater_than
action:
  - notify: email
  - notify: slack
  - severity: high
filter:
  - environment: production
  - transaction: api.*
  - status_code: [500, 502, 503, 504]
```

**响应流程**:
1. 识别失败的 API 端点
2. 检查依赖服务状态
3. 查看错误日志
4. 修复或降级服务

## 按子系统分类的告警

### 前端客户端 (dacong-client)

- **崩溃告警**: 崩溃率 > 1%
- **网络错误**: 网络请求失败率 > 15%
- **渲染错误**: UI 渲染异常
- **性能告警**: 页面加载时间 > 3s

### 后端 API (dacong-api)

- **高错误率**: 错误率 > 5%
- **慢请求**: P95 响应时间 > 2s
- **数据库错误**: 数据库操作失败
- **外部 API 错误**: 第三方 API 调用失败

### 爬虫系统 (dacong-spider)

- **爬取失败**: 爬虫运行失败
- **数据质量**: 数据验证失败率 > 10%
- **性能问题**: 爬取时间超过预期 2 倍
- **限流告警**: 被目标网站限流

### 管理后台 (dacong-admin)

- **操作错误**: 管理操作失败
- **权限错误**: 未授权访问尝试
- **数据导出错误**: 导出操作失败

## 告警通知配置

### Slack 集成

1. 在 Sentry 项目设置中添加 Slack 集成
2. 选择通知频道（如 `#alerts`）
3. 配置告警规则关联到 Slack

### Email 通知

1. 在 Sentry 项目设置中配置邮件通知
2. 添加接收人列表
3. 设置通知频率（立即/每小时摘要/每日摘要）

### 通知优先级

- **Critical**: 立即通知（Email + Slack）
- **High**: 5 分钟内通知（Slack）
- **Medium**: 15 分钟内通知（Slack）
- **Low**: 每日摘要（Email）

## 告警静默规则

### 已知问题静默

对于已知且正在修复的问题，可以临时静默告警：

1. 在 Sentry 中找到对应的 Issue
2. 点击 "Mute" 按钮
3. 选择静默时长（1小时/1天/直到修复）
4. 添加静默原因

### 维护窗口静默

在系统维护期间，可以全局静默告警：

1. 进入项目设置 > Alerts
2. 创建维护窗口规则
3. 设置开始和结束时间
4. 选择要静默的告警类型

## 告警响应 SLA

| 严重级别 | 响应时间 | 解决时间 |
|---------|---------|---------|
| Critical | 15 分钟 | 2 小时 |
| High | 1 小时 | 8 小时 |
| Medium | 4 小时 | 24 小时 |
| Low | 24 小时 | 1 周 |

## 告警优化建议

### 1. 减少噪音

- 合并相似错误
- 提高阈值（避免误报）
- 过滤已知的非关键错误

### 2. 提高准确性

- 使用多个指标组合判断
- 设置合理的时间窗口
- 区分不同环境的阈值

### 3. 改进响应

- 在告警中包含上下文信息
- 提供快速诊断链接
- 自动创建修复任务

## 定期审查

每月审查告警规则：

1. 检查误报率
2. 调整阈值
3. 添加新规则
4. 删除过时规则
5. 更新响应流程

## 相关文档

- [Sentry 设置文档](./SENTRY_SETUP.md)
- [前端客户端 Sentry 集成](../dacong-client/lib/core/config/SENTRY_README.md)
- [后端 API Sentry 集成](../dacong-api/supabase/functions/_shared/utils/SENTRY_README.md)
- [爬虫系统 Sentry 集成](../dacong-spider/core/SENTRY_README.md)
