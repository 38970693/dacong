"""
AI Rankings 爬虫基类

轻量级爬虫，用于抓取 AI 模型排行榜数据
不需要复杂的数据处理管道，直接抓取并存储
"""
import time
from abc import abstractmethod
from typing import Optional

from core.interfaces import ISpider, IHttpClient, IDataStorage, ILogger, SpiderResult
from core.implementations import HttpClient, SpiderLogger
from core.storage import SupabaseStorage


class BaseRankingsSpider(ISpider):
    """
    排行榜爬虫基类

    简化版爬虫，专用于排行榜数据抓取
    特点：
    - 无需数据处理器
    - 无需去重器（数据源本身已去重）
    - 直接存储到指定表
    """

    def __init__(
        self,
        http_client: Optional[IHttpClient] = None,
        storage: Optional[IDataStorage] = None,
        logger: Optional[ILogger] = None
    ):
        self.http_client = http_client or HttpClient()
        self.storage = storage or SupabaseStorage()
        self.logger = logger or SpiderLogger(name=self.__class__.__name__)

        # 统计
        self.items_fetched = 0
        self.items_written = 0

    @property
    @abstractmethod
    def name(self) -> str:
        """爬虫名称"""
        pass

    @property
    @abstractmethod
    def source(self) -> str:
        """数据源标识"""
        pass

    @property
    @abstractmethod
    def table_name(self) -> str:
        """存储表名"""
        pass

    @abstractmethod
    async def fetch(self) -> list[dict]:
        """抓取数据"""
        pass

    async def run(self, fetcher=None, writer=None) -> SpiderResult:
        """执行爬虫（兼容 SpiderBase 接口但不使用 fetcher/writer）"""
        start_time = time.monotonic()
        self.logger.info(f"🚀 开始执行爬虫: {self.name}")

        try:
            # 1. 抓取数据
            items = await self.fetch()
            self.items_fetched = len(items)
            self.logger.info(f"📥 抓取到 {self.items_fetched} 条数据")

            if not items:
                return SpiderResult(
                    spider_name=self.name,
                    success=True,
                    items_fetched=0,
                    items_written=0,
                    duration_seconds=time.monotonic() - start_time
                )

            # 2. 写入数据库
            written = await self.save_to_table(items)
            self.items_written = written
            self.logger.info(f"💾 成功写入 {self.items_written} 条数据")

            return SpiderResult(
                spider_name=self.name,
                success=True,
                items_fetched=self.items_fetched,
                items_written=self.items_written,
                duration_seconds=time.monotonic() - start_time
            )

        except Exception as e:
            self.logger.error(f"💥 爬虫执行失败: {self.name}", e)
            return SpiderResult(
                spider_name=self.name,
                success=False,
                items_fetched=self.items_fetched,
                items_written=self.items_written,
                duration_seconds=time.monotonic() - start_time,
                errors=[str(e)]
            )

    async def save_to_table(self, items: list[dict]) -> int:
        """保存数据到指定表"""
        from supabase import create_client
        from config import SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY

        client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

        # 使用 upsert 避免重复
        response = client.table(self.table_name).upsert(
            items,
            ignore_conflicts=True
        ).execute()

        return len(response.data) if response.data else len(items)