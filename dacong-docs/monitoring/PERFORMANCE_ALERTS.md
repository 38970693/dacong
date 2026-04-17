# 性能告警配置

## 告警规则

### API 性能告警

#### 1. API 响应时间告警

**规则名称**: `api_response_time_p95`

**条件**:
- P95 响应时间 > 1000ms（警告）
- P95 响应时间 > 5000ms（严重）

**检查频率**: 每 5 分钟

**告警内容**:
```
🟡 WARNING: API 响应时间过长
端点: {endpoint}
P95 响应时间: {p95_ms}ms
阈值: 1000ms
建议: 检查数据库查询、添加缓存
```

#### 2. API 错误率告警

**规则名称**: `api_error_rate`

**条件**:
- 错误率 > 5%（严重）
- 错误率 > 10%（紧急）

**检查频率**: 每 1 分钟

**告警内容**:
```
🔴 CRITICAL: API 错误率过高
端点: {endpoint}
错误率: {error_rate}%
阈值: 5%
建议: 立即检查日志，修复 bug
```

### 数据库性能告警

#### 3. 慢查询告警

**规则名称**: `slow_query_count`

**条件**:
- 慢查询数量 > 10 次/分钟（警告）
- 慢查询数量 > 50 次/分钟（严重）

**检查频率**: 每 5 分钟

**告警内容**:
```
🟡 WARNING: 数据库慢查询过多
慢查询数量: {count}/分钟
阈值: 10/分钟
建议: 检查 pg_stat_statements，添加索引
```

#### 4. 数据库连接数告警

**规则名称**: `db_connection_count`

**条件**:
- 连接数 > 80（警告）
- 连接数 > 95（严重）

**检查频率**: 每 1 分钟

**告警内容**:
```
🔴 CRITICAL: 数据库连接数过高
当前连接数: {count}
最大连接数: 100
建议: 检查连接泄漏，优化连接池配置
```

### 前端性能告警

#### 5. 页面加载时间告警

**规则名称**: `page_load_time`

**条件**:
- 页面加载时间 > 3000ms（警告）
- 页面加载时间 > 5000ms（严重）

**检查频率**: 实时

**告警内容**:
```
🟡 WARNING: 页面加载时间过长
页面: {page_name}
加载时间: {duration_ms}ms
阈值: 3000ms
建议: 优化资源加载，使用代码分割
```

#### 6. 帧率告警

**规则名称**: `frame_rate_low`

**条件**:
- 帧率 < 30 FPS（严重）
- 帧率 < 50 FPS（警告）

**检查频率**: 实时

**告警内容**:
```
🔴 CRITICAL: 帧率过低
当前帧率: {fps} FPS
阈值: 30 FPS
建议: 优化渲染逻辑，减少重绘
```

### 爬虫性能告警

#### 7. 爬虫失败率告警

**规则名称**: `spider_error_rate`

**条件**:
- 错误率 > 10%（警告）
- 错误率 > 20%（严重）

**检查频率**: 每次运行后

**告警内容**:
```
🔴 CRITICAL: 爬虫失败率过高
爬虫: {spider_name}
错误率: {error_rate}%
阈值: 10%
建议: 检查网络连接，修复解析逻辑
```

#### 8. 爬虫运行时间告警

**规则名称**: `spider_duration`

**条件**:
- 运行时间 > 600s（警告）
- 运行时间 > 1800s（严重）

**检查频率**: 每次运行后

**告警内容**:
```
🟡 WARNING: 爬虫运行时间过长
爬虫: {spider_name}
运行时间: {duration}s
阈值: 600s
建议: 优化并发配置，检查网络延迟
```

## 告警通知配置

### 通知渠道

1. **控制台日志**: 所有告警
2. **Sentry**: 严重和紧急告警
3. **邮件**: 严重告警（可选）
4. **Slack/钉钉**: 严重告警（可选）

### 告警级别

| 级别 | 说明 | 响应时间 | 通知方式 |
|------|------|----------|----------|
| INFO | 信息 | 无需响应 | 日志 |
| WARNING | 警告 | 24小时内 | 日志 + Sentry |
| CRITICAL | 严重 | 1小时内 | 日志 + Sentry + 邮件 |
| EMERGENCY | 紧急 | 立即 | 所有渠道 |

### 告警抑制

为避免告警风暴，配置告警抑制规则：

1. **同类告警合并**: 5分钟内同一规则的告警合并为一条
2. **告警静默期**: 告警发送后 15 分钟内不再重复发送
3. **维护窗口**: 维护期间暂停告警

## 告警处理流程

### 1. 接收告警

- 查看告警级别和内容
- 确认是否为误报
- 记录告警时间和现象

### 2. 初步诊断

- 查看监控面板
- 检查相关日志
- 确定影响范围

### 3. 问题定位

- 使用性能分析工具
- 查询数据库慢查询
- 检查系统资源使用

### 4. 问题修复

- 实施临时缓解措施
- 修复根本原因
- 验证修复效果

### 5. 复盘总结

- 记录问题原因
- 更新文档
- 优化告警规则

## 告警配置示例

### Sentry 告警配置

```yaml
# sentry.yaml
alerts:
  - name: API Response Time P95
    conditions:
      - metric: transaction.duration
        aggregation: p95
        value: 1000
        comparison: gt
    actions:
      - type: email
        target: devops@example.com
      - type: slack
        target: "#alerts"
```

### 数据库告警查询

```sql
-- 检查慢查询
SELECT
    COUNT(*) as slow_query_count
FROM pg_stat_statements
WHERE mean_exec_time > 1000
    AND calls > 10;

-- 检查连接数
SELECT
    COUNT(*) as connection_count
FROM pg_stat_activity
WHERE state = 'active';
```

### 自定义告警脚本

```bash
#!/bin/bash
# check_performance.sh

# 检查 API P95 响应时间
p95=$(psql $DATABASE_URL -t -c "
    SELECT PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY metric_value)
    FROM performance_metrics
    WHERE service = 'api'
        AND metric_type = 'api_call'
        AND created_at > NOW() - INTERVAL '5 minutes';
")

if (( $(echo "$p95 > 1000" | bc -l) )); then
    echo "🟡 WARNING: API P95 response time is ${p95}ms"
    # 发送告警
fi
```

## 告警优化建议

1. **避免告警疲劳**: 只配置真正重要的告警
2. **合理设置阈值**: 根据历史数据设置阈值
3. **告警分级**: 不同级别采用不同处理策略
4. **定期审查**: 定期审查告警规则，删除无效告警
5. **自动化响应**: 对于常见问题，配置自动化响应
6. **告警文档**: 为每个告警编写处理文档
7. **告警测试**: 定期测试告警是否正常工作

## 参考资料

- [Sentry Alerts Documentation](https://docs.sentry.io/product/alerts/)
- [PostgreSQL Monitoring](https://www.postgresql.org/docs/current/monitoring.html)
- [Site Reliability Engineering - Alerting](https://sre.google/sre-book/monitoring-distributed-systems/)
