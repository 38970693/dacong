"""
Sentry 错误监控配置
用于爬虫系统的错误追踪和性能监控
"""
import logging
import os
from typing import Any, Dict, Optional

import sentry_sdk
from sentry_sdk.integrations.logging import LoggingIntegration

logger = logging.getLogger(__name__)


def init_sentry(
    dsn: Optional[str] = None,
    environment: Optional[str] = None,
    release: Optional[str] = None,
    traces_sample_rate: float = 0.2,
    debug: bool = False,
) -> None:
    """
    初始化 Sentry

    Args:
        dsn: Sentry DSN，如果未提供则从环境变量读取
        environment: 环境名称（development/production）
        release: 发布版本
        traces_sample_rate: 性能追踪采样率
        debug: 是否启用调试模式
    """
    dsn = dsn or os.getenv("SENTRY_DSN")

    if not dsn:
        logger.warning("Sentry DSN not configured, skipping initialization")
        return

    # 配置日志集成
    logging_integration = LoggingIntegration(
        level=logging.INFO,  # 捕获 INFO 及以上级别的日志
        event_level=logging.ERROR,  # 将 ERROR 及以上级别作为事件发送
    )

    sentry_sdk.init(
        dsn=dsn,
        environment=environment or os.getenv("ENVIRONMENT", "production"),
        release=release or "dacong-spider@1.0.0",
        traces_sample_rate=traces_sample_rate,
        debug=debug,
        integrations=[logging_integration],
        # 过滤敏感信息
        before_send=_before_send,
        before_breadcrumb=_before_breadcrumb,
    )

    logger.info("Sentry initialized successfully")


def _before_send(event: Dict[str, Any], hint: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """
    发送前过滤敏感信息
    """
    # 移除敏感的环境变量
    if "contexts" in event and "runtime" in event["contexts"]:
        env = event["contexts"]["runtime"].get("env", {})
        sensitive_keys = ["SUPABASE_KEY", "GITHUB_TOKEN", "OPENROUTER_API_KEY", "REDDIT_CLIENT_SECRET"]
        for key in sensitive_keys:
            if key in env:
                env[key] = "***REDACTED***"

    return event


def _before_breadcrumb(crumb: Dict[str, Any], hint: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """
    面包屑过滤
    """
    # 过滤掉过于频繁的日志
    if crumb.get("category") == "log" and crumb.get("level") == "debug":
        return None

    return crumb


def set_user(user_id: str, **kwargs: Any) -> None:
    """
    设置用户上下文

    Args:
        user_id: 用户 ID
        **kwargs: 其他用户属性（email, username 等）
    """
    sentry_sdk.set_user({"id": user_id, **kwargs})


def clear_user() -> None:
    """清除用户上下文"""
    sentry_sdk.set_user(None)


def set_tag(key: str, value: str) -> None:
    """
    设置标签

    Args:
        key: 标签键
        value: 标签值
    """
    sentry_sdk.set_tag(key, value)


def set_context(key: str, context: Dict[str, Any]) -> None:
    """
    设置上下文

    Args:
        key: 上下文键
        context: 上下文数据
    """
    sentry_sdk.set_context(key, context)


def add_breadcrumb(
    message: str,
    category: Optional[str] = None,
    level: str = "info",
    data: Optional[Dict[str, Any]] = None,
) -> None:
    """
    添加面包屑

    Args:
        message: 面包屑消息
        category: 分类
        level: 级别（debug/info/warning/error/fatal）
        data: 附加数据
    """
    sentry_sdk.add_breadcrumb(
        message=message,
        category=category,
        level=level,
        data=data,
    )


def capture_exception(
    exception: Exception,
    level: str = "error",
    extras: Optional[Dict[str, Any]] = None,
) -> None:
    """
    捕获异常

    Args:
        exception: 异常对象
        level: 严重级别
        extras: 额外信息
    """
    with sentry_sdk.push_scope() as scope:
        scope.level = level
        if extras:
            for key, value in extras.items():
                scope.set_extra(key, value)
        sentry_sdk.capture_exception(exception)


def capture_message(
    message: str,
    level: str = "info",
    extras: Optional[Dict[str, Any]] = None,
) -> None:
    """
    捕获消息

    Args:
        message: 消息内容
        level: 严重级别
        extras: 额外信息
    """
    with sentry_sdk.push_scope() as scope:
        scope.level = level
        if extras:
            for key, value in extras.items():
                scope.set_extra(key, value)
        sentry_sdk.capture_message(message)


def start_transaction(name: str, op: str, description: Optional[str] = None):
    """
    开始性能追踪事务

    Args:
        name: 事务名称
        op: 操作类型
        description: 描述

    Returns:
        Transaction 对象
    """
    return sentry_sdk.start_transaction(
        name=name,
        op=op,
        description=description,
    )


def report_spider_error(
    spider_name: str,
    error: Exception,
    url: Optional[str] = None,
    extras: Optional[Dict[str, Any]] = None,
) -> None:
    """
    报告爬虫错误

    Args:
        spider_name: 爬虫名称
        error: 错误对象
        url: 出错的 URL
        extras: 额外信息
    """
    add_breadcrumb(
        message=f"Spider error: {spider_name}",
        category="spider",
        level="error",
        data={"spider": spider_name, "url": url},
    )

    extra_data = {"spider_name": spider_name, "url": url}
    if extras:
        extra_data.update(extras)

    capture_exception(error, level="error", extras=extra_data)


def report_performance_issue(
    operation: str,
    duration_ms: float,
    threshold_ms: float = 3000,
    extras: Optional[Dict[str, Any]] = None,
) -> None:
    """
    报告性能问题

    Args:
        operation: 操作名称
        duration_ms: 持续时间（毫秒）
        threshold_ms: 阈值（毫秒）
        extras: 额外信息
    """
    if duration_ms > threshold_ms:
        extra_data = {
            "operation": operation,
            "duration_ms": duration_ms,
            "threshold_ms": threshold_ms,
        }
        if extras:
            extra_data.update(extras)

        capture_message(
            f"Slow operation: {operation} took {duration_ms:.2f}ms",
            level="warning",
            extras=extra_data,
        )


def report_data_quality_issue(
    issue_type: str,
    description: str,
    spider_name: Optional[str] = None,
    extras: Optional[Dict[str, Any]] = None,
) -> None:
    """
    报告数据质量问题

    Args:
        issue_type: 问题类型
        description: 问题描述
        spider_name: 爬虫名称
        extras: 额外信息
    """
    extra_data = {
        "issue_type": issue_type,
        "spider_name": spider_name,
    }
    if extras:
        extra_data.update(extras)

    capture_message(
        f"Data quality issue: {description}",
        level="warning",
        extras=extra_data,
    )
