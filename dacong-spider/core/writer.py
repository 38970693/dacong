"""
数据写入器 - Writer
职责：将 Spider 爬取的原始数据写入 Supabase 数据库
包含去重逻辑（最近 24h 已有相同指标则跳过）
"""
import logging
from datetime import datetime, timedelta, timezone
from typing import Optional

from supabase import create_client, Client
from supabase.lib.client_options import ClientOptions

from config import SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, DEBUG_MODE
from models.metrics import RawMetric, RepositoryMetric, HotNewsItem

logger = logging.getLogger(__name__)


class Writer:
    """
    Supabase 写入器
    负责：连接 Supabase + 写入 model_raw_metrics / repository_metrics / hot_news_raw
    """

    def __init__(self):
        self._client: Optional[Client] = None

    @property
    def client(self) -> Client:
        if self._client is None:
            self._client = create_client(
                SUPABASE_URL,
                SUPABASE_SERVICE_ROLE_KEY,
                options=ClientOptions(autoRefreshToken=False),
            )
            logger.info("[Writer] Supabase 客户端初始化完成")
        return self._client

    # ──────────────────────────────────────────────────────
    # 公共方法（供所有 Spider 调用）
    # ──────────────────────────────────────────────────────

    def upsert_model_metrics(self, metric: RawMetric) -> bool:
        """
        写入模型原始指标（含 24h 去重）
        Returns: True 写入成功，False 跳过（重复）
        """
        try:
            # 去重：检查最近 24h 内是否有相同 model_id + source + metric_type
            cutoff = (datetime.now(timezone.utc) - timedelta(hours=24)).isoformat()
            existing = self.client.table("model_raw_metrics").select(
                "id", count="exact"
            ).match({
                "model_id": metric.model_id,
                "source": metric.source.value,
                "metric_type": metric.metric_type.value,
            }).gte("fetched_at", cutoff).execute()

            if existing.count and existing.count > 0:
                if DEBUG_MODE:
                    logger.debug(
                        f"[Writer] 跳过重复 metric: {metric.model_id} "
                        f"[{metric.source.value}/{metric.metric_type.value}]"
                    )
                return False

            data, _ = self.client.table("model_raw_metrics").insert(
                metric.to_dict()
            ).execute()

            if DEBUG_MODE:
                logger.debug(f"[Writer] 写入 model_raw_metrics: {metric.model_id}")
            return True

        except Exception as e:
            logger.error(f"[Writer] upsert_model_metrics 失败: {e}")
            return False

    def upsert_repository_metrics(self, repo: RepositoryMetric) -> bool:
        """
        写入 GitHub 仓库指标（含 24h 去重）
        """
        try:
            cutoff = (datetime.now(timezone.utc) - timedelta(hours=24)).isoformat()
            existing = self.client.table("repository_metrics").select(
                "id", count="exact"
            ).match({
                "full_name": repo.full_name,
            }).gte("fetched_at", cutoff).execute()

            if existing.count and existing.count > 0:
                return False

            self.client.table("repository_metrics").insert(
                repo.to_dict()
            ).execute()

            return True

        except Exception as e:
            logger.error(f"[Writer] upsert_repository_metrics 失败: {e}")
            return False

    def upsert_hot_news(self, news: HotNewsItem) -> bool:
        """
        写入快讯条目（含 24h 去重）
        """
        try:
            cutoff = (datetime.now(timezone.utc) - timedelta(hours=24)).isoformat()
            existing = self.client.table("hot_news_raw").select(
                "id", count="exact"
            ).match({
                "title": news.title,
                "source": news.source,
            }).gte("fetched_at", cutoff).execute()

            if existing.count and existing.count > 0:
                return False

            self.client.table("hot_news_raw").insert(
                news.to_dict()
            ).execute()

            return True

        except Exception as e:
            logger.error(f"[Writer] upsert_hot_news 失败: {e}")
            return False

    def upsert_model(self, name: str, vendor: str, category: str,
                      description: str = "", website_url: str = "",
                      tags: list[str] = None) -> Optional[str]:
        """
        确保模型存在于 models 表，返回 model_id
        如果已存在则返回现有 id
        """
        try:
            tags = tags or []
            # 先查
            existing = self.client.table("models").select("id").match({
                "name": name,
                "vendor": vendor,
            }).execute()

            if existing.data:
                return existing.data[0]["id"]

            # 不存在则插入
            data, _ = self.client.table("models").insert({
                "name": name,
                "vendor": vendor,
                "category": category,
                "description": description,
                "website_url": website_url,
                "tags": tags,
            }).execute()

            return data[0]["id"] if data else None

        except Exception as e:
            logger.error(f"[Writer] upsert_model 失败: {e}")
            return None

    def upsert_ranking(self, table: str, data: dict, unique_keys: list[str]) -> bool:
        """
        通用的 upsert 方法（用于排行榜表）
        Args:
            table: 表名 (swebench_rankings, arena_rankings 等)
            data: 要写入的数据
            unique_keys: 用于 ON CONFLICT 的唯一键列表
        """
        try:
            unique_constraint = ", ".join(unique_keys)
            # 使用 upsert
            result, _ = self.client.table(table).upsert(
                data,
                on_conflict=unique_constraint
            ).execute()
            return True
        except Exception as e:
            logger.error(f"[Writer] upsert_ranking {table} 失败: {e}")
            return False

    def execute_raw(self, sql: str, params: list = None) -> bool:
        """
        执行原始 SQL（用于复杂的 upsert，如 ON CONFLICT DO UPDATE）
        注意：需要 PostgreSQL RPC 函数支持
        """
        try:
            # 使用 rpc 函数执行 raw SQL（如果配置了）
            # 这里只是简单包装，实际使用需要后端支持
            logger.warning("[Writer] execute_raw 需要后端 RPC 支持")
            return False
        except Exception as e:
            logger.error(f"[Writer] execute_raw 失败: {e}")
            return False
