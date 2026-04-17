# Sentry 集成测试验证清单

本文档提供 Sentry 集成的测试验证步骤和清单。

## 测试环境准备

### 1. 配置测试 DSN

为每个子系统配置测试环境的 Sentry DSN：

```bash
# 前端客户端
export SENTRY_DSN_CLIENT=https://test-client-dsn@sentry.io/project-id

# 管理后台
export SENTRY_DSN_ADMIN=https://test-admin-dsn@sentry.io/project-id

# 后端 API
export SENTRY_DSN_API=https://test-api-dsn@sentry.io/project-id

# 爬虫系统
export SENTRY_DSN_SPIDER=https://test-spider-dsn@sentry.io/project-id
```

## 前端客户端 (dacong-client) 测试

### ✅ 基础集成测试

```bash
cd dacong-client

# 1. 安装依赖
flutter pub get

# 2. 运行应用（配置 DSN）
flutter run --dart-define=SENTRY_DSN=$SENTRY_DSN_CLIENT
```

### ✅ 错误捕获测试

在应用中添加测试代码：

```dart
// 测试未处理异常
ElevatedButton(
  onPressed: () {
    throw Exception('Test Sentry: Unhandled exception');
  },
  child: Text('触发测试错误'),
)

// 测试手动捕获
ElevatedButton(
  onPressed: () async {
    await SentryConfig.captureException(
      Exception('Test Sentry: Manual capture'),
      hint: 'Manual test',
    );
  },
  child: Text('手动捕获错误'),
)
```

### ✅ 验证清单

- [ ] 应用启动时 Sentry 初始化成功
- [ ] 未处理异常自动上报到 Sentry
- [ ] 手动捕获的异常正确上报
- [ ] 错误详情包含堆栈信息
- [ ] 面包屑正确记录
- [ ] 用户上下文正确设置
- [ ] 敏感信息已过滤
- [ ] 错误 UI 正确显示

## 管理后台 (dacong-admin) 测试

### ✅ 基础集成测试

```bash
cd dacong-admin

# 1. 安装依赖
flutter pub get

# 2. 运行应用
flutter run --dart-define=SENTRY_DSN=$SENTRY_DSN_ADMIN
```

### ✅ 验证清单

- [ ] 应用启动时 Sentry 初始化成功
- [ ] 管理操作错误正确上报
- [ ] 权限错误正确捕获
- [ ] 用户上下文包含管理员信息
- [ ] 标签正确设置（app=dacong-admin）

## 后端 API (dacong-api) 测试

### ✅ 基础集成测试

```bash
cd dacong-api

# 1. 配置 Sentry DSN
supabase secrets set SENTRY_DSN=$SENTRY_DSN_API --env-file .env.local

# 2. 本地测试
supabase functions serve get-content-detail --env-file .env.local

# 3. 触发测试错误
curl "http://localhost:54321/functions/v1/get-content-detail?id=invalid-id"
```

### ✅ 错误捕获测试

测试不同类型的错误：

```bash
# 1. 参数验证错误
curl "http://localhost:54321/functions/v1/get-content-detail"

# 2. 数据库错误
curl "http://localhost:54321/functions/v1/get-content-detail?id=non-existent"

# 3. 未处理异常
# 在代码中添加 throw new Error('Test error')
```

### ✅ 验证清单

- [ ] Edge Function 启动时 Sentry 初始化成功
- [ ] HTTP 请求信息正确记录
- [ ] 错误响应正确上报
- [ ] 面包屑包含请求详情
- [ ] 敏感 headers 已过滤
- [ ] 性能追踪正常工作
- [ ] 数据库错误正确分类

## 爬虫系统 (dacong-spider) 测试

### ✅ 基础集成测试

```bash
cd dacong-spider

# 1. 安装依赖
pip install -r requirements.txt

# 2. 配置环境变量
echo "SENTRY_DSN=$SENTRY_DSN_SPIDER" >> .env

# 3. 运行测试
python main.py --spider github --debug
```

### ✅ 错误捕获测试

```python
# 测试脚本：test_sentry.py
from core.sentry_config import (
    init_sentry,
    capture_exception,
    report_spider_error,
    report_performance_issue,
)

# 初始化
init_sentry(debug=True)

# 测试 1: 捕获异常
try:
    raise Exception("Test Sentry: Spider error")
except Exception as e:
    capture_exception(e)

# 测试 2: 报告爬虫错误
report_spider_error(
    spider_name="test-spider",
    error=Exception("Test spider error"),
    url="https://example.com",
)

# 测试 3: 报告性能问题
report_performance_issue(
    operation="test-operation",
    duration_ms=5000,
    threshold_ms=3000,
)

print("测试完成，请检查 Sentry Dashboard")
```

运行测试：

```bash
python test_sentry.py
```

### ✅ 验证清单

- [ ] 爬虫启动时 Sentry 初始化成功
- [ ] 爬虫错误正确上报
- [ ] 爬虫名称标签正确设置
- [ ] 性能问题正确报告
- [ ] 数据质量问题正确记录
- [ ] 日志集成正常工作
- [ ] 敏感环境变量已过滤

## 性能监控测试

