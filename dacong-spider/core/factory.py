"""
爬虫工厂 - 工厂模式 (Factory Pattern)

职责：创建和配置爬虫实例
遵循依赖倒置原则 (DIP)
"""
from typing import Optional

from core.interfaces import (
    ISpider, IHttpClient, IDataStorage, IDeduplicator, ILogger
)
from core.implementations import (
    HttpClient, ContentHashDeduplicator, SpiderLogger,
    ExponentialBackoffRetry
)
from core.storage import SupabaseStorage


class SpiderFactory:
    """
    爬虫工厂

    设计模式：
    1. Factory Pattern：封装对象创建逻辑
    2. Dependency Injection：注入共享依赖

    职责：
    - 创建爬虫实例
    - 配置依赖注入
    - 管理共享资源（HTTP 客户端、存储等）
    """

    def __init__(
        self,
        http_client: Optional[IHttpClient] = None,
        storage: Optional[IDataStorage] = None,
        deduplicator: Optional[IDeduplicator] = None
    ):
        """
        初始化工厂

        Args:
            http_client: HTTP 客户端（可选，默认创建新实例）
            storage: 数据存储（可选，默认使用 Supabase）
            deduplicator: 去重器（可选，默认使用内容哈希去重）
        """
        # 共享的 HTTP 客户端（复用连接池）
        self.http_client = http_client or HttpClient(
            retry_strategy=ExponentialBackoffRetry()
        )

        # 共享的存储实例
        self.storage = storage or SupabaseStorage()

        # 共享的去重器
        self.deduplicator = deduplicator or ContentHashDeduplicator()

    def create_spider(
        self,
        spider_class: type[ISpider],
        **kwargs
    ) -> ISpider:
        """
        创建爬虫实例

        Args:
            spider_class: 爬虫类
            **kwargs: 传递给爬虫构造函数的额外参数

        Returns:
            配置好的爬虫实例
        """
        # 导入具体的数据处理器
        from spiders.processors import get_processor_for_spider

        processor = get_processor_for_spider(spider_class)
        logger = SpiderLogger(name=spider_class.__name__, storage=self.storage)

        # 依赖注入
        return spider_class(
            http_client=self.http_client,
            data_processor=processor,
            storage=self.storage,
            deduplicator=self.deduplicator,
            logger=logger,
            **kwargs
        )

    def create_github_spider(self):
        """创建 GitHub 爬虫"""
        from spiders.github_spider import GitHubSpider
        return self.create_spider(GitHubSpider)

    def create_huggingface_spider(self):
        """创建 HuggingFace 爬虫"""
        from spiders.huggingface_spider import HuggingFaceSpider
        return self.create_spider(HuggingFaceSpider)

    def create_openrouter_spider(self):
        """创建 OpenRouter 爬虫"""
        from spiders.openrouter_spider import OpenRouterSpider
        return self.create_spider(OpenRouterSpider)

    def create_reddit_spider(self):
        """创建 Reddit 爬虫"""
        from spiders.reddit_spider import RedditSpider
        return self.create_spider(RedditSpider)

    def create_hackernews_spider(self):
        """创建 Hacker News 爬虫"""
        from spiders.hackernews_spider import HackerNewsSpider
        return self.create_spider(HackerNewsSpider)

    async def cleanup(self):
        """清理资源"""
        await self.http_client.close()


class SpiderRegistry:
    """
    爬虫注册表

    职责：
    - 注册所有可用的爬虫
    - 根据名称获取爬虫
    - 管理爬虫配置
    """

    def __init__(self, factory: SpiderFactory):
        self.factory = factory
        self._registry: dict[str, tuple[type[ISpider], dict]] = {}

    def register(self, name: str, spider_class: type[ISpider], config: Optional[dict] = None):
        """
        注册爬虫

        Args:
            name: 爬虫名称（唯一标识）
            spider_class: 爬虫类
            config: 配置参数
        """
        self._registry[name] = (spider_class, config or {})

    def get(self, name: str) -> Optional[ISpider]:
        """
        根据名称获取爬虫实例

        Args:
            name: 爬虫名称

        Returns:
            爬虫实例，不存在返回 None
        """
        if name not in self._registry:
            return None

        spider_class, config = self._registry[name]
        return self.factory.create_spider(spider_class, **config)

    def get_all(self) -> list[ISpider]:
        """获取所有注册的爬虫实例"""
        return [self.get(name) for name in self._registry.keys()]

    def list_names(self) -> list[str]:
        """列出所有注册的爬虫名称"""
        return list(self._registry.keys())


def create_default_registry() -> SpiderRegistry:
    """
    创建默认的爬虫注册表

    包含所有内置爬虫
    """
    from spiders.github_spider import GitHubSpider
    from spiders.huggingface_spider import HuggingFaceSpider
    from spiders.openrouter_spider import OpenRouterSpider
    from spiders.reddit_spider import RedditSpider
    from spiders.hackernews_spider import HackerNewsSpider

    factory = SpiderFactory()
    registry = SpiderRegistry(factory)

    # 注册所有爬虫
    registry.register("github", GitHubSpider)
    registry.register("huggingface", HuggingFaceSpider)
    registry.register("openrouter", OpenRouterSpider)
    registry.register("reddit", RedditSpider)
    registry.register("hackernews", HackerNewsSpider)

    return registry
