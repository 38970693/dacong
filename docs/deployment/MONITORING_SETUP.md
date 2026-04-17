# 监控配置指南

## 概述

本文档说明如何配置完整的监控系统，包括错误追踪、性能监控、日志聚合和告警通知。

---

## 1. 监控架构

```
┌─────────────────────────────────────────────────────────┐
│                    监控层级                              │
├─────────────────────────────────────────────────────────┤
│  应用层    │  Sentry (错误追踪)                         │
│            │  Supabase Analytics (性能监控)             │
├─────────────────────────────────────────────────────────┤
│  基础设施层 │  Netdata/Prometheus (服务器监控)          │
│            │  Cloudflare Analytics (CDN 监控)           │
├─────────────────────────────────────────────────────────┤
│  日志层    │  Loki/ELK (日志聚合)                       │
│            │  Supabase Logs (数据库日志)                │
├─────────────────────────────────────────────────────────┤
│  告警层    │  Email/Slack/Telegram (通知渠道)          │
└─────────────────────────────────────────────────────────┘
```

---

## 2. Sentry 错误监控

### 2.1 创建 Sentry 项目

1. 访问 https://sentry.io
2. 注册账号（免费版：5000 errors/月）
3. 创建新项目：
   - Platform: Flutter
   - Project Name: `dacong-client`
4. 获取 DSN：`https://xxxxx@sentry.io/xxxxx`

### 2.2 Flutter 集成

**安装依赖**：
```yaml
# pubspec.yaml
dependencies:
  sentry_flutter: ^7.0.0
```

**初始化 Sentry**：
```dart
// lib/main.dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://xxxxx@sentry.io/xxxxx';
      options.environment = 'production';
      options.release = '1.0.0';
      options.tracesSampleRate = 1.0; // 100% 性能追踪
      options.enableAutoSessionTracking = true;
      options.attachScreenshot = true;
      options.attachViewHierarchy = true;
    },
    appRunner: () => runApp(MyApp()),
  );
}
```

**捕获错误**：
```dart
// 自动捕获未处理的错误
FlutterError.onError = (details) {
  Sentry.captureException(
    details.exception,
    stackTrace: details.stack,
  );
};

// 手动捕获错误
try {
  await riskyOperation();
} catch (error, stackTrace) {
  await Sentry.captureException(
    error,
    stackTrace: stackTrace,
    hint: Hint.withMap({'operation': 'riskyOperation'}),
  );
}

// 添加用户上下文
Sentry.configureScope((scope) {
  scope.setUser(SentryUser(
    id: userId,
    email: userEmail,
    username: username,
  ));
});

// 添加面包屑
Sentry.addBreadcrumb(Breadcrumb(
  message: 'User clicked button',
  category: 'ui.click',
  level: SentryLevel.info,
));
```

### 2.3 后端集成（Edge Functions）

**安装 Sentry SDK**：
```typescript
// supabase/functions/_shared/sentry.ts
import * as Sentry from 'https://deno.land/x/sentry/index.mjs';

Sentry.init({
  dsn: Deno.env.get('SENTRY_DSN'),
  environment: 'production',
  tracesSampleRate: 1.0,
});

export function captureError(error: Error, context?: Record<string, any>) {
  Sentry.captureException(error, {
    extra: context,
  });
}
```

**使用示例**：
```typescript
// supabase/functions/rank-calc/index.ts
import { captureError } from '../_shared/sentry.ts';

Deno.serve(async (req) => {
  try {
    // 业务逻辑
    const result = await calculateRank();
    return new Response(JSON.stringify(result), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    captureError(error, {
      function: 'rank-calc',
      request: req.url,
    });
    return new Response(JSON.stringify({ error: 'Internal error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
```

### 2.4 配置告警规则

访问 Sentry Dashboard > Alerts

**推荐规则**：

1. **高频错误告警**
   - 条件：同一错误 > 10 次/小时
   - 通知：Email + Slack

2. **新错误告警**
   - 条件：首次出现的错误
   - 通知：Email

3. **性能下降告警**
   - 条件：P95 响应时间 > 2 秒
   - 通知：Slack

4. **崩溃率告警**
   - 条件：崩溃率 > 1%
   - 通知：Email + Slack

