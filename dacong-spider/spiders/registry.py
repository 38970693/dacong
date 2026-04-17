"""
Spider 工厂 - SpiderFactory
采用工厂模式 + 注册表模式
各 Spider 在此处注册，调度器通过名字获取实例
调度器无需 import 具体的 Spider 类，解耦
"""
from core.base import SpiderBase


# 全局 Spider 注册表
_SPIDER_REGISTRY: dict[str, type[SpiderBase]] = {}


def register_spider(name: str, cls: type[SpiderBase]):
    """
    Spider 注册装饰器
    用法：
        @register_spider("github")
        class GitHubTrendingSpider(SpiderBase):
            ...
    """
    _SPIDER_REGISTRY[name] = cls
    return cls


def get_spider(name: str) -> SpiderBase:
    """根据名字从注册表获取 Spider 实例"""
    cls = _SPIDER_REGISTRY.get(name)
    if cls is None:
        raise ValueError(f"未知的 Spider: {name}，可用: {list(_SPIDER_REGISTRY.keys())}")
    return cls()


def list_spiders() -> list[str]:
    """列出所有已注册的 Spider"""
    return list(_SPIDER_REGISTRY.keys())


def create_all_spiders() -> list[SpiderBase]:
    """创建所有已注册的 Spider 实例"""
    return [cls() for cls in _SPIDER_REGISTRY.values()]


# ─── 导入并注册所有 Spider（自动注册）────────────
# 这些 import 会触发 @register_spider 装饰器
from spiders.github_trending import GitHubTrendingSpider
from spiders.huggingface import HuggingFaceSpider
from spiders.hackernews import HackerNewsSpider

# 显式注册（装饰器已在类定义时执行）
register_spider("github", GitHubTrendingSpider)
register_spider("huggingface", HuggingFaceSpider)
register_spider("hackernews", HackerNewsSpider)
