# 日志告警规则配置

## 告警规则定义

### 1. 错误率告警

**规则名称**: `high_error_rate`

**触发条件**: 5 分钟内错误率超过 5%

**LogQL 查询**:
```logql
sum(rate({service=~"dacong-.*"} |= "ERROR" [5m])) 
/ 
sum(rate({service=~"dacong-.*"} [5m])) 
> 0.05
```

**严重级别**: Critical

**通知渠道**: Email, Slack, PagerDuty

**处理建议**:
1. 检查最近的部署是否引入问题
2. 查看错误日志详情定位根因
3. 如果是新部署导致，考虑回滚
4. 修复后验证错误率恢复正常

---

### 2. 数据库连接失败告警

**规则名称**: `database_connection_failure`

**触发条件**: 出现数据库连接失败日志

**LogQL 查询**:
```logql
count_over_time({service=~"dacong-.*"} |~ "database.*connection.*failed|ECONNREFUSED.*postgres" [5m]) > 0
```

**严重级别**: Critical

**通知渠道**: Email, Slack, PagerDuty

**处理建议**:
1. 检查数据库服务状态
2. 验证数据库连接配置
3. 检查网络连接
4. 查看数据库连接池状态
5. 必要时重启应用服务

---

### 3. 慢请求告警

**规则名称**: `slow_requests`

**触发条件**: 5 分钟内超过 10% 的请求响应时间 > 1 秒

**LogQL 查询**:
```logql
sum(rate({service="dacong-api"} | json | duration_ms > 1000 [5m]))
/
sum(rate({service="dacong-api"} | json | duration_ms > 0 [5m]))
> 0.1
```

**严重级别**: Warning

**通知渠道**: Slack

**处理建议**:
1. 查看慢请求的具体接口
2. 检查数据库查询性能
3. 分析是否有 N+1 查询问题
4. 检查缓存是否正常工作
5. 考虑添加索引或优化查询

---

### 4. 爬虫失败率告警

**规则名称**: `spider_high_failure_rate`

**触发条件**: 10 分钟内爬虫失败率超过 20%

**LogQL 查询**:
```logql
sum(rate({service="dacong-spider"} |= "Scrape failed" [10m]))
/
sum(rate({service="dacong-spider"} |~ "Scrape (started|failed|completed)" [10m]))
> 0.2
```

**严重级别**: Warning

**通知渠道**: Slack

**处理建议**:
1. 检查目标网站是否可访问
2. 验证是否被反爬虫机制拦截
3. 检查代理服务是否正常
4. 查看具体失败原因
5. 调整爬虫策略（降低频率、更换 User-Agent）

---

### 5. 日志量异常告警

**规则名称**: `abnormal_log_volume`

**触发条件**: 日志量突然增加或减少 50% 以上

**LogQL 查询**:
```logql
# 日志量突增
abs(
  rate({service=~"dacong-.*"} [5m])
  -
  rate({service=~"dacong-.*"} [5m] offset 1h)
) 
/ 
rate({service=~"dacong-.*"} [5m] offset 1h)
> 0.5
```

**严重级别**: Warning

**通知渠道**: Slack

**处理建议**:
1. 日志量突增：检查是否有异常循环或错误
2. 日志量突减：检查服务是否正常运行
3. 查看日志内容确认是否有异常
4. 检查是否有流量异常

---

### 6. 认证失败告警

**规则名称**: `authentication_failures`

**触发条件**: 5 分钟内认证失败超过 100 次

**LogQL 查询**:
```logql
count_over_time({service="dacong-api"} |~ "authentication.*failed|unauthorized|401" [5m]) > 100
```

**严重级别**: Warning

**通知渠道**: Slack, Email

**处理建议**:
1. 检查是否有暴力破解攻击
2. 查看失败的 IP 地址
3. 考虑启用 IP 限流
4. 验证认证服务是否正常
5. 必要时临时封禁可疑 IP

---

### 7. 内存不足告警

**规则名称**: `out_of_memory`

**触发条件**: 出现内存不足错误

**LogQL 查询**:
```logql
count_over_time({service=~"dacong-.*"} |~ "out of memory|OOM|memory.*exhausted" [5m]) > 0
```

**严重级别**: Critical

**通知渠道**: Email, Slack, PagerDuty

**处理建议**:
1. 立即检查服务内存使用情况
2. 重启受影响的服务
3. 分析内存泄漏原因
4. 考虑增加内存配置
5. 优化代码减少内存占用

---

## Loki 告警规则配置文件

在 `config/loki-rules.yaml` 中配置：