---

## 3. Supabase 性能监控

### 3.1 启用 Supabase 监控

访问 Supabase Dashboard > Reports

**监控指标**：
- API 请求数和响应时间
- 数据库连接数和查询时间
- Storage 使用量和带宽
- Edge Functions 调用次数和执行时间

### 3.2 配置慢查询监控

```sql
-- 启用 pg_stat_statements
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- 查看慢查询
SELECT 
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time,
    stddev_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 100  -- 平均执行时间 > 100ms
ORDER BY mean_exec_time DESC
LIMIT 20;

-- 创建慢查询视图
CREATE OR REPLACE VIEW slow_queries AS
SELECT 
    query,
    calls,
    round(total_exec_time::numeric, 2) as total_time_ms,
    round(mean_exec_time::numeric, 2) as avg_time_ms,
    round(max_exec_time::numeric, 2) as max_time_ms
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC;
```

### 3.3 配置使用量告警

访问 Supabase Dashboard > Settings > Billing > Usage Alerts

**推荐告警**：
- Database Size > 80% of quota
- API Requests > 80% of quota
- Storage > 80% of quota
- Bandwidth > 80% of quota

---

## 4. 服务器监控

### 4.1 安装 Netdata（推荐）

**优势**：
- 实时监控（1 秒更新）
- 零配置
- 美观的 Web 界面
- 免费开源

**安装**：
```bash
# 一键安装
bash <(curl -Ss https://my-netdata.io/kickstart.sh)

# 启动服务
sudo systemctl start netdata
sudo systemctl enable netdata

# 访问 Web 界面
# http://your-vps-ip:19999
```

**配置防火墙**：
```bash
# 仅允许特定 IP 访问
sudo ufw allow from your-ip to any port 19999

# 或使用 Nginx 反向代理 + 认证
sudo apt install apache2-utils
sudo htpasswd -c /etc/nginx/.htpasswd admin

# Nginx 配置
server {
    listen 80;
    server_name monitor.dacong.com;
    
    location / {
        proxy_pass http://localhost:19999;
        auth_basic "Restricted";
        auth_basic_user_file /etc/nginx/.htpasswd;
    }
}
```

### 4.2 配置 Prometheus + Grafana（高级）

**安装 Prometheus**：
```bash
# 下载 Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
tar xvfz prometheus-*.tar.gz
cd prometheus-*

# 配置 prometheus.yml
cat > prometheus.yml <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
  
  - job_name: 'dacong-spider'
    static_configs:
      - targets: ['localhost:8000']
EOF

# 启动 Prometheus
./prometheus --config.file=prometheus.yml
```

**安装 Node Exporter**：
```bash
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.0/node_exporter-1.6.0.linux-amd64.tar.gz
tar xvfz node_exporter-*.tar.gz
cd node_exporter-*
./node_exporter
```

**安装 Grafana**：
```bash
sudo apt-get install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo apt-get update
sudo apt-get install grafana

sudo systemctl start grafana-server
sudo systemctl enable grafana-server

# 访问 http://your-vps-ip:3000
# 默认账号：admin/admin
```

**导入 Dashboard**：
1. 访问 Grafana > Dashboards > Import
2. 输入 Dashboard ID：
   - Node Exporter Full: `1860`
   - PostgreSQL: `9628`
3. 选择 Prometheus 数据源
4. 点击 Import

---

## 5. 日志聚合

### 5.1 配置 Loki + Promtail（推荐）

**安装 Loki**：
```bash
# 下载 Loki
wget https://github.com/grafana/loki/releases/download/v2.8.0/loki-linux-amd64.zip
unzip loki-linux-amd64.zip
chmod +x loki-linux-amd64

# 配置 loki-config.yaml
cat > loki-config.yaml <<EOF
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /tmp/loki/boltdb-shipper-active
    cache_location: /tmp/loki/boltdb-shipper-cache
    shared_store: filesystem
  filesystem:
    directory: /tmp/loki/chunks
EOF

# 启动 Loki
./loki-linux-amd64 -config.file=loki-config.yaml
```

