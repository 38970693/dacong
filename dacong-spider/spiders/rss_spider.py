"""
具体爬虫实现 - RSS 订阅源（Twitter/X, Google News 等）

职责：使用 RSSHub 提供统一 RSS 订阅方式抓取社交媒体和新闻
"""
import asyncio
import hashlib
import json
import logging
import re
from datetime import datetime, timezone
from typing import Optional
from xml.etree import ElementTree as ET

from core.interfaces import (
    MetricSource, DataType, RawData, IDataProcessor, IHttpClient,
    IDataStorage, IDeduplicator, ILogger
)
from core.spider_base import BaseSpider
from core.implementations import ContentHashDeduplicator, HttpClient

logger = logging.getLogger(__name__)


class RSSSpider(BaseSpider):
    """
    RSS 订阅源爬虫

    支持数据源：
    - Twitter/X: 用户推文、搜索结果
    - Google News: 特定主题新闻

    使用 RSSHub (https://github.com/DIYgod/RSSHub) 提供 RSS 源
    """

    def __init__(
        self,
        http_client: IHttpClient,
        data_processor: IDataProcessor,
        storage: IDataStorage,
        deduplicator: IDeduplicator,
        logger: ILogger,
        rsshub_base_url: str = "https://rsshub.app",
        feed_configs: Optional[list[dict]] = None,
        keywords: Optional[list[str]] = None
    ):
        super().__init__(
            http_client=http_client,
            data_processor=data_processor,
            storage=storage,
            deduplicator=deduplicator,
            logger=logger
        )
        self.rsshub_base_url = rsshub_base_url.rstrip('/')
        self.feed_configs = feed_configs or []
        self.keywords = keywords or ["AI", "machine learning", "artificial intelligence"]
        self.data_processor = RSSDataProcessor()

    @property
    def name(self) -> str:
        return "RSS Spider"

    @property
    def source(self) -> MetricSource:
        return MetricSource.GOOGLE_NEWS  # 统一使用 google_news 作为 RSS 源标识

    @property
    def default_interval_hours(self) -> int:
        return 4  # 每 4 小时更新一次（新闻需要更频繁）

    async def fetch(self) -> list[dict]:
        """
        抓取所有配置的 RSS 源

        策略：
        1. 解析 feed_configs 获取各数据源配置
        2. 对每个配置生成 RSSHub URL
        3. 并行抓取所有源
        4. 过滤关键词相关条目
        """
        all_items = []

        # 如果没有配置 feed，使用默认配置
        if not self.feed_configs:
            self.feed_configs = self._get_default_feeds()

        # 并行抓取所有源
        tasks = [self._fetch_feed(config) for config in self.feed_configs]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        for result in results:
            if isinstance(result, list):
                all_items.extend(result)

        # 去重（按 source_id）
        seen_ids = set()
        unique_items = []
        for item in all_items:
            item_id = item.get("id", item.get("link", ""))
            if item_id not in seen_ids:
                seen_ids.add(item_id)
                unique_items.append(item)

        self.logger.info(f"抓取到 {len(unique_items)} 个 RSS 条目")
        return unique_items

    def _get_default_feeds(self) -> list[dict]:
        """获取默认 RSS 源配置"""
        return [
            # Google News AI 相关
            {
                "type": "google_news",
                "source": MetricSource.GOOGLE_NEWS,
                "url_pattern": "/google news search/{keyword}",
                "params": {"keyword": "AI"},
                "name": "Google News - AI"
            },
            {
                "type": "google_news",
                "source": MetricSource.GOOGLE_NEWS,
                "url_pattern": "/google news search/{keyword}",
                "params": {"keyword": "machine learning"},
                "name": "Google News - ML"
            },
            # Twitter 搜索
            {
                "type": "twitter",
                "source": MetricSource.TWITTER,
                "url_pattern": "/twitter/search/{keyword}",
                "params": {"keyword": "AI"},
                "name": "Twitter - AI"
            },
        ]

    async def _fetch_feed(self, config: dict) -> list[dict]:
        """抓取单个 RSS 源"""
        try:
            url = self._build_rsshub_url(config)
            if not url:
                return []

            # 使用 http_client 获取 XML
            response = await self.http_client.get(url)
            if not response:
                self.logger.warning(f"获取 RSS 源失败: {config.get('name', 'unknown')}")
                return []

            # 解析 XML
            items = self._parse_rss(response, config)
            return items

        except Exception as e:
            self.logger.error(f"抓取 RSS 源 {config.get('name', 'unknown')} 失败: {e}")
            return []

    def _build_rsshub_url(self, config: dict) -> str:
        """构建 RSSHub URL"""
        pattern = config.get("url_pattern", "")
        params = config.get("params", {})

        if not pattern:
            return ""

        # 替换路径参数
        url = pattern
        for key, value in params.items():
            url = url.replace(f"{{{key}}}", str(value))

        return f"{self.rsshub_base_url}{url}"

    def _parse_rss(self, xml_content: str, config: dict) -> list[dict]:
        """解析 RSS XML"""
        items = []
        source_type = config.get("type", "unknown")
        source = config.get("source", MetricSource.GOOGLE_NEWS)
        feed_name = config.get("name", "unknown")

        try:
            root = ET.fromstring(xml_content)

            # 尝试不同的 RSS 格式
            if root.tag == "rss":
                # 标准 RSS 2.0
                channel = root.find("channel")
                if channel:
                    for item in channel.findall("item"):
                        parsed = self._parse_rss_item(item, source_type, source, feed_name)
                        if parsed:
                            items.append(parsed)
            elif root.tag.endswith("feed"):
                # Atom 格式
                for entry in root.findall("entry"):
                    parsed = self._parse_atom_entry(entry, source_type, source, feed_name)
                    if parsed:
                        items.append(parsed)

        except ET.ParseError as e:
            logger.error(f"RSS XML 解析失败: {e}")

        return items

    def _parse_rss_item(self, item, source_type: str, source: MetricSource, feed_name: str) -> dict:
        """解析 RSS item 元素"""
        def get_text(element, tag, default=""):
            el = item.find(tag)
            return el.text if el is not None and el.text else default

        # 提取基本字段
        title = get_text(item, "title")
        link = get_text(item, "link")
        description = get_text(item, "description")
        pub_date = get_text(item, "pubDate")
        guid = get_text(item, "guid", link)

        # 过滤关键词（如果配置了关键词）
        if self.keywords:
            text = f"{title} {description}".lower()
            if not any(kw.lower() in text for kw in self.keywords):
                return None

        return {
            "id": guid,
            "title": title,
            "link": link,
            "description": self._clean_html(description),
            "pub_date": pub_date,
            "source_type": source_type,
            "source": source.value,
            "feed_name": feed_name,
            "raw": item
        }

    def _parse_atom_entry(self, entry, source_type: str, source: MetricSource, feed_name: str) -> dict:
        """解析 Atom entry 元素"""
        def get_text(element, tag, default=""):
            el = entry.find(tag)
            return el.text if el is not None and el.text else default

        # Atom 使用 link rel="alternate" 或第一个 link
        links = entry.findall("link")
        link = ""
        for l in links:
            rel = l.get("rel", "alternate")
            if rel == "alternate":
                link = l.get("href", "")
                break
        if not link and links:
            link = links[0].get("href", "")

        title = get_text(entry, "title")
        summary = get_text(entry, "summary") or get_text(entry, "content")
        updated = get_text(entry, "updated") or get_text(entry, "published")

        # 过滤关键词
        if self.keywords:
            text = f"{title} {summary}".lower()
            if not any(kw.lower() in text for kw in self.keywords):
                return None

        return {
            "id": link,
            "title": title,
            "link": link,
            "description": self._clean_html(summary),
            "pub_date": updated,
            "source_type": source_type,
            "source": source.value,
            "feed_name": feed_name,
            "raw": entry
        }

    def _clean_html(self, text: str) -> str:
        """清理 HTML 标签"""
        if not text:
            return ""
        import re
        # 移除 HTML 标签
        clean = re.sub(r'<[^>]+>', '', text)
        # 清理多余空白
        clean = re.sub(r'\s+', ' ', clean).strip()
        return clean[:500]  # 限制长度

    async def process_item(self, raw_data: dict) -> Optional[RawData]:
        """处理单条 RSS 数据"""
        return self.data_processor.process(raw_data)


