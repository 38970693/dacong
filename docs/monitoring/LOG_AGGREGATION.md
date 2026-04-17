# 日志聚合系统文档

## 概述

大聪项目采用 **Grafana Loki + Promtail** 作为集中式日志聚合方案，实现所有服务的日志统一收集、查询和分析。

### 架构优势

- **轻量级**：相比 ELK Stack，资源占用更少
- **成本低**：不需要索引全部日志内容，只索引标签
- **易集成**：与 Grafana 无缝集成，统一监控和日志平台
- **高性能**：支持高并发日志写入和查询
- **灵活查询**：LogQL 查询语言强大且易学

---

## 系统架构

```
┌─────────────────┐
│  dacong-client  │──┐
│   (Flutter)     │  │
└─────────────────┘  │
                     │
┌─────────────────┐  │    ┌──────────────┐    ┌──────────────┐
│   dacong-api    │──┼───→│   Promtail   │───→│     Loki     │
│  (Supabase)     │  │    │ (日志收集器)  │    │  (日志存储)   │
└─────────────────┘  │    └──────────────┘    └──────────────┘
                     │                               │
┌─────────────────┐  │                               │
│ dacong-spider   │──┘                               ↓
│   (Python)      │                          ┌──────────────┐
└─────────────────┘                          │   Grafana    │
                                             │  (日志查询)   │
                                             └──────────────┘
```

### 组件说明

1. **应用服务**：生成结构化 JSON 日志，写入本地文件
2. **Promtail**：监控日志文件，实时采集并推送到 Loki
3. **Loki**：存储日志数据，提供查询 API
4. **Grafana**：可视化界面，支持日志查询、分析和告警

---

## 部署指南

### 前置要求

- Docker 20.10+
- Docker Compose 1.29+
- 至少 2GB 可用内存
- 至少 10GB 可用磁盘空间

### 快速部署

```bash
# 1. 克隆项目
cd /path/to/dacong

# 2. 创建日志目录
mkdir -p logs/{api,spider,client}

# 3. 运行部署脚本
./scripts/setup_logging.sh

# 4. 验证服务状态
docker-compose -f docker-compose.logging.yml ps
```

### 手动部署

```bash
# 启动服务
docker-compose -f docker-compose.logging.yml up -d

# 查看日志
docker-compose -f docker-compose.logging.yml logs -f

# 停止服务
docker-compose -f docker-compose.logging.yml down

# 重启服务
docker-compose -f docker-compose.logging.yml restart
```

### 访问服务

- **Grafana**: http://localhost:3000
  - 默认账号: `admin`
  - 默认密码: `admin` (首次登录后需修改)
- **Loki API**: http://localhost:3100

---

## 日志格式规范

### 统一 JSON 格式

所有服务的日志必须遵循以下 JSON 格式：

```json
{
  "timestamp": "2026-04-17T12:00:00Z",
  "level": "INFO",
  "service": "dacong-api",
  "function": "recommend",
  "message": "Recommendation generated",
  "context": {
    "user_id": "uuid",
    "scenario_id": "uuid",
    "duration_ms": 150
  }
}
```

### 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `timestamp` | string | 是 | ISO 8601 格式的 UTC 时间 |
| `level` | string | 是 | 日志级别：DEBUG, INFO, WARN, ERROR |
| `service` | string | 是 | 服务名称：dacong-api, dacong-spider, dacong-client |
| `function` | string | 是 | 函数/模块名称 |
| `message` | string | 是 | 日志消息 |
| `context` | object | 否 | 上下文信息（键值对） |
| `error` | object | 否 | 错误信息（仅 ERROR 级别） |

### 错误日志格式

```json
{
  "timestamp": "2026-04-17T12:00:00Z",
  "level": "ERROR",
  "service": "dacong-api",
  "function": "recommend",
  "message": "Failed to generate recommendation",
  "context": {
    "user_id": "uuid",
    "scenario_id": "uuid"
  },
  "error": {
    "type": "DatabaseError",
    "message": "Connection timeout",
    "stack_trace": "..."
  }
}
```

---

## 日志记录器使用

### Flutter 客户端

```dart
import 'package:dacong_client/core/logging/logger.dart';

// 创建日志实例
final logger = createLogger('HomeScreen');

// 记录不同级别的日志
logger.debug('Debug message', context: {'key': 'value'});
logger.info('Info message');
logger.warn('Warning message');
logger.error('Error message', error: exception, stackTrace: stackTrace);

// 记录性能日志
logger.logPerformance('load_data', 150);

// 记录页面访问
logger.logPageView('HomeScreen');

// 记录用户操作
logger.logUserAction('click_button', context: {'button': 'submit'});

// 记录 API 请求
logger.logApiRequest('GET', '/api/recommendations');

// 记录 API 响应
logger.logApiResponse('GET', '/api/recommendations', 200, 150);
```

### TypeScript API

