"""
爬虫监控模块

职责：
- 监控爬取成功率
- 统计平均响应时间
- 记录错误信息
- 生成监控报告
"""
import logging
import time
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Optional
from collections import defaultdict

logger = logging.getLogger(__name__)


@dataclass
class CrawlMetrics:
    """单次爬取指标"""
    spider_name: str
    start_time: datetime
    end_time: Optional[datetime] = None
    success: bool = False
    items_fetched: int = 0
    items_written: int = 0
    response_time: float = 0.0
    error_message: Optional[str] = None


@dataclass
class SpiderStats:
    """爬虫统计信息"""
    spider_name: str
    total_runs: int = 0
    successful_runs: int = 0
    failed_runs: int = 0
    total_items_fetched: int = 0
    total_items_written: int = 0
    total_response_time: float = 0.0
    errors: list[str] = field(default_factory=list)
    last_run_time: Optional[datetime] = None
    last_success_time: Optional[datetime] = None

    @property
    def success_rate(self) -> float:
        """成功率"""
        if self.total_runs == 0:
            return 0.0
        return (self.successful_runs / self.total_runs) * 100

    @property
    def avg_response_time(self) -> float:
        """平均响应时间"""
        if self.successful_runs == 0:
            return 0.0
        return self.total_response_time / self.successful_runs

    @property
    def avg_items_per_run(self) -> float:
        """平均每次爬取数据量"""
        if self.successful_runs == 0:
            return 0.0
        return self.total_items_written / self.successful_runs


