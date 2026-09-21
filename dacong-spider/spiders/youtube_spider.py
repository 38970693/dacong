"""
具体爬虫实现 - YouTube

职责：使用 yt-dlp 抓取 YouTube 视频元数据和统计信息
"""
import asyncio
import hashlib
import json
import logging
from datetime import datetime, timezone
from typing import Optional

import yt_dlp

from core.interfaces import (
    MetricSource, DataType, RawData, IDataProcessor, IHttpClient,
    IDataStorage, IDeduplicator, ILogger
)
from core.spider_base import BaseSpider
from core.implementations import ContentHashDeduplicator

logger = logging.getLogger(__name__)


class YouTubeSpider(BaseSpider):
    """
    YouTube 爬虫

    数据源：YouTube Data API / yt-dlp
    策略：抓取指定频道/播放列表的最新视频，过滤 AI 相关
    """

    def __init__(
        self,
        http_client: IHttpClient,
        data_processor: IDataProcessor,
        storage: IDataStorage,
        deduplicator: IDeduplicator,
        logger: ILogger,
        channel_ids: Optional[list[str]] = None,
        keywords: Optional[list[str]] = None,
        max_results: int = 50
    ):
        super().__init__(
            http_client=http_client,
            data_processor=data_processor,
            storage=storage,
            deduplicator=deduplicator,
            logger=logger
        )
        self.channel_ids = channel_ids or []
        self.keywords = keywords or ["AI", "machine learning", "GPT", "LLM", "neural network"]
        self.max_results = max_results
        self.data_processor = YouTubeDataProcessor()

    @property
    def name(self) -> str:
        return "YouTube Spider"

    @property
    def source(self) -> MetricSource:
        return MetricSource.YOUTUBE

    @property
    def default_interval_hours(self) -> int:
        return 6  # 每 6 小时更新一次

    async def fetch(self) -> list[dict]:
        """
        抓取 YouTube 视频

        使用 yt-dlp 的 --flat-playlist 模式获取视频信息
        """
        videos = []

        # 如果配置了频道 ID，抓取频道视频
        if self.channel_ids:
            for channel_id in self.channel_ids:
                channel_videos = await self._fetch_channel_videos(channel_id)
                videos.extend(channel_videos)

        # 如果没有配置频道，抓取搜索结果（关键词过滤）
        if not self.channel_ids:
            videos = await self._fetch_by_keywords()

        self.logger.info(f"抓取到 {len(videos)} 个 YouTube 视频")
        return videos

    async def _fetch_channel_videos(self, channel_id: str) -> list[dict]:
        """抓取频道的最新视频"""
        try:
            playlist_url = f"https://www.youtube.com/channel/{channel_id}/videos"

            # yt-dlp 需要在线程池中运行
            loop = asyncio.get_event_loop()
            video_info = await loop.run_in_executor(
                None,
                self._extract_videos,
                playlist_url
            )

            # 过滤 AI 相关视频
            filtered = [v for v in video_info if self._is_ai_related(v)]
            return filtered

        except Exception as e:
            self.logger.error(f"抓取频道 {channel_id} 失败: {e}")
            return []

    async def _fetch_by_keywords(self) -> list[dict]:
        """使用搜索获取 AI 相关视频"""
        videos = []
        for keyword in self.keywords[:5]:  # 限制关键词数量
            try:
                search_url = f"ytsearch{self.max_results}:{keyword}"
                loop = asyncio.get_event_loop()
                results = await loop.run_in_executor(
                    None,
                    self._extract_videos,
                    search_url
                )
                videos.extend(results)
            except Exception as e:
                self.logger.error(f"搜索 '{keyword}' 失败: {e}")

        # 去重（过滤 None 值）
        seen_ids = set()
        unique_videos = []
        for v in videos:
            if v is None:
                continue
            vid = v.get("id", "")
            if vid and vid not in seen_ids:
                seen_ids.add(vid)
                unique_videos.append(v)

        return unique_videos

    def _extract_videos(self, url: str) -> list[dict]:
        """使用 yt-dlp 提取视频信息"""
        ydl_opts = {
            'quiet': True,
            'no_warnings': True,
            'extract_flat': True,  # 仅获取元数据，不下载
            'ignoreerrors': True,
            'force_generic_extractor': True,
        }

        videos = []
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            try:
                result = ydl.extract_info(url, download=False)
                if result and 'entries' in result:
                    # 过滤 None 值（yt-dlp entries 迭代器可能返回 None）
                    videos = [e for e in result['entries'] if e is not None]
                elif result:
                    videos = [result]
            except Exception as e:
                logger.error(f"yt-dlp extraction failed for {url}: {e}")

        return videos

    def _is_ai_related(self, video: dict) -> bool:
        """判断视频是否与 AI 相关"""
        title = video.get("title", "").lower()
        description = video.get("description", "").lower()

        ai_keywords = [
            "ai", "llm", "gpt", "claude", "model", "machine learning",
            "deep learning", "neural", "transformer", "openai", "anthropic",
            "artificial intelligence", "chatgpt", "stable diffusion"
        ]

        text = f"{title} {description}"
        return any(keyword in text for keyword in ai_keywords)

    async def process_item(self, raw_data: dict) -> Optional[RawData]:
        """处理单条视频数据"""
        return self.data_processor.process(raw_data)


