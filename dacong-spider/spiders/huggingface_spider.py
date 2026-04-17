"""
具体爬虫实现 - HuggingFace

职责：抓取 HuggingFace 热门模型
"""
from core.spider_base import ApiSpider
from core.interfaces import MetricSource, IDataProcessor


class HuggingFaceSpider(ApiSpider):
    """
    HuggingFace 爬虫

    数据源：HuggingFace Models API
    策略：按下载量排序，获取热门模型
    """

    @property
    def name(self) -> str:
        return "HuggingFace Spider"

    @property
    def source(self) -> MetricSource:
        return MetricSource.HUGGINGFACE

    @property
    def api_base_url(self) -> str:
        return "https://huggingface.co/api"

    async def fetch(self) -> list[dict]:
        """
        抓取 HuggingFace 模型

        策略：
        1. 获取按下载量排序的模型
        2. 限制 100 个
        """
        endpoint = "models?sort=downloads&direction=-1&limit=100"
        data = await self.fetch_json(endpoint)

        if not data:
            self.logger.warning("抓取 HuggingFace 模型失败")
            return []

        self.logger.info(f"抓取到 {len(data)} 个模型")
        return data


class HuggingFaceDataProcessor(IDataProcessor):
    """
    HuggingFace 数据处理器

    职责：将 HuggingFace API 响应转换为标准化的 RawData
    """

    def __init__(self):
        from core.implementations import BaseDataProcessor
        from core.interfaces import DataType

        self.source = MetricSource.HUGGINGFACE
        self.data_type = DataType.MODEL

    def process(self, raw_data: dict):
        """处理原始数据"""
        from core.interfaces import RawData
        from datetime import datetime, timezone
        import logging

        logger = logging.getLogger(__name__)

        try:
            # 验证必填字段
            if "modelId" not in raw_data:
                logger.warning("Missing required field: modelId")
                return None

            source_id = self._extract_source_id(raw_data)
            title = self._extract_title(raw_data)
            description = self._extract_description(raw_data)
            url = self._extract_url(raw_data)
            metadata = self._extract_metadata(raw_data)
            content_hash = self.generate_content_hash(raw_data)

            return RawData(
                source=self.source,
                data_type=self.data_type,
                source_id=source_id,
                title=title,
                description=description,
                url=url,
                metadata=metadata,
                raw_content="",
                content_hash=content_hash,
                fetched_at=datetime.now(timezone.utc)
            )
        except Exception as e:
            logger.error(f"Failed to process HuggingFace data: {e}", exc_info=True)
            return None

    def generate_content_hash(self, data: dict) -> str:
        """生成内容哈希"""
        import hashlib
        import json

        # 使用关键字段生成哈希
        key_fields = {
            "modelId": data.get("modelId"),
            "downloads": data.get("downloads"),
            "likes": data.get("likes"),
        }
        content = json.dumps(key_fields, sort_keys=True)
        return hashlib.md5(content.encode()).hexdigest()

    def _extract_source_id(self, data: dict) -> str:
        return data["modelId"]

    def _extract_title(self, data: dict) -> str:
        # 提取模型名（去掉作者前缀）
        model_id = data["modelId"]
        return model_id.split("/")[-1] if "/" in model_id else model_id

    def _extract_description(self, data: dict) -> str:
        author = data.get("author", "")
        pipeline = data.get("pipeline_tag", "")
        return f"{author} - {pipeline}" if pipeline else author

    def _extract_url(self, data: dict) -> str:
        return f"https://huggingface.co/{data['modelId']}"

    def _extract_metadata(self, data: dict) -> dict:
        return {
            "author": data.get("author"),
            "downloads": data.get("downloads", 0),
            "likes": data.get("likes", 0),
            "tags": data.get("tags", []),
            "pipeline_tag": data.get("pipeline_tag"),
            "library_name": data.get("library_name"),
            "created_at": data.get("createdAt"),
            "last_modified": data.get("lastModified")
        }
