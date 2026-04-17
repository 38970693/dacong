"""
数据去重模块

职责：
- 基于 URL 的去重
- 基于内容哈希的去重
- 基于数据库的去重检查
- 支持多种去重策略
"""
import hashlib
import logging
from typing import Optional
from abc import ABC, abstractmethod

logger = logging.getLogger(__name__)


class DeduplicationStrategy(ABC):
    """去重策略接口"""

    @abstractmethod
    async def is_duplicate(self, item: dict) -> bool:
        """
        检查是否重复

        Args:
            item: 数据项

        Returns:
            是否重复
        """
        pass


class UrlDeduplicator(DeduplicationStrategy):
    """
    基于 URL 的去重器

    使用内存缓存 + 布隆过滤器优化
    """

    def __init__(self, cache_size: int = 10000):
        """
        初始化 URL 去重器

        Args:
            cache_size: 缓存大小
        """
        self.seen_urls: set[str] = set()
        self.cache_size = cache_size

    async def is_duplicate(self, item: dict) -> bool:
        """检查 URL 是否重复"""
        url = item.get("url") or item.get("link") or item.get("repo_url")

        if not url:
            # 没有 URL 字段，无法判断
            return False

        if url in self.seen_urls:
            logger.debug(f"URL 重复: {url}")
            return True

        self.seen_urls.add(url)

        # 限制缓存大小
        if len(self.seen_urls) > self.cache_size:
            # 清理最旧的一半
            to_remove = len(self.seen_urls) - self.cache_size // 2
            for _ in range(to_remove):
                self.seen_urls.pop()

        return False

    def clear(self):
        """清空缓存"""
        self.seen_urls.clear()


class ContentHashDeduplicator(DeduplicationStrategy):
    """
    基于内容哈希的去重器

    计算内容的 SHA256 哈希值进行去重
    """

    def __init__(self, cache_size: int = 10000):
        """
        初始化内容哈希去重器

        Args:
            cache_size: 缓存大小
        """
        self.seen_hashes: set[str] = set()
        self.cache_size = cache_size

    async def is_duplicate(self, item: dict) -> bool:
        """检查内容哈希是否重复"""
        content_hash = self._compute_hash(item)

        if content_hash in self.seen_hashes:
            logger.debug(f"内容哈希重复: {content_hash[:8]}...")
            return True

        self.seen_hashes.add(content_hash)

        # 限制缓存大小
        if len(self.seen_hashes) > self.cache_size:
            to_remove = len(self.seen_hashes) - self.cache_size // 2
            for _ in range(to_remove):
                self.seen_hashes.pop()

        return False

    def _compute_hash(self, item: dict) -> str:
        """
        计算内容哈希

        Args:
            item: 数据项

        Returns:
            SHA256 哈希值
        """
        # 提取关键内容字段
        content_fields = ["title", "description", "content", "text", "body"]
        content_parts = []

        for field in content_fields:
            if field in item and item[field]:
                content_parts.append(str(item[field]))

        # 如果没有内容字段，使用整个对象
        if not content_parts:
            import json
            content = json.dumps(item, sort_keys=True, ensure_ascii=False)
        else:
            content = "\n".join(content_parts)

        return hashlib.sha256(content.encode()).hexdigest()

    def clear(self):
        """清空缓存"""
        self.seen_hashes.clear()


class DatabaseDeduplicator(DeduplicationStrategy):
    """
    基于数据库的去重器

    查询数据库检查是否已存在
    """

    def __init__(self, storage, key_field: str = "url"):
        """
        初始化数据库去重器

        Args:
            storage: 存储实例（需要实现 exists 方法）
            key_field: 用于去重的关键字段
        """
        self.storage = storage
        self.key_field = key_field

    async def is_duplicate(self, item: dict) -> bool:
        """检查数据库中是否已存在"""
        key_value = item.get(self.key_field)

        if not key_value:
            return False

        try:
            exists = await self.storage.exists(self.key_field, key_value)
            if exists:
                logger.debug(f"数据库中已存在: {self.key_field}={key_value}")
            return exists
        except Exception as e:
            logger.error(f"数据库去重检查失败: {e}")
            return False


class CompositeDeduplicator(DeduplicationStrategy):
    """
    组合去重器

    支持多种去重策略组合使用
    """

    def __init__(self, strategies: list[DeduplicationStrategy]):
        """
        初始化组合去重器

        Args:
            strategies: 去重策略列表
        """
        self.strategies = strategies

    async def is_duplicate(self, item: dict) -> bool:
        """
        检查是否重复（任一策略判定为重复即为重复）

        Args:
            item: 数据项

        Returns:
            是否重复
        """
        for strategy in self.strategies:
            if await strategy.is_duplicate(item):
                return True
        return False


class Deduplicator:
    """
    去重管理器（门面模式）

    提供简单的去重接口
    """

    def __init__(
        self,
        use_url: bool = True,
        use_content_hash: bool = True,
        use_database: bool = False,
        storage=None
    ):
        """
        初始化去重器

        Args:
            use_url: 是否使用 URL 去重
            use_content_hash: 是否使用内容哈希去重
            use_database: 是否使用数据库去重
            storage: 存储实例（use_database=True 时必需）
        """
        strategies = []

        if use_url:
            strategies.append(UrlDeduplicator())

        if use_content_hash:
            strategies.append(ContentHashDeduplicator())

        if use_database:
            if not storage:
                raise ValueError("use_database=True 时必须提供 storage 参数")
            strategies.append(DatabaseDeduplicator(storage))

        self.strategy = CompositeDeduplicator(strategies)

        logger.info(
            f"去重器初始化完成，启用策略: "
            f"URL={use_url}, ContentHash={use_content_hash}, Database={use_database}"
        )

    async def filter_duplicates(self, items: list[dict]) -> list[dict]:
        """
        过滤重复数据

        Args:
            items: 数据项列表

        Returns:
            去重后的数据项列表
        """
        unique_items = []

        for item in items:
            if not await self.strategy.is_duplicate(item):
                unique_items.append(item)

        removed_count = len(items) - len(unique_items)
        if removed_count > 0:
            logger.info(
                f"去重完成: 原始 {len(items)} 条，"
                f"去重后 {len(unique_items)} 条，"
                f"移除 {removed_count} 条重复数据"
            )

        return unique_items

    async def is_duplicate(self, item: dict) -> bool:
        """
        检查单个数据项是否重复

        Args:
            item: 数据项

        Returns:
            是否重复
        """
        return await self.strategy.is_duplicate(item)
