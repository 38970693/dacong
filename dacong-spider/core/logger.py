"""
结构化日志工具
统一的日志格式，便于 Loki 聚合和查询
"""

import json
import logging
import sys
from datetime import datetime
from enum import Enum
from typing import Any, Dict, Optional


class LogLevel(str, Enum):
    DEBUG = "DEBUG"
    INFO = "INFO"
    WARN = "WARN"
    ERROR = "ERROR"


class StructuredLogger:
    """结构化日志记录器"""

    def __init__(self, service: str = "dacong-spider", spider_name: str = "unknown"):
        self.service = service
        self.spider_name = spider_name
        self._setup_logger()

    def _setup_logger(self):
        """配置日志记录器"""
        self.logger = logging.getLogger(f"{self.service}.{self.spider_name}")
        self.logger.setLevel(logging.DEBUG)

        # 移除现有的处理器
        self.logger.handlers.clear()

        # 添加控制台处理器（UTF-8编码）
        handler = logging.StreamHandler(sys.stdout.buffer)
        handler.setLevel(logging.DEBUG)
        self.logger.addHandler(handler)

        # 禁用传播，避免重复日志
        self.logger.propagate = False

    def _format_log(
        self,
        level: LogLevel,
        message: str,
        context: Optional[Dict[str, Any]] = None,
        exc_info: Optional[Exception] = None,
    ) -> str:
        """格式化日志为 JSON"""
        entry = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": level.value,
            "service": self.service,
            "spider_name": self.spider_name,
            "message": message,
        }

        if context:
            entry["context"] = context

        if exc_info:
            entry["error"] = {
                "type": type(exc_info).__name__,
                "message": str(exc_info),
                "traceback": self._format_exception(exc_info),
            }

        return json.dumps(entry, ensure_ascii=False)

    def _format_exception(self, exc: Exception) -> str:
        """格式化异常信息"""
        import traceback
        return "".join(traceback.format_exception(type(exc), exc, exc.__traceback__))

    def debug(self, message: str, **kwargs):
        """记录 DEBUG 级别日志"""
        log_message = self._format_log(LogLevel.DEBUG, message, kwargs if kwargs else None)
        self.logger.debug(log_message)

    def info(self, message: str, **kwargs):
        """记录 INFO 级别日志"""
        log_message = self._format_log(LogLevel.INFO, message, kwargs if kwargs else None)
        self.logger.info(log_message)

    def warn(self, message: str, **kwargs):
        """记录 WARN 级别日志"""
        log_message = self._format_log(LogLevel.WARN, message, kwargs if kwargs else None)
        self.logger.warning(log_message)

    def error(self, message: str, exc_info: Optional[Exception] = None, **kwargs):
        """记录 ERROR 级别日志"""
        log_message = self._format_log(LogLevel.ERROR, message, kwargs if kwargs else None, exc_info)
        self.logger.error(log_message)

    def log_performance(self, operation: str, duration_ms: float, **kwargs):
        """记录性能日志"""
        context = {**kwargs, "duration_ms": duration_ms, "operation": operation}
        self.info(f"Performance: {operation}", **context)

    def log_scrape_start(self, url: str, **kwargs):
        """记录爬取开始"""
        context = {**kwargs, "url": url}
        self.info(f"Scrape started: {url}", **context)

    def log_scrape_success(self, url: str, items_count: int, duration_ms: float, **kwargs):
        """记录爬取成功"""
        context = {
            **kwargs,
            "url": url,
            "items_count": items_count,
            "duration_ms": duration_ms,
        }
        self.info(f"Scrape completed: {url}", **context)

    def log_scrape_error(self, url: str, error: Exception, **kwargs):
        """记录爬取失败"""
        context = {**kwargs, "url": url}
        self.error(f"Scrape failed: {url}", exc_info=error, **context)


def create_logger(spider_name: str) -> StructuredLogger:
    """创建日志实例的工厂函数"""
    return StructuredLogger(service="dacong-spider", spider_name=spider_name)


# 示例用法
if __name__ == "__main__":
    logger = create_logger("test_spider")

    logger.info("Spider started", spider_version="1.0.0")
    logger.debug("Debug information", detail="some detail")
    logger.warn("Warning message", reason="rate limit approaching")

    try:
        raise ValueError("Test error")
    except Exception as e:
        logger.error("An error occurred", exc_info=e, url="https://example.com")

    logger.log_performance("parse_page", 150.5, page_size=1024)