class TwitterSpider(RSSSpider):
    """
    Twitter/X 专用爬虫

    简化的 Twitter 抓取接口
    """

    def __init__(
        self,
        http_client: IHttpClient,
        data_processor: IDataProcessor,
        storage: IDataStorage,
        deduplicator: IDeduplicator,
        logger: ILogger,
        rsshub_base_url: str = "https://rsshub.app",
        search_keywords: Optional[list[str]] = None,
        user_timelines: Optional[list[str]] = None
    ):
        # 构建 Twitter 专用配置
        feed_configs = []

        # 搜索关键词
        if search_keywords:
            for kw in search_keywords:
                feed_configs.append({
                    "type": "twitter",
                    "source": MetricSource.TWITTER,
                    "url_pattern": f"/twitter/search/{kw.replace(' ', '%20')}",
                    "params": {},
                    "name": f"Twitter Search - {kw}"
                })

        # 用户时间线
        if user_timelines:
            for user in user_timelines:
                feed_configs.append({
                    "type": "twitter",
                    "source": MetricSource.TWITTER,
                    "url_pattern": f"/twitter/user/{user}",
                    "params": {},
                    "name": f"Twitter - @{user}"
                })

        super().__init__(
            http_client=http_client,
            data_processor=data_processor,
            storage=storage,
            deduplicator=deduplicator,
            logger=logger,
            rsshub_base_url=rsshub_base_url,
            feed_configs=feed_configs,
            keywords=search_keywords
        )

    @property
    def name(self) -> str:
        return "Twitter Spider"

    @property
    def source(self) -> MetricSource:
        return MetricSource.TWITTER