class YouTubeDataProcessor(IDataProcessor):
    """
    YouTube 数据处理器

    职责：将 yt-dlp 响应转换为标准化的 RawData
    """

    def __init__(self):
        self.source = MetricSource.YOUTUBE
        self.data_type = DataType.NEWS
        self.deduplicator = ContentHashDeduplicator()

    def process(self, raw_data: dict) -> Optional[RawData]:
        """处理原始数据，转换为 RawData DTO"""
        try:
            source_id = self._extract_source_id(raw_data)
            title = self._extract_title(raw_data)
            description = self._extract_description(raw_data)
            url = self._extract_url(raw_data)
            metadata = self._extract_metadata(raw_data)

            content = json.dumps(raw_data, sort_keys=True, ensure_ascii=False)
            content_hash = hashlib.md5(content.encode()).hexdigest()

            return RawData(
                source=self.source,
                data_type=self.data_type,
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
            logger.error(f"Failed to process YouTube data: {e}")
            return None

    def generate_content_hash(self, data: dict) -> str:
        """生成内容哈希"""
        content = json.dumps(data, sort_keys=True, ensure_ascii=False)
        return hashlib.md5(content.encode()).hexdigest()

    def _extract_source_id(self, data: dict) -> str:
        """提取视频 ID"""
        return data.get("id", data.get("display_id", ""))

    def _extract_title(self, data: dict) -> str:
        """提取标题"""
        return data.get("title", "Untitled")

    def _extract_description(self, data: dict) -> str:
        """提取描述（前 500 字符）"""
        desc = data.get("description", "")
        return desc[:500] if desc else ""

    def _extract_url(self, data: dict) -> str:
        """提取视频 URL"""
        video_id = data.get("id", data.get("display_id", ""))
        return f"https://www.youtube.com/watch?v={video_id}"

    def _extract_metadata(self, data: dict) -> dict:
        """提取元数据"""
        # 处理可能的字段名称差异
        channel = data.get("channel") or data.get("uploader", "Unknown")
        channel_id = data.get("channel_id", "")
        duration = data.get("duration", 0)
        view_count = data.get("view_count", 0)
        like_count = data.get("like_count", data.get("average_rating", 0))
        upload_date = data.get("upload_date", "")

        return {
            "channel": channel,
            "channel_id": channel_id,
            "duration_seconds": duration,
            "view_count": view_count,
            "like_count": like_count,
            "upload_date": self._format_date(upload_date),
            "thumbnail": data.get("thumbnail", ""),
            "tags": data.get("tags", []),
            "categories": data.get("categories", []),
        }

    def _format_date(self, date_str: str) -> str:
        """格式化日期 YYYYMMDD -> ISO 格式"""
        if not date_str or len(date_str) != 8:
            return ""
        try:
            dt = datetime.strptime(date_str, "%Y%m%d")
            return dt.isoformat()
        except:
            return date_str
