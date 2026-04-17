"""
爬虫性能监控模块
监控爬虫运行时间、抓取速度、成功率等指标
"""

import time
import logging
from datetime import datetime
from typing import Dict, Optional, List
from dataclasses import dataclass, asdict
import json

logger = logging.getLogger(__name__)


@dataclass
class SpiderMetric:
    """爬虫性能指标"""
    spider_name: str
    start_time: str
    end_time: str
    duration_seconds: float
    items_count: int
    items_per_second: float
    success_count: int
    error_count: int
    success_rate: float
    error_rate: float
    timestamp: str


class PerformanceMonitor:
    """性能监控器"""

    def __init__(self):
        self.metrics: List[SpiderMetric] = []
        self.current_runs: Dict[str, Dict] = {}

    def start_spider_run(self, spider_name: str) -> None:
        """开始监控爬虫运行"""
        self.current_runs[spider_name] = {
            'start_time': time.time(),
            'items_count': 0,
            'success_count': 0,
            'error_count': 0,
        }
        logger.info(f"📊 Started monitoring spider: {spider_name}")

    def record_item(self, spider_name: str, success: bool = True) -> None:
        """记录抓取的条目"""
        if spider_name not in self.current_runs:
            logger.warning(f"Spider {spider_name} not started")
            return

        run = self.current_runs[spider_name]
        run['items_count'] += 1

        if success:
            run['success_count'] += 1
        else:
            run['error_count'] += 1

    def end_spider_run(self, spider_name: str) -> Optional[SpiderMetric]:
        """结束监控爬虫运行"""
        if spider_name not in self.current_runs:
            logger.warning(f"Spider {spider_name} not started")
            return None

        run = self.current_runs.pop(spider_name)
        end_time = time.time()
        duration = end_time - run['start_time']

        items_count = run['items_count']
        success_count = run['success_count']
        error_count = run['error_count']

        items_per_second = items_count / duration if duration > 0 else 0
        success_rate = success_count / items_count if items_count > 0 else 0
        error_rate = error_count / items_count if items_count > 0 else 0

        metric = SpiderMetric(
            spider_name=spider_name,
            start_time=datetime.fromtimestamp(run['start_time']).isoformat(),
            end_time=datetime.fromtimestamp(end_time).isoformat(),
            duration_seconds=duration,
            items_count=items_count,
            items_per_second=items_per_second,
            success_count=success_count,
            error_count=error_count,
            success_rate=success_rate,
            error_rate=error_rate,
            timestamp=datetime.now().isoformat()
        )

        self.metrics.append(metric)
        self._log_metric(metric)
        self._check_alerts(metric)

        return metric

    def _log_metric(self, metric: SpiderMetric) -> None:
        """记录性能指标"""
        logger.info(json.dumps({
            'type': 'spider_performance',
            **asdict(metric)
        }))

        # 性能评估
        if metric.duration_seconds > 300:  # 5分钟
            logger.warning(f"🟡 Slow spider run: {metric.spider_name} took {metric.duration_seconds:.1f}s")

        if metric.error_rate > 0.1:  # 错误率 > 10%
            logger.error(f"🔴 High error rate: {metric.spider_name} error rate {metric.error_rate:.1%}")

        if metric.items_per_second < 1:  # 每秒少于1条
            logger.warning(f"🟡 Low throughput: {metric.spider_name} only {metric.items_per_second:.2f} items/s")

    def _check_alerts(self, metric: SpiderMetric) -> None:
        """检查告警条件"""
        alerts = []

        # 错误率告警
        if metric.error_rate > 0.1:
            alerts.append({
                'level': 'critical',
                'type': 'high_error_rate',
                'message': f'Spider {metric.spider_name} error rate {metric.error_rate:.1%} > 10%',
                'value': metric.error_rate,
                'threshold': 0.1,
            })

        # 运行时间告警
        if metric.duration_seconds > 600:  # 10分钟
            alerts.append({
                'level': 'warning',
                'type': 'slow_spider',
                'message': f'Spider {metric.spider_name} took {metric.duration_seconds:.1f}s',
                'value': metric.duration_seconds,
                'threshold': 600,
            })

        # 吞吐量告警
        if metric.items_per_second < 0.5:
            alerts.append({
                'level': 'warning',
                'type': 'low_throughput',
                'message': f'Spider {metric.spider_name} throughput {metric.items_per_second:.2f} items/s',
                'value': metric.items_per_second,
                'threshold': 0.5,
            })

        for alert in alerts:
            logger.warning(json.dumps({
                'type': 'performance_alert',
                'spider': metric.spider_name,
                **alert
            }))

    def get_stats(self, spider_name: Optional[str] = None) -> Dict:
        """获取性能统计"""
        metrics = self.metrics
        if spider_name:
            metrics = [m for m in metrics if m.spider_name == spider_name]

        if not metrics:
            return {}

        durations = [m.duration_seconds for m in metrics]
        items_counts = [m.items_count for m in metrics]
        error_rates = [m.error_rate for m in metrics]

        return {
            'total_runs': len(metrics),
            'avg_duration': sum(durations) / len(durations),
            'avg_items': sum(items_counts) / len(items_counts),
            'avg_error_rate': sum(error_rates) / len(error_rates),
            'total_items': sum(items_counts),
        }

    def clear(self) -> None:
        """清空指标"""
        self.metrics.clear()
        self.current_runs.clear()


# 全局实例
performance_monitor = PerformanceMonitor()