class GoogleNewsSpider(RSSSpider):
    """
    Google News 专用爬虫

    简化的 Google News 抓取接口
    """

    def __init__(
        self,
        http_client: IHttpClient,
        data_processor: IDataProcessor,
        storage: IDataStorage,
        deduplicator: IDeduplicator,
        logger: ILogger,
        rsshub_base_url: str = "https://rsshub.app",
        search_topics: Optional[list[str]] = None
    ):
        # 构建 Google News 专用配置
        feed_configs = []

        # 搜索主题
        topics = search_topics or ["AI", "machine learning", "artificial intelligence"]
        for topic in topics:
            feed_configs.append({
                "type": "google_news",
                "source": MetricSource.GOOGLE_NEWS,
                "url_pattern": f"/google news search/{topic.replace(' ', '%20')}",
                "params": {},
                "name": f"Google News - {topic}"
            })

        super().__init__(
            http_client=http_client,
            data_processor=data_processor,
            storage=storage,
            deduplicator=deduplicator,
            logger=logger,
            rsshub_base_url=rsshub_base_url,
            feed_configs=feed_configs,
            keywords=topics
        )

    @property
    def name(self) -> str:
        return "Google News Spider"

    @property
    def source(self) -> MetricSource:
        return MetricSource.GOOGLE_NEWS


class RSSDataProcessor(IDataProcessor):
    """
    RSS 数据处理器

    职责：将 RSS 条目转换为标准化的 RawData
    """

    def __init__(self):
        self.deduplicator = ContentHashDeduplicator()

    def process(self, raw_data: dict) -> Optional[RawData]:
        """处理原始数据，转换为 RawData DTO"""
        try:
            source_str = raw_data.get("source", "google_news")
            source = MetricSource(source_str)

            data_type_str = raw_data.get("source_type", "news")
            if data_type_str == "twitter":
                data_type = DataType.POST
            else:
                data_type = DataType.NEWS

            source_id = raw_data.get("id", "")
            title = raw_data.get("title", "Untitled")
            description = raw_data.get("description", "")
            url = raw_data.get("link", "")
            feed_name = raw_data.get("feed_name", "")
            pub_date = raw_data.get("pub_date", "")

            # 生成元数据
            metadata = {
                "feed_name": feed_name,
                "pub_date": pub_date,
                "source_type": raw_data.get("source_type", ""),
            }

            content = json.dumps(raw_data, sort_keys=True, ensure_ascii=False)
            content_hash = hashlib.md5(content.encode()).hexdigest()

            return RawData(
                source=source,
                data_type=data_type,
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
            logger.error(f"Failed to process RSS data: {e}")
            return None

    def generate_content_hash(self, data: dict) -> str:
        """生成内容哈希"""
        content = json.dumps(data, sort_keys=True, ensure_ascii=False)
        return hashlib.md5(content.encode()).hexdigest()