**安装 Promtail**：
```bash
# 下载 Promtail
wget https://github.com/grafana/loki/releases/download/v2.8.0/promtail-linux-amd64.zip
unzip promtail-linux-amd64.zip
chmod +x promtail-linux-amd64

# 配置 promtail-config.yaml
cat > promtail-config.yaml <<EOF
server:
  http_listen_port: 9080

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://localhost:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*log
  
  - job_name: dacong-spider
    static_configs:
      - targets:
          - localhost
        labels:
          job: dacong-spider
          __path__: /var/log/dacong-spider*.log
EOF

# 启动 Promtail
./promtail-linux-amd64 -config.file=promtail-config.yaml
```

**在 Grafana 中配置 Loki**：
1. Grafana > Configuration > Data Sources
2. Add data source > Loki
3. URL: `http://localhost:3100`
4. Save & Test

### 5.2 查询日志

**LogQL 查询示例**：
```logql
# 查看所有爬虫日志
{job="dacong-spider"}

# 查看错误日志
{job="dacong-spider"} |= "ERROR"

# 查看最近 1 小时的错误
{job="dacong-spider"} |= "ERROR" [1h]

# 统计错误数量
sum(count_over_time({job="dacong-spider"} |= "ERROR" [5m]))
```

---

## 6. 应用性能监控（APM）

### 6.1 自定义性能指标

**Flutter 性能追踪**：
```dart
// lib/utils/performance.dart
import 'package:sentry_flutter/sentry_flutter.dart';

class PerformanceMonitor {
  static Future<T> trace<T>(
    String operation,
    Future<T> Function() function,
  ) async {
    final transaction = Sentry.startTransaction(
      operation,
      'task',
    );
    
    try {
      final result = await function();
      transaction.status = SpanStatus.ok();
      return result;
    } catch (e) {
      transaction.status = SpanStatus.internalError();
      rethrow;
    } finally {
      await transaction.finish();
    }
  }
}

// 使用示例
final data = await PerformanceMonitor.trace(
  'fetch_content_list',
  () => supabase.from('published_content').select(),
);
```

**Edge Functions 性能追踪**：
```typescript
// supabase/functions/_shared/performance.ts
export async function measurePerformance<T>(
  operation: string,
  fn: () => Promise<T>
): Promise<T> {
  const start = Date.now();
  try {
    const result = await fn();
    const duration = Date.now() - start;
    console.log(`[PERF] ${operation}: ${duration}ms`);
    return result;
  } catch (error) {
    const duration = Date.now() - start;
    console.error(`[PERF] ${operation} failed after ${duration}ms`);
    throw error;
  }
}

// 使用示例
const result = await measurePerformance('calculate_rank', async () => {
  return await calculateRank(contentId);
});
```

### 6.2 关键指标监控

**前端指标**：
- 首屏加载时间（FCP）
- 可交互时间（TTI）
- 最大内容绘制（LCP）
- 累积布局偏移（CLS）
- 首次输入延迟（FID）

**后端指标**：
- API 响应时间（P50, P95, P99）
- 数据库查询时间
- Edge Functions 执行时间
- 错误率
- 请求吞吐量

---

## 7. 告警配置

### 7.1 告警渠道

#### Email 告警

**配置 Sentry Email**：
1. Sentry > Settings > Notifications
2. 添加邮箱地址
3. 配置告警规则

#### Slack 告警

**集成 Slack**：
1. 创建 Slack Webhook：
   - 访问 https://api.slack.com/apps
   - Create New App > Incoming Webhooks
   - 复制 Webhook URL

2. 配置 Sentry Slack 集成：
   - Sentry > Settings > Integrations > Slack
   - 添加 Webhook URL
   - 选择通知频道

#### Telegram 告警

**创建 Telegram Bot**：
```bash
# 1. 与 @BotFather 对话创建 Bot
# 2. 获取 Bot Token
# 3. 获取 Chat ID（发送消息给 Bot，访问 https://api.telegram.org/bot<TOKEN>/getUpdates）

# 发送告警脚本
cat > /usr/local/bin/telegram-alert.sh <<'EOF'
#!/bin/bash
TOKEN="your-bot-token"
CHAT_ID="your-chat-id"
MESSAGE="$1"

curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
  -d chat_id="${CHAT_ID}" \
  -d text="${MESSAGE}" \
  -d parse_mode="Markdown"
EOF

chmod +x /usr/local/bin/telegram-alert.sh

# 测试
/usr/local/bin/telegram-alert.sh "Test alert from DaCong"
```

