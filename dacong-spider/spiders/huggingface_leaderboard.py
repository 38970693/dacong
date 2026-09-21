"""
LMArena 排行榜爬虫 - 通过 HuggingFace 数据集获取数据

由于 lmarena.ai 网站有访问限制，改用 HuggingFace 上的官方数据集
数据集: https://huggingface.co/datasets/lmarena-ai/leaderboard-dataset
"""
import hashlib
import io
import json
import logging
from datetime import datetime, timezone

import httpx
import pandas as pd

from core.interfaces import RawData, MetricSource, DataType

logger = logging.getLogger(__name__)


class HuggingFaceLeaderboardSpider:
    """
    通过 HuggingFace 获取 LMArena 排行榜数据

    数据源: lmarena-ai/leaderboard-dataset
    包含各分类排行榜: text, search, vision, image_to_video 等
    """

    DATASET_ID = "lmarena-ai/leaderboard-dataset"

    # 排行榜分类列表
    CATEGORIES = [
        "text",
        "text_style_control",
        "search",
        "search_style_control",
        "vision",
        "vision_style_control",
        "image_edit",
        "image_to_video",
        "text_to_image",
        "text_to_video",
        "video_edit",
        "webdev",
        "document",
        "document_style_control",
    ]

    def __init__(self):
        self._client: httpx.AsyncClient | None = None

    async def _get_client(self) -> httpx.AsyncClient:
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(timeout=60, follow_redirects=True)
        return self._client

    async def close(self):
        if self._client and not self._client.is_closed:
            await self._client.aclose()

    async def fetch(self) -> list[RawData]:
        """获取所有排行榜数据"""
        items = []

        for category in self.CATEGORIES:
            try:
                category_items = await self._fetch_category(category)
                items.extend(category_items)
                if category_items:
                    logger.info(f"获取 {category}: {len(category_items)} 条")
            except Exception as e:
                logger.error(f"获取 {category} 失败: {e}")

        return items

    async def _fetch_category(self, category: str) -> list[RawData]:
        """获取指定分类的数据"""
        url = (
            f"https://huggingface.co/datasets/{self.DATASET_ID}/"
            f"resolve/main/{category}/latest-00000-of-00001.parquet"
        )

        client = await self._get_client()
        headers = {"User-Agent": "Mozilla/5.0"}

        try:
            resp = await client.get(url, headers=headers)

            if resp.status_code != 200:
                # 尝试 full 版本
                url = url.replace("latest", "full")
                resp = await client.get(url, headers=headers)

            if resp.status_code != 200:
                logger.debug(f"无法获取 {category}: {resp.status_code}")
                return []

            # 解析 parquet 数据
            df = pd.read_parquet(io.BytesIO(resp.content))
            return self._parse_dataframe(df, category)

        except Exception as e:
            logger.error(f"解析 {category} 失败: {e}")
            return []

    def _parse_dataframe(self, df: pd.DataFrame, category: str) -> list[RawData]:
        """解析 DataFrame 为 RawData 列表"""
        items = []

        for idx, row in df.iterrows():
            try:
                # 提取关键字段
                model_name = str(row.get("model_name", row.name))
                organization = str(row.get("organization", "unknown"))
                rating = float(row.get("rating", 0))
                rank = int(row.get("rank", 0)) if pd.notna(row.get("rank")) else 0

                # 构建 source_id
                source_id = f"lmarena-{category}-{model_name}"

                # 构建 metadata
                metadata = {
                    "category": category,
                    "organization": organization,
                    "license": str(row.get("license", "")),
                    "rating": rating,
                    "rating_lower": float(row.get("rating_lower")) if pd.notna(row.get("rating_lower")) else None,
                    "rating_upper": float(row.get("rating_upper")) if pd.notna(row.get("rating_upper")) else None,
                    "variance": float(row.get("variance")) if pd.notna(row.get("variance")) else None,
                    "vote_count": int(row.get("vote_count")) if pd.notna(row.get("vote_count")) else None,
                    "rank": rank,
                    "leaderboard_publish_date": str(row.get("leaderboard_publish_date", "")),
                }

                # 构建 JSON 内容
                raw_content = json.dumps(metadata, ensure_ascii=False)
                content_hash = hashlib.md5(raw_content.encode()).hexdigest()

                # 访问 URL
                url = f"https://huggingface.co/{organization}/{model_name}" if organization != "unknown" else ""

                item = RawData(
                    source=MetricSource.LM_ARENA,
                    data_type=DataType.MODEL,
                    source_id=source_id,
                    title=f"{model_name} ({organization})",
                    description=f"{category} 排行榜第 {rank} 名，ELO: {rating:.2f}",
                    url=url,
                    metadata=metadata,
                    raw_content=raw_content,
                    content_hash=content_hash,
                    fetched_at=datetime.now(timezone.utc),
                )
                items.append(item)

            except Exception as e:
                logger.debug(f"解析行 {idx} 失败: {e}")

        return items