```typescript
import { createLogger } from './_shared/utils/logger';

// 创建日志实例
const logger = createLogger('recommend');

// 记录不同级别的日志
logger.debug('Debug message', { key: 'value' });
logger.info('Info message');
logger.warn('Warning message');
logger.error('Error message', error, { key: 'value' });

// 记录性能日志
logger.logPerformance('generate_recommendation', 150);

// 记录请求日志
logger.logRequest('POST', '/recommend', { user_id: 'uuid' });

// 记录响应日志
logger.logResponse('POST', '/recommend', 200, 150);
```

### Python 爬虫

```python
from core.logger import create_logger

# 创建日志实例
logger = create_logger('xiaohongshu_spider')

# 记录不同级别的日志
logger.debug('Debug message', key='value')
logger.info('Info message')
logger.warn('Warning message')
logger.error('Error message', exc_info=exception)

# 记录性能日志
logger.log_performance('parse_page', 150.5)

# 记录爬取开始
logger.log_scrape_start('https://example.com')

# 记录爬取成功
logger.log_scrape_success('https://example.com', items_count=10, duration_ms=500)

# 记录爬取失败
logger.log_scrape_error('https://example.com', error=exception)
```

---

## LogQL 查询语法

### 基础查询

```logql
# 查询特定服务的日志
{service="dacong-api"}

# 查询特定级别的日志
{service="dacong-api"} |= "ERROR"

# 查询特定函数的日志
{service="dacong-api", function="recommend"}

# 正则匹配
{service="dacong-api"} |~ "error|failed"

# 排除特定内容
{service="dacong-api"} != "health check"
```

### JSON 解析

```logql
# 解析 JSON 字段
{service="dacong-api"} | json

# 过滤 JSON 字段
{service="dacong-api"} | json | duration_ms > 1000

# 提取 JSON 字段
{service="dacong-api"} | json | line_format "{{.function}}: {{.message}}"
```

### 聚合查询

```logql
# 统计日志数量
count_over_time({service="dacong-api"} [5m])

# 计算速率
rate({service="dacong-api"} [5m])

# 按标签分组
sum(rate({service="dacong-api"} [5m])) by (function)

# 计算错误率
sum(rate({service="dacong-api"} |= "ERROR" [5m])) 
/ 
sum(rate({service="dacong-api"} [5m]))
```

### 高级查询

```logql
# 查询慢请求
{service="dacong-api"} 
| json 
| duration_ms > 1000 
| line_format "{{.function}} took {{.duration_ms}}ms"

# 查询特定用户的操作
{service="dacong-api"} 
| json 
| context_user_id="uuid-here"

# 查询爬虫失败原因
{service="dacong-spider"} 
|= "Scrape failed" 
| json 
| line_format "{{.context_url}}: {{.error_message}}"

# 查询 API 错误并按接口分组
sum by (context_path) (
  count_over_time({service="dacong-api"} |= "ERROR" [1h])
)
```

---

## Grafana 面板配置

### 创建日志查询面板

