"""
具体爬虫实现 - Reddit

职责：抓取 Reddit r/LocalLLaMA 社区讨论
"""
import os
from typing import Optional
from datetime import datetime

from core.spider_base import ApiSpider
from core.interfaces import MetricSource, IDataProcessor


class RedditSpider(ApiSpider):
    """
    Reddit 爬虫

    数据源：Reddit API (OAuth)
    策略：抓取 r/LocalLLaMA 热门帖子
    """

    def __init__(self, *args, client_id: Optional[str] = None, client_secret: Optional[str] = None, **kwargs):
        super().__init__(*args, **kwargs)
        self.client_id = client_id or os.getenv("REDDIT_CLIENT_ID")
        self.client_secret = client_secret or os.getenv("REDDIT_CLIENT_SECRET")
        self.access_token: Optional[str] = None

    @property
    def name(self) -> str:
        return "Reddit Spider"

    @property
    def source(self) -> MetricSource:
        return MetricSource.REDDIT

    @property
    def api_base_url(self) -> str:
        return "https://oauth.reddit.com"

    async def on_start(self):
        """获取 OAuth token"""
        if not self.client_id or not self.client_secret:
            raise ValueError("Reddit API credentials are required")

        # 获取 access token
        auth_url = "https://www.reddit.com/api/v1/access_token"
        auth = (self.client_id, self.client_secret)

        # 使用 httpx 直接请求（因为需要 basic auth）
        import httpx
        async with httpx.AsyncClient() as client:
            response = await client.post(
                auth_url,
                auth=auth,
                data={"grant_type": "client_credentials"},
                headers={"User-Agent": "DaCong-Spider/1.0"}
            )

            if response.status_code == 200:
                data = response.json()
                self.access_token = data["access_token"]
                self.logger.info("Reddit OAuth token 获取成功")
            else:
                raise Exception(f"Failed to get Reddit token: {response.status_code}")

    def get_headers(self) -> dict:
        """添加 OAuth token"""
        headers = super().get_headers()
        if self.access_token:
            headers["Authorization"] = f"Bearer {self.access_token}"
        return headers

    async def fetch(self) -> list[dict]:
        """
        抓取 Reddit 帖子

        策略：
        1. 获取 r/LocalLLaMA 热门帖子
        2. 限制 50 个
        """
        endpoint = "r/LocalLLaMA/hot?limit=50"
        data = await self.fetch_json(endpoint)

        if not data or "data" not in data:
            self.logger.warning("抓取 Reddit 帖子失败")
            return []

        posts = [child["data"] for child in data["data"]["children"]]
        self.logger.info(f"抓取到 {len(posts)} 个帖子")
        return posts


class RedditDataProcessor(IDataProcessor):
    """
    Reddit 数据处理器

    职责：将 Reddit API 响应转换为标准化的 RawData
    """

    def __init__(self):
        from core.implementations import BaseDataProcessor
        from core.interfaces import DataType

        self.base = BaseDataProcessor(MetricSource.REDDIT, DataType.POST)

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
                source=MetricSource.REDDIT,
                data_type="post",
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
            logging.error(f"Failed to process Reddit data: {e}")
            return None

    def generate_content_hash(self, data: dict) -> str:
        return self.base.generate_content_hash(data)

    def _extract_source_id(self, data: dict) -> str:
        return data["id"]

    def _extract_title(self, data: dict) -> str:
        return data["title"]

    def _extract_description(self, data: dict) -> str:
        selftext = data.get("selftext", "")
        return selftext[:200] if selftext else ""

    def _extract_url(self, data: dict) -> str:
        return data.get("url", f"https://reddit.com{data.get('permalink', '')}")

    def _extract_metadata(self, data: dict) -> dict:
        return {
            "score": data.get("score", 0),
            "num_comments": data.get("num_comments", 0),
            "author": data.get("author"),
            "created_utc": datetime.fromtimestamp(data["created_utc"]).isoformat(),
            "subreddit": data.get("subreddit"),
            "is_self": data.get("is_self", False),
            "upvote_ratio": data.get("upvote_ratio", 0)
        }

    def __getattr__(self, name):
        if name.startswith("_extract_"):
            return getattr(self, name)
        return getattr(self.base, name)
