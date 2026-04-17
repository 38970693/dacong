"""
数据处理器注册表

职责：根据爬虫类型返回对应的数据处理器
遵循开闭原则 (OCP)
"""
from typing import Type

from core.interfaces import ISpider, IDataProcessor


# 处理器映射表
_PROCESSOR_REGISTRY: dict[str, Type[IDataProcessor]] = {}


def register_processor(spider_class: Type[ISpider], processor_class: Type[IDataProcessor]):
    """
    注册处理器

    Args:
        spider_class: 爬虫类
        processor_class: 对应的处理器类
    """
    _PROCESSOR_REGISTRY[spider_class.__name__] = processor_class


def get_processor_for_spider(spider_class: Type[ISpider]) -> IDataProcessor:
    """
    获取爬虫对应的处理器实例

    Args:
        spider_class: 爬虫类

    Returns:
        处理器实例

    Raises:
        ValueError: 如果找不到对应的处理器
    """
    processor_class = _PROCESSOR_REGISTRY.get(spider_class.__name__)

    if processor_class is None:
        raise ValueError(f"No processor registered for {spider_class.__name__}")

    return processor_class()


# 注册所有处理器
def _register_all_processors():
    """注册所有内置处理器"""
    from spiders.github_spider import GitHubSpider, GitHubDataProcessor
    from spiders.huggingface_spider import HuggingFaceSpider, HuggingFaceDataProcessor
    from spiders.openrouter_spider import OpenRouterSpider, OpenRouterDataProcessor
    from spiders.reddit_spider import RedditSpider, RedditDataProcessor
    from spiders.hackernews_spider import HackerNewsSpider, HackerNewsDataProcessor

    register_processor(GitHubSpider, GitHubDataProcessor)
    register_processor(HuggingFaceSpider, HuggingFaceDataProcessor)
    register_processor(OpenRouterSpider, OpenRouterDataProcessor)
    register_processor(RedditSpider, RedditDataProcessor)
    register_processor(HackerNewsSpider, HackerNewsDataProcessor)


# 自动注册
_register_all_processors()
