"""
爬虫监控模块
实时监控爬虫运行状态、性能指标和异常情况
"""

import time
import asyncio
from typing import Dict, Any, Optional
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from collections import defaultdict
import logging

logger = logging.getLogger(__name__)


@dataclass
class SpiderMetrics:
    """爬虫指标"""
    
    start_time: float = field(default_factory=time.time)
    total_requests: int = 0
    successful_requests: int = 0
    failed_requests: int = 0
    items_scraped: int = 0
    items_saved: int = 0
    items_failed: int = 0
    total_bytes: int = 0
    avg_response_time: float = 0.0
    errors: Dict[str, int] = field(default_factory=lambda: defaultdict(int))
    
    def get_runtime(self) -> float:
        return time.time() - self.start_time
        
    def get_success_rate(self) -> float:
        if self.total_requests == 0:
            return 0.0
        return self.successful_requests / self.total_requests * 100
        
    def get_requests_per_second(self) -> float:
        runtime = self.get_runtime()
        if runtime == 0:
            return 0.0
        return self.total_requests / runtime


class SpiderMonitor:
    """爬虫监控器"""
    
    def __init__(self, spider_name: str, report_interval: float = 60.0):
        self.spider_name = spider_name
        self.report_interval = report_interval
        self.metrics = SpiderMetrics()
        self._running = False
        
    async def start(self):
        self._running = True
        logger.info(f"爬虫监控已启动: {self.spider_name}")
        
    async def stop(self):
        self._running = False
        self.print_report(final=True)
        
    def record_request(self, success: bool, response_time: float = 0.0):
        self.metrics.total_requests += 1
        if success:
            self.metrics.successful_requests += 1
        else:
            self.metrics.failed_requests += 1
            
    def record_item(self, success: bool = True):
        self.metrics.items_scraped += 1
        if success:
            self.metrics.items_saved += 1
        else:
            self.metrics.items_failed += 1
            
    def print_report(self, final: bool = False):
        runtime = self.metrics.get_runtime()
        logger.info(f"\n{'='*60}")
        logger.info(f"爬虫监控报告 - {self.spider_name}")
        logger.info(f"运行时间: {timedelta(seconds=int(runtime))}")
        logger.info(f"总请求: {self.metrics.total_requests}")
        logger.info(f"成功率: {self.metrics.get_success_rate():.2f}%")
        logger.info(f"抓取数量: {self.metrics.items_scraped}")
        logger.info(f"{'='*60}\n")
