"""
DaCong Spider - 面向对象爬虫系统

核心组件：
- core.interfaces: 接口定义
- core.implementations: 基础实现
- core.spider_base: 爬虫基类
- core.storage: 存储实现
- core.factory: 工厂和注册表
- spiders: 具体爬虫实现
- schedulers: 调度器
"""

__version__ = "2.0.0"
__author__ = "DaCong Team"

from core.interfaces import (
    ISpider,
    IHttpClient,
    IDataProcessor,
    IDataStorage,
    IDeduplicator,
    IRetryStrategy,
    IScheduler,
    ILogger,
    MetricSource,
    DataType,
    RawData,
    SpiderResult,
)

from core.factory import (
    SpiderFactory,
    SpiderRegistry,
)

from core.storage import (
    SupabaseStorage,
    InMemoryStorage,
)

__all__ = [
    # 接口
    "ISpider",
    "IHttpClient",
    "IDataProcessor",
    "IDataStorage",
    "IDeduplicator",
    "IRetryStrategy",
    "IScheduler",
    "ILogger",
    # 枚举
    "MetricSource",
    "DataType",
    # DTOs
    "RawData",
    "SpiderResult",
    # 工厂
    "SpiderFactory",
    "SpiderRegistry",
    # 存储
    "SupabaseStorage",
    "InMemoryStorage",
]