class CrawlerMonitor:
    """
    爬虫监控器

    特性：
    - 实时监控爬取状态
    - 统计成功率和性能指标
    - 错误追踪和报警
    - 生成监控报告
    """

    def __init__(self, max_error_history: int = 100):
        """
        初始化监控器

        Args:
            max_error_history: 最大错误历史记录数
        """
        self.stats: dict[str, SpiderStats] = defaultdict(
            lambda: SpiderStats(spider_name="")
        )
        self.max_error_history = max_error_history
        self.active_crawls: dict[str, CrawlMetrics] = {}

        logger.info("爬虫监控器初始化完成")

    def start_crawl(self, spider_name: str) -> str:
        """
        开始监控一次爬取

        Args:
            spider_name: 爬虫名称

        Returns:
            爬取 ID
        """
        crawl_id = f"{spider_name}_{int(time.time() * 1000)}"

        metrics = CrawlMetrics(
            spider_name=spider_name,
            start_time=datetime.now()
        )

        self.active_crawls[crawl_id] = metrics

        logger.info(f"开始监控爬取: {spider_name} (ID: {crawl_id})")

        return crawl_id

    def end_crawl(
        self,
        crawl_id: str,
        success: bool,
        items_fetched: int = 0,
        items_written: int = 0,
        error_message: Optional[str] = None
    ):
        """
        结束监控一次爬取

        Args:
            crawl_id: 爬取 ID
            success: 是否成功
            items_fetched: 抓取的数据量
            items_written: 写入的数据量
            error_message: 错误信息
        """
        if crawl_id not in self.active_crawls:
            logger.warning(f"未找到活跃的爬取: {crawl_id}")
            return

        metrics = self.active_crawls[crawl_id]
        metrics.end_time = datetime.now()
        metrics.success = success
        metrics.items_fetched = items_fetched
        metrics.items_written = items_written
        metrics.error_message = error_message
        metrics.response_time = (
            metrics.end_time - metrics.start_time
        ).total_seconds()

        # 更新统计信息
        self._update_stats(metrics)

        # 移除活跃爬取
        del self.active_crawls[crawl_id]

        logger.info(
            f"结束监控爬取: {metrics.spider_name} "
            f"(成功: {success}, 耗时: {metrics.response_time:.2f}s)"
        )

    def _update_stats(self, metrics: CrawlMetrics):
        """
        更新统计信息

        Args:
            metrics: 爬取指标
        """
        stats = self.stats[metrics.spider_name]
        stats.spider_name = metrics.spider_name
        stats.total_runs += 1
        stats.last_run_time = metrics.end_time

        if metrics.success:
            stats.successful_runs += 1
            stats.total_items_fetched += metrics.items_fetched
            stats.total_items_written += metrics.items_written
            stats.total_response_time += metrics.response_time
            stats.last_success_time = metrics.end_time
        else:
            stats.failed_runs += 1

            # 记录错误
            if metrics.error_message:
                stats.errors.append(
                    f"[{metrics.end_time.isoformat()}] {metrics.error_message}"
                )

                # 限制错误历史大小
                if len(stats.errors) > self.max_error_history:
                    stats.errors = stats.errors[-self.max_error_history:]

    def get_spider_stats(self, spider_name: str) -> Optional[SpiderStats]:
        """
        获取爬虫统计信息

        Args:
            spider_name: 爬虫名称

        Returns:
            统计信息，如果不存在返回 None
        """
        return self.stats.get(spider_name)

    def get_all_stats(self) -> dict[str, SpiderStats]:
        """
        获取所有爬虫统计信息

        Returns:
            爬虫名称到统计信息的映射
        """
        return dict(self.stats)

    def get_summary(self) -> dict:
        """
        获取监控摘要

        Returns:
            监控摘要字典
        """
        total_runs = sum(s.total_runs for s in self.stats.values())
        total_success = sum(s.successful_runs for s in self.stats.values())
        total_failed = sum(s.failed_runs for s in self.stats.values())

        overall_success_rate = (
            (total_success / total_runs * 100) if total_runs > 0 else 0.0
        )

        return {
            "total_spiders": len(self.stats),
            "total_runs": total_runs,
            "successful_runs": total_success,
            "failed_runs": total_failed,
            "overall_success_rate": round(overall_success_rate, 2),
            "active_crawls": len(self.active_crawls),
            "spiders": [
                {
                    "name": stats.spider_name,
                    "total_runs": stats.total_runs,
                    "success_rate": round(stats.success_rate, 2),
                    "avg_response_time": round(stats.avg_response_time, 2),
                    "avg_items_per_run": round(stats.avg_items_per_run, 2),
                    "last_run_time": (
                        stats.last_run_time.isoformat()
                        if stats.last_run_time else None
                    ),
                    "last_success_time": (
                        stats.last_success_time.isoformat()
                        if stats.last_success_time else None
                    ),
                    "recent_errors": stats.errors[-5:]  # 最近 5 个错误
                }
                for stats in self.stats.values()
            ]
        }

    def generate_report(self) -> str:
        """
        生成监控报告

        Returns:
            格式化的监控报告文本
        """
        summary = self.get_summary()

        report_lines = [
            "=" * 60,
            "爬虫监控报告",
            "=" * 60,
            f"生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            "",
            "总体统计:",
            f"  爬虫数量: {summary['total_spiders']}",
            f"  总运行次数: {summary['total_runs']}",
            f"  成功次数: {summary['successful_runs']}",
            f"  失败次数: {summary['failed_runs']}",
            f"  总体成功率: {summary['overall_success_rate']}%",
            f"  活跃爬取: {summary['active_crawls']}",
            "",
            "各爬虫详情:",
            "-" * 60
        ]

        for spider_info in summary['spiders']:
            report_lines.extend([
                f"\n爬虫: {spider_info['name']}",
                f"  运行次数: {spider_info['total_runs']}",
                f"  成功率: {spider_info['success_rate']}%",
                f"  平均响应时间: {spider_info['avg_response_time']}s",
                f"  平均数据量: {spider_info['avg_items_per_run']} 条/次",
                f"  最后运行: {spider_info['last_run_time'] or 'N/A'}",
                f"  最后成功: {spider_info['last_success_time'] or 'N/A'}"
            ])

            if spider_info['recent_errors']:
                report_lines.append("  最近错误:")
                for error in spider_info['recent_errors']:
                    report_lines.append(f"    - {error}")

        report_lines.append("=" * 60)

        return "\n".join(report_lines)

    def check_health(self) -> dict:
        """
        健康检查

        Returns:
            健康状态字典
        """
        issues = []

        for spider_name, stats in self.stats.items():
            # 检查成功率
            if stats.success_rate < 80 and stats.total_runs >= 5:
                issues.append(
                    f"{spider_name}: 成功率过低 ({stats.success_rate:.1f}%)"
                )

            # 检查最近是否有成功运行
            if stats.last_success_time:
                time_since_success = datetime.now() - stats.last_success_time
                if time_since_success > timedelta(hours=24):
                    issues.append(
                        f"{spider_name}: 超过 24 小时未成功运行"
                    )

            # 检查响应时间
            if stats.avg_response_time > 60:
                issues.append(
                    f"{spider_name}: 平均响应时间过长 "
                    f"({stats.avg_response_time:.1f}s)"
                )

        is_healthy = len(issues) == 0

        return {
            "healthy": is_healthy,
            "issues": issues,
            "checked_at": datetime.now().isoformat()
        }

    def reset_stats(self, spider_name: Optional[str] = None):
        """
        重置统计信息

        Args:
            spider_name: 爬虫名称，None 表示重置所有
        """
        if spider_name:
            if spider_name in self.stats:
                del self.stats[spider_name]
                logger.info(f"已重置统计信息: {spider_name}")
        else:
            self.stats.clear()
            logger.info("已重置所有统计信息")


# 全局监控器实例
_global_monitor: Optional[CrawlerMonitor] = None


def get_monitor() -> CrawlerMonitor:
    """
    获取全局监控器实例（单例模式）

    Returns:
        监控器实例
    """
    global _global_monitor
    if _global_monitor is None:
        _global_monitor = CrawlerMonitor()
    return _global_monitor
