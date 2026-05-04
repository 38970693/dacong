"""
数据存储实现 - Supabase

职责：将数据持久化到 Supabase 数据库
遵循接口隔离原则 (ISP)
"""
import logging
from typing import Optional
from datetime import datetime

from supabase import create_client, Client

from core.interfaces import IDataStorage, RawData, MetricSource
from config import SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY


class SupabaseStorage(IDataStorage):
    """
    Supabase 存储实现

    职责：
    1. 连接 Supabase 数据库
    2. 实现 CRUD 操作
    3. 处理幂等写入（upsert）
    """

    def __init__(self, url: str = SUPABASE_URL, key: str = SUPABASE_SERVICE_ROLE_KEY):
        if not url or not key:
            raise ValueError("Supabase URL and key are required")

        self.client: Client = create_client(url, key)
        self.table_name = "raw_data"
        self.logger = logging.getLogger(__name__)

    async def save(self, data: RawData) -> bool:
        """
        保存单条数据（幂等操作）

        使用 upsert：存在则更新，不存在则插入
        """
        try:
            row = self._to_db_row(data)

            # upsert: 根据 (source, source_id) 唯一约束
            result = self.client.table(self.table_name).upsert(
                row,
                on_conflict="source,source_id"
            ).execute()

            return result.data is not None

        except Exception as e:
            self.logger.error(f"Failed to save data: {e}")
            return False

    async def save_batch(self, data_list: list[RawData]) -> int:
        """
        批量保存数据

        Returns:
            成功保存的数量
        """
        if not data_list:
            return 0

        try:
            rows = [self._to_db_row(data) for data in data_list]

            result = self.client.table(self.table_name).upsert(
                rows,
                on_conflict="source,source_id"
            ).execute()

            return len(result.data) if result.data else 0

        except Exception as e:
            self.logger.error(f"Failed to save batch: {e}")
            return 0

    async def exists(self, source: MetricSource, source_id: str) -> bool:
        """检查数据是否已存在"""
        try:
            result = self.client.table(self.table_name).select("id").eq(
                "source", source
            ).eq(
                "source_id", source_id
            ).limit(1).execute()

            return len(result.data) > 0

        except Exception as e:
            self.logger.error(f"Failed to check existence: {e}")
            return False

    async def get_content_hash(self, source: MetricSource, source_id: str) -> Optional[str]:
        """获取已存储数据的内容哈希"""
        try:
            result = self.client.table(self.table_name).select("content_hash").eq(
                "source", source
            ).eq(
                "source_id", source_id
            ).limit(1).execute()

            if result.data and len(result.data) > 0:
                return result.data[0].get("content_hash")

            return None

        except Exception as e:
            self.logger.error(f"Failed to get content hash: {e}")
            return None

    def _to_db_row(self, data: RawData) -> dict:
        """将 RawData DTO 转换为数据库行"""
        return {
            "source": data.source,
            "data_type": data.data_type,
            "source_id": data.source_id,
            "title": data.title,
            "description": data.description,
            "url": data.url,
            "metadata": data.metadata,
            "raw_content": data.raw_content,
            "content_hash": data.content_hash,
            "fetched_at": data.fetched_at.isoformat(),
            "updated_at": datetime.utcnow().isoformat()
        }


class InMemoryStorage(IDataStorage):
    """
    内存存储实现（用于测试）

    职责：在内存中模拟数据库操作
    """

    def __init__(self):
        self.data: dict[tuple[str, str], RawData] = {}

    async def save(self, data: RawData) -> bool:
        key = (data.source.value, data.source_id)
        self.data[key] = data
        return True

    async def save_batch(self, data_list: list[RawData]) -> int:
        count = 0
        for data in data_list:
            if await self.save(data):
                count += 1
        return count

    async def exists(self, source: MetricSource, source_id: str) -> bool:
        key = (source.value, source_id)
        return key in self.data

    async def get_content_hash(self, source: MetricSource, source_id: str) -> Optional[str]:
        key = (source.value, source_id)
        data = self.data.get(key)
        return data.content_hash if data else None

    def clear(self):
        """清空数据（测试用）"""
        self.data.clear()

    def count(self) -> int:
        """获取数据数量（测试用）"""
        return len(self.data)
