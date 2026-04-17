"""
调度器实现 - APScheduler

职责：管理爬虫的定时执行
遵循单一职责原则 (SRP)
"""
import asyncio
import logging
from typing import Optional

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger

from core.interfaces import IScheduler, ISpider
from core.factory import SpiderRegistry


class SpiderScheduler(IScheduler):
    """
    爬虫调度器

    职责：
    1. 注册爬虫和执行计划
    2. 定时触发爬虫执行
    3. 管理调度器生命周期
    """

    def __init__(self, registry: SpiderRegistry):
        self.registry = registry
        self.scheduler = AsyncIOScheduler()
        self.logger = logging.getLogger(__name__)

    def register_spider(self, spider: ISpider, interval_hours: int):
        """
        注册爬虫到调度器

        Args:
            spider: 爬虫实例
            interval_hours: 执行间隔（小时）
        """
        # 使用 cron 表达式：每 N 小时执行一次
        trigger = CronTrigger(hour=f"*/{interval_hours}")

        self.scheduler.add_job(
            func=self._run_spider,
            trigger=trigger,
            args=[spider],
            id=spider.name,
            name=spider.name,
            replace_existing=True
        )

        self.logger.info(f"已注册爬虫: {spider.name}, 间隔: {interval_hours}小时")

    def register_spider_by_name(self, spider_name: str, interval_hours: int):
        """
        根据名称注册爬虫

        Args:
            spider_name: 爬虫名称
            interval_hours: 执行间隔（小时）
        """
        spider = self.registry.get(spider_name)
        if spider:
            self.register_spider(spider, interval_hours)
        else:
            self.logger.error(f"爬虫不存在: {spider_name}")

    async def _run_spider(self, spider: ISpider):
        """执行爬虫（内部方法）"""
        try:
            result = await spider.run()
            if not result.success:
                self.logger.error(f"爬虫执行失败: {spider.name}")
        except Exception as e:
            self.logger.exception(f"爬虫执行异常: {spider.name}, {e}")

    async def start(self):
        """启动调度器"""
        self.scheduler.start()
        self.logger.info("调度器已启动")

        # 保持运行
        try:
            while True:
                await asyncio.sleep(3600)  # 每小时检查一次
        except (KeyboardInterrupt, SystemExit):
            await self.stop()

    async def stop(self):
        """停止调度器"""
        self.scheduler.shutdown()
        self.logger.info("调度器已停止")

    def run_now(self, spider_name: str):
        """立即执行指定爬虫"""
        spider = self.registry.get(spider_name)
        if spider:
            self.scheduler.add_job(
                func=self._run_spider,
                args=[spider],
                id=f"{spider_name}_manual",
                replace_existing=True
            )
            self.logger.info(f"已触发立即执行: {spider_name}")
        else:
            self.logger.error(f"爬虫不存在: {spider_name}")

    def list_jobs(self) -> list[dict]:
        """列出所有调度任务"""
        jobs = []
        for job in self.scheduler.get_jobs():
            jobs.append({
                "id": job.id,
                "name": job.name,
                "next_run": job.next_run_time.isoformat() if job.next_run_time else None
            })
        return jobs


def create_default_scheduler(registry: SpiderRegistry) -> SpiderScheduler:
    """
    创建默认调度器

    根据配置文件注册所有爬虫
    """
    from config import SPIDERS

    scheduler = SpiderScheduler(registry)

    # 注册所有启用的爬虫
    for spider_name, config in SPIDERS.items():
        if config.get("enabled", False):
            interval_hours = config.get("interval_hours", 24)
            scheduler.register_spider_by_name(spider_name, interval_hours)

    return scheduler
