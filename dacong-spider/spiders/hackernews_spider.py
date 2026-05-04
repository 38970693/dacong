"""
具体爬虫实现 - Hacker News

职责：抓取 Hacker News AI 相关新闻
"""
from datetime import datetime

from core.spider_base import ApiSpider
from core.interfaces import MetricSource, IDataProcessor
from config import HUGGINGFACE_AI_KEYWORDS


class HackerNewsSpider(ApiSpider):
    """
    Hacker News 爬虫

    数据源：Hacker News Firebase API
    策略：抓取热门故事，过滤 AI 相关
    """

    @property
    def name(self) -> str:
        return "Hacker News Spider"

    @property
    def source(self) -> MetricSource:
        return MetricSource.HACKERNEWS

    @property
    def api_base_url(self) -> str:
        return "https://hacker-news.firebaseio.com/v0"

    async def fetch(self) -> list[dict]:
        """
        抓取 Hacker News 故事

        策略：
        1. 获取热门故事 ID 列表
        2. 逐个获取故事详情
        3. 过滤 AI 相关故事
        """
        # 1. 获取热门故事 ID
        endpoint = "topstories.json"
        story_ids = await self.fetch_json(endpoint)

        if not story_ids:
            self.logger.warning("抓取 Hacker News 故事 ID 失败")
            return []

        # 2. 获取前 100 个故事详情
        stories = []
        for story_id in story_ids[:100]:
            story = await self._fetch_story(story_id)
            if story and self._is_ai_related(story):
                stories.append(story)

        self.logger.info(f"抓取到 {len(stories)} 个 AI 相关故事")
        return stories

    async def _fetch_story(self, story_id: int) -> dict:
        """获取单个故事详情"""
        endpoint = f"item/{story_id}.json"
        return await self.fetch_json(endpoint)

    def _is_ai_related(self, story: dict) -> bool:
        """判断是否为 AI 相关故事"""
        title = story.get("title", "").lower()
        text = story.get("text", "").lower()

        ai_keywords = [
            "ai", "llm", "gpt", "claude", "model", "machine learning",
            "deep learning", "neural", "transformer", "openai", "anthropic"
        ]

        return any(keyword in title or keyword in text for keyword in ai_keywords)


class HackerNewsDataProcessor(IDataProcessor):
    """
    Hacker News 数据处理器

    职责：将 Hacker News API 响应转换为标准化的 RawData
    """

    def __init__(self):
        from core.implementations import BaseDataProcessor
        from core.interfaces import DataType

        self.base = BaseDataProcessor(MetricSource.HACKERNEWS, DataType.NEWS)

    def process(self, raw_data: dict):
        """
        处理原始数据，转换为 RawData DTO
        注意：直接实现而不是委托给 base，以使用子类自己的 _extract_ 方法
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
                source=MetricSource.HACKERNEWS,
                data_type="news",
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
            logging.error(f"Failed to process data: {e}")
            return None

    def generate_content_hash(self, data: dict) -> str:
        return self.base.generate_content_hash(data)

    def _extract_source_id(self, data: dict) -> str:
        # 优先使用 hn_id，其次使用 id
        return str(data.get("hn_id") or data.get("id", ""))

    def _extract_title(self, data: dict) -> str:
        return data["title"]

    def _extract_description(self, data: dict) -> str:
        text = data.get("text", "")
        return text[:200] if text else ""

    def _extract_url(self, data: dict) -> str:
        # 优先使用外部链接，否则使用 HN 讨论页
        return data.get("url", f"https://news.ycombinator.com/item?id={data['id']}")

    def _extract_metadata(self, data: dict) -> dict:
        return {
            "score": data.get("score", 0),
            "num_comments": data.get("descendants", 0),
            "author": data.get("by"),
            "created_at": datetime.fromtimestamp(data["time"]).isoformat(),
            "type": data.get("type", "story")
        }

    def __getattr__(self, name):
        if name.startswith("_extract_"):
            return getattr(self, name)
        return getattr(self.base, name)
