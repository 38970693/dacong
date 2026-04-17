# Sentry 集成说明 - 爬虫系统

## 环境变量配置

在 `.env` 文件中添加：

```bash
SENTRY_DSN=your_sentry_dsn_here
ENVIRONMENT=production  # 或 development
```

## 使用方法

### 1. 自动集成

系统启动时会自动初始化 Sentry，无需额外配置。

```bash
# 生产环境
python main.py

# 开发环境（启用调试）
python main.py --debug
```

### 2. 手动捕获异常

```python
from core.sentry_config import capture_exception, capture_message

try:
    # 业务逻辑
    result = risky_operation()
except Exception as e:
    capture_exception(
        e,
        level="error",
        extras={
            "operation": "risky_operation",
            "context": "additional_info",
        }
    )
    raise
```

### 3. 报告爬虫错误

```python
from core.sentry_config import report_spider_error

try:
    await spider.crawl(url)
except Exception as e:
    report_spider_error(
        spider_name="github",
        error=e,
        url=url,
        extras={"page": page_num}
    )
```

### 4. 添加面包屑

```python
from core.sentry_config import add_breadcrumb

add_breadcrumb(
    message="开始爬取 GitHub 仓库",
    category="spider",
    level="info",
    data={"repo": repo_name}
)
```

### 5. 性能追踪

```python
from core.sentry_config import start_transaction, report_performance_issue
import time

# 方式 1: 使用事务
transaction = start_transaction(
    name="crawl-github",
    op="spider.crawl",
    description="爬取 GitHub 数据"
)

try:
    await crawl_github()
    transaction.set_status("ok")
except Exception as e:
    transaction.set_status("internal_error")
    raise
finally:
    transaction.finish()

# 方式 2: 报告慢操作
start_time = time.time()
await slow_operation()
duration_ms = (time.time() - start_time) * 1000

report_performance_issue(
    operation="slow_operation",
    duration_ms=duration_ms,
    threshold_ms=3000,
    extras={"details": "additional_context"}
)
```

### 6. 设置上下文

```python
from core.sentry_config import set_user, set_tag, set_context

# 设置用户（如果适用）
set_user(user_id="spider-bot")

# 设置标签
set_tag("spider_name", "github")
set_tag("version", "1.0.0")

# 设置上下文
set_context("spider", {
    "name": "github",
    "interval_hours": 24,
    "last_run": "2024-01-01T00:00:00Z"
})
```

### 7. 报告数据质量问题

```python
from core.sentry_config import report_data_quality_issue

report_data_quality_issue(
    issue_type="missing_field",
    description="GitHub 仓库缺少 stars 字段",
    spider_name="github",
    extras={
        "repo": repo_name,
        "url": url
    }
)
```

## 功能特性

- ✅ 自动捕获未处理的异常
- ✅ 日志集成（INFO 及以上级别）
- ✅ 性能追踪和监控
- ✅ 面包屑记录
- ✅ 敏感信息自动过滤（API keys, tokens）
- ✅ 环境标签
- ✅ 爬虫特定的错误报告
- ✅ 数据质量问题追踪

## 集成示例

查看 `main.py` 中的完整集成示例：
- 系统启动时初始化 Sentry
- 爬虫运行时自动捕获错误
- 性能问题自动报告

## 最佳实践

### 1. 在爬虫中使用

```python
from core.sentry_config import (
    add_breadcrumb,
    report_spider_error,
    report_performance_issue,
    start_transaction
)

class MySpider:
    async def run(self):
        transaction = start_transaction(
            name=f"spider-{self.name}",
            op="spider.run"
        )

        try:
            add_breadcrumb(
                message=f"开始运行爬虫: {self.name}",
                category="spider",
                level="info"
            )

            start_time = time.time()
            await self.crawl()
            duration_ms = (time.time() - start_time) * 1000

            # 报告慢操作
            report_performance_issue(
                operation=f"spider-{self.name}",
                duration_ms=duration_ms,
                threshold_ms=60000  # 1分钟
            )

            transaction.set_status("ok")

        except Exception as e:
            report_spider_error(
                spider_name=self.name,
                error=e,
                extras={"stage": "crawl"}
            )
            transaction.set_status("internal_error")
            raise
        finally:
            transaction.finish()
```

### 2. 在数据处理中使用

```python
from core.sentry_config import report_data_quality_issue, add_breadcrumb

def process_data(data):
    # 验证数据质量
    if not data.get("required_field"):
        report_data_quality_issue(
            issue_type="missing_required_field",
            description="数据缺少必需字段",
            extras={"data_id": data.get("id")}
        )

    add_breadcrumb(
        message="数据处理完成",
        category="data",
        level="info",
        data={"record_count": len(data)}
    )
```

## 注意事项

1. 生产环境必须配置 `SENTRY_DSN`
2. 敏感信息会自动过滤（SUPABASE_KEY, GITHUB_TOKEN 等）
3. 采样率已针对环境优化（开发 100%，生产 20%）
4. 日志级别 ERROR 及以上会自动发送到 Sentry
5. 调试日志不会记录到面包屑中
