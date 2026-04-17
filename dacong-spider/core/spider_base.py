"""
爬虫基类 - 模板方法模式 (Template Method Pattern)

定义爬虫执行的标准流程，子类只需实现具体的抓取逻辑
遵循开闭原则 (OCP)：对扩展开放，对修改关闭
"""
import time
from abc import abstractmethod
from typing import Optional

from core.interfaces import (
    ISpider, IHttpClient, IDataProcessor, IDataStorage,
    IDeduplicator, ILogger, MetricSource, SpiderResult
)


class BaseSpider(ISpider):
    """
    爬虫基类 - 模板方法模式

    设计模式：
    1. Template Method：定义执行流程，子类实现具体步骤
    2. Dependency Injection：通过构造函数注入依赖
    3. Strategy Pattern：可替换的处理器、存储器、去重器

    职责：
    - 定义爬虫执行的标准流程
    - 协调各个组件的工作
    - 处理异常和日志记录
    """

    def __init__(
        self,
        http_client: IHttpClient,
        data_processor: IDataProcessor,
        storage: IDataStorage,
        deduplicator: IDeduplicator,
        logger: ILogger
    ):
        """
        依赖注入构造函数
        所有依赖都是接口类型，便于测试和替换实现
        """
        self.http_client = http_client
        self.data_processor = data_processor
        self.storage = storage
        self.deduplicator = deduplicator
        self.logger = logger

    @property
    @abstractmethod
    def name(self) -> str:
        """爬虫名称（子类必须实现）"""
        pass

    @property
    @abstractmethod
    def source(self) -> MetricSource:
        """数据源（子类必须实现）"""
        pass

    @abstractmethod
    async def fetch(self) -> list[dict]:
        """
        抓取原始数据（子类必须实现）

        职责：
        1. 使用 http_client 发起请求
        2. 解析响应数据
        3. 返回原始数据列表

        Returns:
            原始数据列表
        """
        pass

    # ══════════════════════════════════════════════════════════
    # 模板方法 - 定义执行流程
    # ══════════════════════════════════════════════════════════

    async def run(self) -> SpiderResult:
        """
        执行爬虫的标准流程（模板方法）

        流程：
        1. 开始前钩子
        2. 抓取数据
        3. 处理数据
        4. 去重
        5. 保存数据
        6. 结束后钩子
        7. 返回结果
        """
        start_time = time.monotonic()
        self.logger.info(f"🚀 开始执行爬虫: {self.name}")

        try:
            # 1. 开始前钩子
            await self.on_start()

            # 2. 抓取原始数据
            raw_items = await self.fetch()
            self.logger.info(f"📥 抓取到 {len(raw_items)} 条原始数据")

            if not raw_items:
                return self._create_result(
                    success=True,
                    items_fetched=0,
                    items_written=0,
                    duration=time.monotonic() - start_time
                )

            # 3. 处理数据
            processed_items = []
            for item in raw_items:
                processed = self.data_processor.process(item)
                if processed:
                    processed_items.append(processed)

            self.logger.info(f"🔄 处理后 {len(processed_items)} 条有效数据")

            # 4. 去重
            unique_items = await self.deduplicator.filter_duplicates(
                processed_items,
                self.storage
            )
            self.logger.info(f"✨ 去重后 {len(unique_items)} 条新数据")

            # 5. 保存数据
            written_count = await self.storage.save_batch(unique_items)
            self.logger.info(f"💾 成功写入 {written_count} 条数据")

            # 6. 结束后钩子
            result = self._create_result(
                success=True,
                items_fetched=len(raw_items),
                items_written=written_count,
                duration=time.monotonic() - start_time
            )
            await self.on_end(result)

            return result

        except Exception as e:
            self.logger.error(f"💥 爬虫执行失败: {self.name}", e)
            result = self._create_result(
                success=False,
                items_fetched=0,
                items_written=0,
                duration=time.monotonic() - start_time,
                errors=[str(e)]
            )
            await self.on_error(e)
            return result

    # ══════════════════════════════════════════════════════════
    # 钩子方法 - 子类可选覆盖
    # ══════════════════════════════════════════════════════════

    async def on_start(self):
        """开始前钩子（子类可选实现）"""
        pass

    async def on_end(self, result: SpiderResult):
        """结束后钩子（子类可选实现）"""
        await self.logger.log_spider_result(result)

    async def on_error(self, error: Exception):
        """错误处理钩子（子类可选实现）"""
        pass

    # ══════════════════════════════════════════════════════════
    # 辅助方法
    # ══════════════════════════════════════════════════════════

    def _create_result(
        self,
        success: bool,
        items_fetched: int,
        items_written: int,
        duration: float,
        errors: Optional[list[str]] = None
    ) -> SpiderResult:
        """创建执行结果"""
        return SpiderResult(
            spider_name=self.name,
            success=success,
            items_fetched=items_fetched,
            items_written=items_written,
            errors=errors or [],
            duration_seconds=duration
        )


# ══════════════════════════════════════════════════════════
# API 爬虫基类 - 针对 REST API 的特化
# ══════════════════════════════════════════════════════════

class ApiSpider(BaseSpider):
    """
    API 爬虫基类

    适用于：GitHub API, HuggingFace API, OpenRouter API 等
    提供 API 请求的通用逻辑
    """

    @property
    @abstractmethod
    def api_base_url(self) -> str:
        """API 基础 URL（子类必须实现）"""
        pass

    def get_headers(self) -> dict:
        """
        获取 API 请求头（子类可覆盖）

        子类可以添加认证信息：
        headers = super().get_headers()
        headers["Authorization"] = f"token {self.api_token}"
        return headers
        """
        return {
            "Accept": "application/json",
            "Content-Type": "application/json"
        }

    async def fetch_json(self, endpoint: str) -> Optional[dict]:
        """
        抓取 JSON 数据的便捷方法

        Args:
            endpoint: API 端点（相对路径）

        Returns:
            JSON 数据，失败返回 None
        """
        url = f"{self.api_base_url.rstrip('/')}/{endpoint.lstrip('/')}"
        return await self.http_client.get_json(url, headers=self.get_headers())


# ══════════════════════════════════════════════════════════
# HTML 爬虫基类 - 针对网页爬取的特化
# ══════════════════════════════════════════════════════════

class HtmlSpider(BaseSpider):
    """
    HTML 爬虫基类

    适用于：GitHub Trending, Hacker News 等
    提供 HTML 解析的通用逻辑
    """

    async def fetch_html(self, url: str) -> Optional[str]:
        """
        抓取 HTML 页面的便捷方法

        Args:
            url: 页面 URL

        Returns:
            HTML 文本，失败返回 None
        """
        return await self.http_client.get(url)