```yaml
groups:
  - name: dacong_alerts
    interval: 1m
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate({service=~"dacong-.*"} |= "ERROR" [5m])) 
          / 
          sum(rate({service=~"dacong-.*"} [5m])) 
          > 0.05
        for: 5m
        labels:
          severity: critical
          service: "{{ $labels.service }}"
        annotations:
          summary: "高错误率告警"
          description: "服务 {{ $labels.service }} 的错误率超过 5%"

      - alert: DatabaseConnectionFailure
        expr: |
          count_over_time({service=~"dacong-.*"} |~ "database.*connection.*failed|ECONNREFUSED.*postgres" [5m]) > 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "数据库连接失败"
          description: "检测到数据库连接失败"

      - alert: SlowRequests
        expr: |
          sum(rate({service="dacong-api"} | json | duration_ms > 1000 [5m]))
          /
          sum(rate({service="dacong-api"} | json | duration_ms > 0 [5m]))
          > 0.1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "慢请求告警"
          description: "超过 10% 的请求响应时间大于 1 秒"

      - alert: SpiderHighFailureRate
        expr: |
          sum(rate({service="dacong-spider"} |= "Scrape failed" [10m]))
          /
          sum(rate({service="dacong-spider"} |~ "Scrape (started|failed|completed)" [10m]))
          > 0.2
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "爬虫失败率过高"
          description: "爬虫失败率超过 20%"

      - alert: AuthenticationFailures
        expr: |
          count_over_time({service="dacong-api"} |~ "authentication.*failed|unauthorized|401" [5m]) > 100
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "认证失败次数过多"
          description: "5 分钟内认证失败超过 100 次，可能存在暴力破解攻击"

      - alert: OutOfMemory
        expr: |
          count_over_time({service=~"dacong-.*"} |~ "out of memory|OOM|memory.*exhausted" [5m]) > 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "内存不足"
          description: "服务 {{ $labels.service }} 出现内存不足错误"
```

---

## Grafana 告警配置

### 1. 配置通知渠道

在 Grafana UI 中配置：

**Alerting → Contact points → New contact point**

#### Slack 配置
- Name: `slack-alerts`
- Type: `Slack`
- Webhook URL: `https://hooks.slack.com/services/YOUR/WEBHOOK/URL`
- Channel: `#dacong-alerts`

#### Email 配置
- Name: `email-alerts`
- Type: `Email`
- Addresses: `ops@example.com, dev@example.com`

#### PagerDuty 配置（可选）
- Name: `pagerduty-critical`
- Type: `PagerDuty`
- Integration Key: `YOUR_INTEGRATION_KEY`

### 2. 配置通知策略

**Alerting → Notification policies**

```
Root policy
├── Critical alerts → PagerDuty + Email
│   └── Match: severity = critical
└── Warning alerts → Slack
    └── Match: severity = warning
```

### 3. 静默规则

在维护期间配置静默：

**Alerting → Silences → New silence**

- Matchers: `service = dacong-api`
- Duration: `2h`
- Comment: `Scheduled maintenance`

---

## 告警测试

### 测试错误率告警

```bash
# 生成测试错误日志
for i in {1..100}; do
  echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","level":"ERROR","service":"dacong-api","function":"test","message":"Test error"}' >> logs/api/test.log
done
```

### 测试数据库连接告警

```bash
echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","level":"ERROR","service":"dacong-api","function":"db","message":"database connection failed"}' >> logs/api/test.log
```

### 验证告警触发

1. 等待 1-5 分钟（根据告警规则的 `for` 时间）
2. 检查 Grafana Alerting 页面
3. 验证通知渠道是否收到告警

---

## 告警响应流程

### 1. 收到告警

- 查看告警详情（服务、时间、严重级别）
- 确认是否为误报
- 记录告警时间和初步判断

### 2. 问题诊断

- 访问 Grafana 查看日志详情
- 使用 LogQL 查询相关日志
- 检查监控指标（CPU、内存、网络）
- 查看最近的部署记录

### 3. 问题处理

- 根据告警类型执行对应的处理建议
- 记录处理步骤和结果
- 必要时升级到高级工程师

### 4. 问题解决

- 验证问题已解决
- 确认告警已恢复
- 编写事后总结（Post-mortem）
- 更新文档和 Runbook

---

## 常用 LogQL 查询

### 查询错误日志
```logql
{service="dacong-api"} |= "ERROR"
```

### 查询特定函数的日志
```logql
{service="dacong-api"} | json | function="recommend"
```

### 查询慢请求
```logql
{service="dacong-api"} | json | duration_ms > 1000
```

### 统计错误率
```logql
sum(rate({service="dacong-api"} |= "ERROR" [5m])) by (function)
```

### 查询特定用户的操作
```logql
{service="dacong-api"} | json | context_user_id="uuid-here"
```

### 查询爬虫失败原因
```logql
{service="dacong-spider"} |= "Scrape failed" | json | line_format "{{.context_url}}: {{.error_message}}"
```

---

## 维护建议

1. **定期审查告警规则**：每月检查告警规则是否合理，调整阈值
2. **减少误报**：分析历史告警，优化规则减少误报
3. **告警疲劳**：避免过多告警，只保留关键告警
4. **文档更新**：及时更新处理建议和 Runbook
5. **演练**：定期进行告警响应演练，确保团队熟悉流程
