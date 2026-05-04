"""
具体爬虫实现 - OpenRouter

职责：抓取 AI 模型价格信息
"""
from core.spider_base import ApiSpider
from core.interfaces import MetricSource, IDataProcessor


class OpenRouterSpider(ApiSpider):
    """
    OpenRouter 爬虫

    数据源：OpenRouter Models API
    策略：获取所有模型的价格信息
    """

    @property
    def name(self) -> str:
        return "OpenRouter Spider"

    @property
    def source(self) -> MetricSource:
        return MetricSource.OPENROUTER

    @property
    def api_base_url(self) -> str:
        return "https://openrouter.ai/api/v1"

    async def fetch(self) -> list[dict]:
        """
        抓取 OpenRouter 模型价格

        策略：
        1. 获取所有模型
        2. 提取价格信息
        """
        endpoint = "models"
        data = await self.fetch_json(endpoint)

        if not data or "data" not in data:
            self.logger.warning("抓取 OpenRouter 模型失败")
            return []

        models = data["data"]
        self.logger.info(f"抓取到 {len(models)} 个模型")
        return models


class OpenRouterDataProcessor(IDataProcessor):
    """
    OpenRouter 数据处理器

    职责：将 OpenRouter API 响应转换为标准化的 RawData
    """

    def __init__(self):
        from core.implementations import BaseDataProcessor
        from core.interfaces import DataType

        self.base = BaseDataProcessor(MetricSource.OPENROUTER, DataType.PRICING)

    def process(self, raw_data: dict):
        """
        处理原始数据，转换为 RawData DTO
        注意：直接实现以使用子类自己的 _extract_ 方法
        """
        from datetime import datetime, timezone
        import hashlib
        import json
        from core.implementations import RawData

        try:
            source_id = self._extract_source_id(raw_data)
            title = self._extract_title(raw_data)
            description = self._extract_description(raw_data)
            url = self._extract_url(raw_data)
            metadata = self._extract_metadata(raw_data)

            content = json.dumps(raw_data, sort_keys=True, ensure_ascii=False)
            content_hash = hashlib.md5(content.encode()).hexdigest()

            return RawData(
                source=MetricSource.OPENROUTER,
                data_type="pricing",
                source_id=source_id,
                title=title,
                description=description,
                url=url,
                metadata=metadata,
                raw_content=content,
                content_hash=content_hash,
                fetched_at=datetime.now(timezone.utc)
            )
        except Exception as e:
            logging.error(f"Failed to process OpenRouter data: {e}")
            return None

    def generate_content_hash(self, data: dict) -> str:
        return self.base.generate_content_hash(data)

    def _extract_source_id(self, data: dict) -> str:
        return data["id"]

    def _extract_title(self, data: dict) -> str:
        return data.get("name", data["id"])

    def _extract_description(self, data: dict) -> str:
        context_length = data.get("context_length", 0)
        return f"Context: {context_length:,} tokens"

    def _extract_url(self, data: dict) -> str:
        model_id = data["id"].replace("/", "%2F")
        return f"https://openrouter.ai/models/{model_id}"

    def _extract_metadata(self, data: dict) -> dict:
        pricing = data.get("pricing", {})
        architecture = data.get("architecture", {})

        return {
            "price_input": float(pricing.get("prompt", 0)),
            "price_output": float(pricing.get("completion", 0)),
            "context_length": data.get("context_length", 0),
            "modality": architecture.get("modality"),
            "tokenizer": architecture.get("tokenizer"),
            "instruct_type": architecture.get("instruct_type")
        }

    def __getattr__(self, name):
        if name.startswith("_extract_"):
            return getattr(self, name)
        return getattr(self.base, name)