### ✅ 前端性能追踪

```dart
// 测试页面加载性能
final transaction = SentryConfig.startTransaction(
  name: 'test-page-load',
  operation: 'navigation',
);

await Future.delayed(Duration(seconds: 2));

transaction.finish();
```

### ✅ 后端性能追踪

```typescript
// 在 Edge Function 中测试
const transaction = startTransaction(
  'test-api-call',
  'http.server',
);

// 模拟慢操作
await new Promise(resolve => setTimeout(resolve, 2000));

transaction.finish();
```

### ✅ 爬虫性能追踪

```python
import time
from core.sentry_config import start_transaction

transaction = start_transaction(
    name='test-crawl',
    op='spider.crawl',
)

time.sleep(2)  # 模拟慢操作

transaction.finish()
```

### ✅ 验证清单

- [ ] 性能事务正确创建
- [ ] 事务持续时间正确记录
- [ ] 慢操作自动标记
- [ ] 性能数据在 Sentry Dashboard 可见

## 告警测试

### ✅ 触发告警条件

```bash
# 1. 高错误率告警
# 在短时间内触发多个错误（> 5%）

# 2. 新错误告警
# 触发一个新类型的错误

# 3. 性能告警
# 触发一个超过 3 秒的慢操作
```

### ✅ 验证清单

- [ ] 告警规则正确配置
- [ ] 告警正确触发
- [ ] Slack 通知正常接收
- [ ] Email 通知正常接收
- [ ] 告警包含足够的上下文信息

## 集成测试脚本

创建自动化测试脚本：

```bash
#!/bin/bash
# test_sentry_integration.sh

echo "开始 Sentry 集成测试..."

# 1. 测试前端客户端
echo "测试前端客户端..."
cd dacong-client
flutter test test/sentry_test.dart

# 2. 测试管理后台
echo "测试管理后台..."
cd ../dacong-admin
flutter test test/sentry_test.dart

# 3. 测试后端 API
echo "测试后端 API..."
cd ../dacong-api
deno test --allow-all supabase/functions/_shared/utils/sentry_test.ts

# 4. 测试爬虫系统
echo "测试爬虫系统..."
cd ../dacong-spider
python -m pytest tests/test_sentry.py

echo "所有测试完成！"
```

## 验证 Sentry Dashboard

### ✅ 检查事项

登录 Sentry Dashboard 验证：

1. **Issues 页面**
   - [ ] 测试错误已上报
   - [ ] 错误详情完整
   - [ ] 堆栈信息正确
   - [ ] 面包屑可见

2. **Performance 页面**
   - [ ] 事务列表可见
   - [ ] 性能指标正确
   - [ ] 慢操作已标记

3. **Releases 页面**
   - [ ] 版本信息正确
   - [ ] 关联的错误可见

4. **Alerts 页面**
   - [ ] 告警规则已配置
   - [ ] 告警历史可见

## 常见问题排查

### 问题 1: 事件未上报

**排查步骤**:
1. 检查 DSN 配置
2. 检查网络连接
3. 查看本地日志
4. 验证 Sentry SDK 版本

### 问题 2: 性能数据缺失

**排查步骤**:
1. 确认性能监控已启用
2. 检查采样率配置
3. 验证事务创建代码

### 问题 3: 告警未触发

**排查步骤**:
1. 检查告警规则配置
2. 验证触发条件
3. 检查通知渠道设置

## 测试报告模板

```markdown
# Sentry 集成测试报告

**测试日期**: YYYY-MM-DD
**测试人员**: [姓名]

## 测试结果

### 前端客户端 (dacong-client)
- [x] 基础集成
- [x] 错误捕获
- [x] 性能追踪
- [ ] 问题: [描述问题]

### 管理后台 (dacong-admin)
- [x] 基础集成
- [x] 错误捕获
- [x] 性能追踪

### 后端 API (dacong-api)
- [x] 基础集成
- [x] 错误捕获
- [x] 性能追踪

### 爬虫系统 (dacong-spider)
- [x] 基础集成
- [x] 错误捕获
- [x] 性能追踪

## 发现的问题

1. [问题描述]
   - 严重级别: High/Medium/Low
   - 影响范围: [描述]
   - 解决方案: [描述]

## 建议

1. [建议内容]

## 结论

- [ ] 所有测试通过，可以部署到生产环境
- [ ] 部分测试失败，需要修复后重新测试
```

## 生产环境验证

在部署到生产环境后：

1. **监控前 24 小时**
   - 检查错误率
   - 验证告警正常
   - 确认性能数据

2. **第一周检查**
   - 审查新错误
   - 调整告警阈值
   - 优化采样率

3. **持续监控**
   - 每周审查错误趋势
   - 每月优化配置
   - 定期更新文档

## 相关文档

- [Sentry 设置文档](./SENTRY_SETUP.md)
- [告警规则配置](./SENTRY_ALERTS.md)
- [前端集成文档](../dacong-client/lib/core/config/SENTRY_README.md)
- [后端集成文档](../dacong-api/supabase/functions/_shared/utils/SENTRY_README.md)
- [爬虫集成文档](../dacong-spider/core/SENTRY_README.md)
