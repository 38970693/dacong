"""
增量爬取模块

职责：
- 记录上次爬取时间
- 判断是否需要重新爬取
- 避免重复爬取相同内容
- 支持基于时间戳和内容哈希的增量策略
"""
import hashlib
import json
import logging
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)


class IncrementalCrawler:
    """
    增量爬取管理器

    特性：
    - 基于时间戳的增量爬取
    - 基于内容哈希的去重
    - 持久化爬取状态
    - 支持强制全量爬取
    """

    def __init__(self, state_dir: str = "data/crawler_state"):
        """
        初始化增量爬取器

        Args:
            state_dir: 状态文件存储目录
        """
        self.state_dir = Path(state_dir)
        self.state_dir.mkdir(parents=True, exist_ok=True)
        self._state_cache: dict[str, dict] = {}

        logger.info(f"增量爬取器初始化完成，状态目录: {self.state_dir}")

    def _get_state_file(self, spider_name: str) -> Path:
        """获取爬虫状态文件路径"""
        return self.state_dir / f"{spider_name}.json"

    def _load_state(self, spider_name: str) -> dict:
        """
        加载爬虫状态

        Args:
            spider_name: 爬虫名称

        Returns:
            状态字典
        """
        if spider_name in self._state_cache:
            return self._state_cache[spider_name]

        state_file = self._get_state_file(spider_name)

        if not state_file.exists():
            return {
                "last_crawl_time": None,
                "last_item_count": 0,
                "content_hashes": set(),
                "metadata": {}
            }

        try:
            with open(state_file, "r", encoding="utf-8") as f:
                data = json.load(f)
                # 将列表转换回集合
                data["content_hashes"] = set(data.get("content_hashes", []))
                self._state_cache[spider_name] = data
                return data
        except Exception as e:
            logger.error(f"加载状态文件失败 {spider_name}: {e}")
            return {
                "last_crawl_time": None,
                "last_item_count": 0,
                "content_hashes": set(),
                "metadata": {}
            }

    def _save_state(self, spider_name: str, state: dict):
        """
        保存爬虫状态

        Args:
            spider_name: 爬虫名称
            state: 状态字典
        """
        state_file = self._get_state_file(spider_name)

        try:
            # 将集合转换为列表以便 JSON 序列化
            save_data = state.copy()
            save_data["content_hashes"] = list(state.get("content_hashes", set()))

            with open(state_file, "w", encoding="utf-8") as f:
                json.dump(save_data, f, indent=2, ensure_ascii=False)

            self._state_cache[spider_name] = state
            logger.debug(f"状态已保存: {spider_name}")

        except Exception as e:
            logger.error(f"保存状态文件失败 {spider_name}: {e}")

    def get_last_crawl_time(self, spider_name: str) -> Optional[datetime]:
        """
        获取上次爬取时间

        Args:
            spider_name: 爬虫名称

        Returns:
            上次爬取时间，如果从未爬取返回 None
        """
        state = self._load_state(spider_name)
        last_time = state.get("last_crawl_time")

        if last_time:
            return datetime.fromisoformat(last_time)
        return None

    def should_crawl(
        self,
        spider_name: str,
        min_interval: Optional[timedelta] = None,
        force: bool = False
    ) -> bool:
        """
        判断是否应该爬取

        Args:
            spider_name: 爬虫名称
            min_interval: 最小爬取间隔，None 表示总是爬取
            force: 是否强制爬取

        Returns:
            是否应该爬取
        """
        if force:
            logger.info(f"强制爬取模式: {spider_name}")
            return True

        last_time = self.get_last_crawl_time(spider_name)

        if last_time is None:
            logger.info(f"首次爬取: {spider_name}")
            return True

        if min_interval is None:
            return True

        elapsed = datetime.now() - last_time

        if elapsed >= min_interval:
            logger.info(
                f"距离上次爬取已过 {elapsed.total_seconds():.0f} 秒，"
                f"超过最小间隔 {min_interval.total_seconds():.0f} 秒: {spider_name}"
            )
            return True
        else:
            remaining = min_interval - elapsed
            logger.info(
                f"距离上次爬取仅 {elapsed.total_seconds():.0f} 秒，"
                f"还需等待 {remaining.total_seconds():.0f} 秒: {spider_name}"
            )
            return False

    def should_crawl_item(self, spider_name: str, item: dict) -> bool:
        """
        判断单个数据项是否需要爬取（基于内容哈希）

        Args:
            spider_name: 爬虫名称
            item: 数据项

        Returns:
            是否需要爬取
        """
        content_hash = self._compute_hash(item)
        state = self._load_state(spider_name)
        content_hashes = state.get("content_hashes", set())

        if content_hash in content_hashes:
            logger.debug(f"内容已存在，跳过: {content_hash[:8]}...")
            return False

        return True

    def update_crawl_time(
        self,
        spider_name: str,
        item_count: int = 0,
        metadata: Optional[dict] = None
    ):
        """
        更新爬取时间和统计信息

        Args:
            spider_name: 爬虫名称
            item_count: 本次爬取的数据项数量
            metadata: 额外的元数据
        """
        state = self._load_state(spider_name)

        state["last_crawl_time"] = datetime.now().isoformat()
        state["last_item_count"] = item_count

        if metadata:
            state["metadata"].update(metadata)

        self._save_state(spider_name, state)

        logger.info(
            f"更新爬取时间: {spider_name}, "
            f"本次爬取 {item_count} 条数据"
        )

    def mark_item_crawled(self, spider_name: str, item: dict):
        """
        标记数据项已爬取

        Args:
            spider_name: 爬虫名称
            item: 数据项
        """
        content_hash = self._compute_hash(item)
        state = self._load_state(spider_name)

        if "content_hashes" not in state:
            state["content_hashes"] = set()

        state["content_hashes"].add(content_hash)

        # 限制哈希集合大小，避免无限增长
        max_hashes = 10000
        if len(state["content_hashes"]) > max_hashes:
            # 保留最新的哈希
            state["content_hashes"] = set(
                list(state["content_hashes"])[-max_hashes:]
            )
            logger.warning(
                f"内容哈希集合超过 {max_hashes}，已清理旧数据: {spider_name}"
            )

        self._save_state(spider_name, state)

    def _compute_hash(self, item: dict) -> str:
        """
        计算数据项的哈希值

        Args:
            item: 数据项

        Returns:
            SHA256 哈希值
        """
        # 提取关键字段用于哈希计算
        key_fields = ["url", "title", "name", "id", "repo_name"]
        key_data = {
            k: v for k, v in item.items()
            if k in key_fields and v is not None
        }

        # 如果没有关键字段，使用整个对象
        if not key_data:
            key_data = item

        # 排序后序列化，确保一致性
        content = json.dumps(key_data, sort_keys=True, ensure_ascii=False)
        return hashlib.sha256(content.encode()).hexdigest()

    def clear_state(self, spider_name: str):
        """
        清除爬虫状态（用于重置）

        Args:
            spider_name: 爬虫名称
        """
        state_file = self._get_state_file(spider_name)

        if state_file.exists():
            state_file.unlink()
            logger.info(f"已清除状态: {spider_name}")

        if spider_name in self._state_cache:
            del self._state_cache[spider_name]

    def get_stats(self, spider_name: str) -> dict:
        """
        获取爬虫统计信息

        Args:
            spider_name: 爬虫名称

        Returns:
            统计信息字典
        """
        state = self._load_state(spider_name)
        last_time = self.get_last_crawl_time(spider_name)

        return {
            "spider_name": spider_name,
            "last_crawl_time": last_time.isoformat() if last_time else None,
            "last_item_count": state.get("last_item_count", 0),
            "cached_hashes": len(state.get("content_hashes", set())),
            "metadata": state.get("metadata", {}),
            "time_since_last_crawl": (
                (datetime.now() - last_time).total_seconds()
                if last_time else None
            )
        }
