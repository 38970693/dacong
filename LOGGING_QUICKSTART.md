# 日志聚合系统快速开始

## 部署

```bash
# 一键部署
./scripts/setup_logging.sh

# 或手动部署
docker-compose -f docker-compose.logging.yml up -d
```

## 测试

```bash
# 运行测试脚本
./scripts/test_logging.sh
```

## 访问

- **Grafana**: http://localhost:3000 (admin/admin)
- **Loki API**: http://localhost:3100

## 使用日志记录器

### Flutter 客户端

```dart
import 'package:dacong_client/core/logging/logger.dart';

final logger = createLogger('HomeScreen');

logger.info('User logged in', context: {'user_id': userId});
logger.error('Failed to load data', error: e, stackTrace: st);
logger.logPerformance('load_recommendations', 150);
```

### TypeScript API

```typescript
import { createLogger } from './_shared/utils/logger';

const logger = createLogger('recommend');

logger.info('Processing recommendation', { user_id: userId });
logger.error('Database error', error, { query: 'SELECT ...' });
logger.logPerformance('generate_recommendation', 150);
```

### Python 爬虫

```python
from core.logger import create_logger

logger = create_logger('xiaohongshu_spider')

logger.info('Starting scrape', url=url)
logger.error('Scrape failed', exc_info=e, url=url)
logger.log_scrape_success(url, items_count=10, duration_ms=500)
```

## 常用 LogQL 查询

```logql
# 查看所有日志
{service=~"dacong-.*"}

# 查看错误日志
{service=~"dacong-.*"} |= "ERROR"

# 查看特定服务
{service="dacong-api"}

# 查看慢请求
{service="dacong-api"} | json | duration_ms > 1000

# 统计错误率
sum(rate({service=~"dacong-.*"} |= "ERROR" [5m])) by (service)
```

## 故障排查

```bash
# 查看服务状态
docker-compose -f docker-compose.logging.yml ps

# 查看日志
docker-compose -f docker-compose.logging.yml logs -f

# 重启服务
docker-compose -f docker-compose.logging.yml restart

# 验证 Loki
curl http://localhost:3100/ready

# 验证 Grafana
curl http://localhost:3000/api/health
```

## 文档

详细文档请查看：
- [日志聚合系统文档](docs/monitoring/LOG_AGGREGATION.md)
- [日志告警规则](docs/monitoring/LOG_ALERTS.md)