### 7.2 告警规则

**创建告警脚本**：
```bash
# /home/dacong/scripts/check-health.sh
#!/bin/bash

# 检查爬虫服务
if ! systemctl is-active --quiet dacong-spider; then
    /usr/local/bin/telegram-alert.sh "⚠️ 爬虫服务已停止"
fi

# 检查磁盘空间
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    /usr/local/bin/telegram-alert.sh "⚠️ 磁盘使用率: ${DISK_USAGE}%"
fi

# 检查内存使用
MEM_USAGE=$(free | awk 'NR==2 {printf "%.0f", $3/$2 * 100}')
if [ $MEM_USAGE -gt 90 ]; then
    /usr/local/bin/telegram-alert.sh "⚠️ 内存使用率: ${MEM_USAGE}%"
fi

# 检查 API 可用性
if ! curl -sf https://api.dacong.com/health > /dev/null; then
    /usr/local/bin/telegram-alert.sh "⚠️ API 不可用"
fi
```

**配置 Cron 任务**：
```bash
# 每 5 分钟检查一次
crontab -e

# 添加
*/5 * * * * /home/dacong/scripts/check-health.sh
```

---

## 8. 监控仪表板

### 8.1 创建 Grafana 仪表板

**推荐面板**：

1. **系统概览**
   - CPU 使用率
   - 内存使用率
   - 磁盘使用率
   - 网络流量

2. **应用性能**
   - API 请求数
   - API 响应时间（P50, P95, P99）
   - 错误率
   - 活跃用户数

3. **数据库性能**
   - 连接数
   - 查询时间
   - 慢查询数量
   - 缓存命中率

4. **爬虫状态**
   - 爬取成功率
   - 爬取速度
   - 队列长度
   - 错误数量

### 8.2 导出仪表板配置

```bash
# 导出 Grafana 仪表板
curl -H "Authorization: Bearer <api-key>" \
  http://localhost:3000/api/dashboards/uid/<dashboard-uid> \
  > dashboard.json
```

---

## 9. 监控检查清单

### 应用监控
- [ ] Sentry 错误追踪已配置
- [ ] 性能监控已启用
- [ ] 用户上下文已添加
- [ ] 面包屑已配置
- [ ] 告警规则已创建

### 基础设施监控
- [ ] 服务器监控已安装（Netdata/Prometheus）
- [ ] 磁盘空间监控
- [ ] 内存使用监控
- [ ] CPU 使用监控
- [ ] 网络流量监控

### 日志监控
- [ ] 日志聚合已配置（Loki/ELK）
- [ ] 应用日志已收集
- [ ] 系统日志已收集
- [ ] 日志保留策略已配置

### 告警配置
- [ ] Email 告警已配置
- [ ] Slack 告警已配置
- [ ] Telegram 告警已配置
- [ ] 告警规则已测试
- [ ] 值班人员已配置

---

## 10. 常见问题

### Sentry 未收到错误

**解决方案**：
1. 检查 DSN 是否正确
2. 检查网络连接
3. 检查 Sentry 配额是否用完
4. 手动发送测试错误：
```dart
await Sentry.captureException(Exception('Test error'));
```

### Grafana 无法连接 Prometheus

**解决方案**：
1. 检查 Prometheus 是否运行：`curl http://localhost:9090`
2. 检查防火墙规则
3. 检查 Grafana 数据源配置

### 日志未被收集

**解决方案**：
1. 检查 Promtail 是否运行
2. 检查日志文件路径是否正确
3. 检查文件权限
4. 查看 Promtail 日志：`journalctl -u promtail -f`

---

## 下一步

1. 配置备份策略：[BACKUP_RECOVERY.md](./BACKUP_RECOVERY.md)
2. 完成部署检查清单：[DEPLOYMENT_CHECKLIST_PRODUCTION.md](./DEPLOYMENT_CHECKLIST_PRODUCTION.md)
3. 阅读故障排查指南：[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
