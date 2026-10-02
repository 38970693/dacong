"""
AI 新闻 RSS Spider（可选、保持小）
抓取几个主流 AI 媒体 RSS，保留媒体名写入 hot_news_raw。
"""
import asyncio
import logging
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
from bs4 import BeautifulSoup

from config import SPIDERS
from core.base import SpiderBase
from core.fetcher import Fetcher
from core.writer import Writer
from models.metrics import HotNewsItem, SpiderResult

logger = logging.getLogger(__name__)

# 默认抓取的主流 AI 媒体 RSS（可在 config 的 SPIDERS['ai_news_rss']['feeds'] 覆盖）
DEFAULT_FEEDS: list[tuple[str, str]] = [
    ("OpenAI", "https://openai.com/news/rss.xml"),
    ("HuggingFace", "https://huggingface.co/blog/feed.xml"),
    ("GitHub", "https://github.blog/ai-and-ml/feed/"),
    ("TheSequence", "https://thesequence.substack.com/feed"),
    ("VentureBeat_AI", "https://venturebeat.com/category/ai/feed/"),
    ("Google_AI", "https://blog.google/technology/ai/rss/"),
    ("MIT_Tech_AI", "https://www.technologyreview.com/topic/artificial-intelligence/feed"),
]

SUMMARY_MAX_LEN = 500


def parse_rss_feed(xml: str) -> list[dict]:
    """
    解析 RSS 2.0 feed（纯函数，便于单测）
    Returns: [{"title", "summary", "url", "published"}]
    """
    soup = BeautifulSoup(xml, "xml")
    items: list[dict] = []

    for item in soup.find_all(["item", "entry"]):
        title_el = item.find("title")
        title = " ".join(title_el.get_text(strip=True).split()) if title_el else ""
        if not title:
            continue

        link_el = item.find("link", attrs={"rel": "alternate"}) or item.find("link", attrs={"href": True}) or item.find("link")
        url = (link_el.get("href") or link_el.get_text(strip=True)) if link_el else ""
        if not url:
            continue

        desc_el = item.find("description") or item.find("summary") or item.find("content")
        summary = ""
        if desc_el:
            summary = " ".join(BeautifulSoup(desc_el.get_text(" ", strip=True), "html.parser").get_text(" ", strip=True).split())
            if len(summary) > SUMMARY_MAX_LEN:
                summary = summary[:SUMMARY_MAX_LEN].rstrip() + "…"

        pub_el = item.find("pubDate") or item.find("published") or item.find("updated")
        published = pub_el.get_text(strip=True) if pub_el else ""

        items.append({
            "title": title,
            "summary": summary,
            "url": url,
            "published": published,
        })

    return items


def publication_date(value: str):
    if not value:
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        try:
            parsed = parsedate_to_datetime(value)
        except (ValueError, TypeError):
            return None
    return parsed.replace(tzinfo=timezone.utc) if parsed.tzinfo is None else parsed.astimezone(timezone.utc)


class AINewsRssSpider(SpiderBase):
    """
    AI 媒体 RSS Spider
    抓取多个 RSS 源，写入 hot_news_raw（source=媒体标签，is_ai_related=True）
    """

    @property
    def name(self) -> str:
        return "AINewsRSS"

    @property
    def retry_delay(self) -> float:
        return 3.0

    def _feeds(self) -> list[tuple[str, str]]:
        cfg = SPIDERS.get("ai_news_rss", {})
        feeds = cfg.get("feeds")
        if feeds:
            return [(f["label"], f["url"]) for f in feeds]
        return DEFAULT_FEEDS

    async def do_fetch(self, fetcher: Fetcher, writer: Writer) -> SpiderResult:
        errors: list[str] = []
        total_fetched = 0
        total_written = 0

        for label, url in self._feeds():
            resp = await fetcher.get(url)
            if not resp:
                errors.append(f"获取 {label} RSS 失败")
                await asyncio.sleep(self.retry_delay)
                continue

            entries = parse_rss_feed(resp.text)
            total_fetched += len(entries)
            logger.info(f"[AINewsRSS] {label}: {len(entries)} 条")

            total_written += self._write_news(writer, entries, label)

            await asyncio.sleep(2.0)

        return SpiderResult(
            spider_name=self.name,
            success=len(errors) == 0,
            items_fetched=total_fetched,
            items_written=total_written,
            errors=errors,
        )

    def _write_news(self, writer: Writer, entries: list[dict], source: str) -> int:
        written = 0

        for e in entries:
            news = HotNewsItem(
                source=source,
                title=e["title"],
                url=e["url"],
                summary=e["summary"],
                is_ai_related=True,
                source_published_at=publication_date(e.get("published", "")),
            )
            try:
                if writer.upsert_hot_news(news):
                    written += 1
            except Exception as ex:
                logger.error(f"[AINewsRSS] 写入失败: {ex}")

        return written