1. 登录 Grafana (http://localhost:3000)
2. 点击 **Explore** 或创建新 Dashboard
3. 选择 **Loki** 数据源
4. 输入 LogQL 查询
5. 调整时间范围和刷新间隔
6. 保存面板

### 推荐面板

#### 1. 实时日志流

```logql
{service=~"dacong-.*"}
```

配置：
- Visualization: Logs
- Time range: Last 15 minutes
- Refresh: 5s

#### 2. 错误日志统计

```logql
sum(rate({service=~"dacong-.*"} |= "ERROR" [5m])) by (service)
```

配置：
- Visualization: Time series
- Legend: {{service}}

#### 3. 请求响应时间分布

```logql
histogram_quantile(0.95, 
  sum(rate({service="dacong-api"} | json | __error__="" [5m])) by (le)
)
```

配置：
- Visualization: Time series
- Unit: milliseconds

#### 4. 服务日志量对比

```logql
sum(rate({service=~"dacong-.*"} [5m])) by (service)
```

配置：
- Visualization: Bar chart
- Legend: {{service}}

#### 5. Top 10 错误消息

```logql
topk(10,
  sum by (message) (
    count_over_time({service=~"dacong-.*"} |= "ERROR" [1h])
  )
)
```

配置：
- Visualization: Table
- Sort: Descending

---

## 日志保留策略

### 配置说明

在 `config/loki-config.yaml` 中配置：

```yaml
limits_config:
  retention_period: 720h  # 30 天

compactor:
  retention_enabled: true
  retention_delete_delay: 2h
```

### 分层存储策略

| 数据类型 | 保留时间 | 存储位置 | 查询性能 |
|---------|---------|---------|---------|
| 热数据 | 7 天 | 本地 SSD | 快速 |
| 温数据 | 30 天 | 本地 HDD | 正常 |
| 冷数据 | 90 天 | 对象存储 | 较慢 |

### 归档配置（可选）

如需长期归档，可配置对象存储：

```yaml
storage_config:
  aws:
    s3: s3://region/bucket-name
    s3forcepathstyle: true
```

---

## 故障排查

### Loki 无法启动

**症状**：`docker-compose logs loki` 显示错误

**排查步骤**：
1. 检查配置文件语法：`docker run --rm -v $(pwd)/config:/config grafana/loki:latest -config.file=/config/loki-config.yaml -verify-config`
2. 检查目录权限：`chmod -R 755 logs/`
3. 检查端口占用：`netstat -tuln | grep 3100`
4. 查看详细日志：`docker-compose -f docker-compose.logging.yml logs loki`

### Promtail 无法采集日志

**症状**：Grafana 中查询不到日志

**排查步骤**：
1. 检查日志文件是否存在：`ls -la logs/`
2. 检查 Promtail 配置：`docker-compose -f docker-compose.logging.yml logs promtail`
3. 验证 Loki 连接：`curl http://localhost:3100/ready`
4. 检查日志文件权限：`chmod 644 logs/**/*.log`

### Grafana 无法连接 Loki

**症状**：Grafana 中数据源显示错误

**排查步骤**：
1. 验证 Loki 服务：`curl http://localhost:3100/ready`
2. 检查网络连接：`docker network inspect dacong_logging`
3. 重新配置数据源：Grafana UI → Configuration → Data sources
4. 检查 Grafana 日志：`docker-compose -f docker-compose.logging.yml logs grafana`

### 日志查询慢

**症状**：LogQL 查询超时或响应慢

**优化方法**：
1. 缩小时间范围（从 24h 改为 1h）
2. 添加更多标签过滤（service, function）
3. 使用 `| json` 前先用 `|=` 过滤
4. 增加 Loki 内存配置
5. 启用查询缓存

### 磁盘空间不足

**症状**：Loki 停止写入或报错

**解决方法**：
1. 清理旧日志：`docker exec dacong-loki rm -rf /loki/chunks/*`
2. 调整保留策略：减少 `retention_period`
3. 配置对象存储：迁移到 S3/MinIO
4. 增加磁盘空间

---

## 性能优化

### Loki 性能调优

```yaml
# config/loki-config.yaml
limits_config:
  ingestion_rate_mb: 20          # 增加写入速率
  ingestion_burst_size_mb: 40    # 增加突发写入
  max_query_parallelism: 64      # 增加查询并发

chunk_store_config:
  chunk_cache_config:
    enable_fifocache: true
    fifocache:
      max_size_bytes: 1GB        # 增加缓存
```

### Promtail 性能调优

```yaml
# config/promtail-config.yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

clients:
  - url: http://loki:3100/loki/api/v1/push
    batchwait: 1s                # 批量等待时间
    batchsize: 1048576           # 批量大小 1MB
```

### 查询优化建议

1. **使用标签过滤**：优先使用 `{service="dacong-api"}` 而不是全文搜索
2. **缩小时间范围**：避免查询超过 24 小时的数据
3. **避免正则**：`|=` 比 `|~` 快，能用精确匹配就不用正则
4. **分步过滤**：先用 `|=` 过滤，再用 `| json` 解析
5. **限制结果数量**：使用 `topk()` 或 `limit` 限制返回结果

---

## 安全配置

### 启用认证

```yaml
# config/loki-config.yaml
auth_enabled: true

server:
  http_listen_port: 3100
  grpc_listen_port: 9096
  http_server_read_timeout: 600s
  http_server_write_timeout: 600s
```

### 配置 TLS

```yaml
# config/loki-config.yaml
server:
  http_tls_config:
    cert_file: /path/to/cert.pem
    key_file: /path/to/key.pem
```

### 限制访问

使用 Nginx 反向代理：

```nginx
location /loki/ {
    auth_basic "Restricted";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass http://localhost:3100/;
}
```

---

## 最佳实践

### 日志记录

1. **结构化日志**：始终使用 JSON 格式
2. **合理级别**：DEBUG < INFO < WARN < ERROR
3. **上下文信息**：记录关键业务字段（user_id, request_id）
4. **避免敏感信息**：不记录密码、token、个人隐私
5. **性能日志**：记录关键操作的耗时

### 日志查询

1. **使用标签**：充分利用 service, function 等标签
2. **时间范围**：根据需求选择合适的时间范围
3. **保存查询**：将常用查询保存为 Dashboard
4. **设置告警**：对关键指标设置告警规则

### 运维管理

1. **定期备份**：备份 Loki 数据和配置
2. **监控资源**：监控磁盘、内存、CPU 使用情况
3. **日志轮转**：配置日志文件轮转，避免单文件过大
4. **定期清理**：清理过期日志，释放磁盘空间
5. **文档更新**：及时更新文档和 Runbook

---

## 参考资料

- [Grafana Loki 官方文档](https://grafana.com/docs/loki/latest/)
- [LogQL 查询语法](https://grafana.com/docs/loki/latest/logql/)
- [Promtail 配置指南](https://grafana.com/docs/loki/latest/clients/promtail/)
- [Grafana 告警配置](https://grafana.com/docs/grafana/latest/alerting/)
- [日志最佳实践](https://grafana.com/docs/loki/latest/best-practices/)

---

## 联系支持

如有问题，请联系：
- DevOps 团队：devops@example.com
- Slack 频道：#dacong-logging
- 文档仓库：https://github.com/your-org/dacong/docs
