"""
arXiv Spider
策略：调用 arXiv Atom API 抓取 cs.AI / cs.CL 近期论文
论文本身即 AI 相关，写入 hot_news_raw（source='arxiv', is_ai_related=True）

写入说明：HotNewsItem / Writer 不带 is_ai_related 字段（不可改动），
故此处复用 Writer 的 Supabase 客户端 + 24h 去重模式，直接 insert 并显式置 is_ai_related=True。
"""
import asyncio
import logging
from datetime import datetime, timedelta, timezone

from bs4 import BeautifulSoup

from config import SPIDERS
from core.base import SpiderBase
from core.fetcher import Fetcher
from core.writer import Writer
from models.metrics import SpiderResult

logger = logging.getLogger(__name__)

# 抓取的 arXiv 分类
ARXIV_CATEGORIES = ["cs.AI", "cs.CL"]

# arXiv Atom API 模板
ARXIV_API_TMPL = (
    "http://export.arxiv.org/api/query"
    "?search_query=cat:{cat}"
    "&sortBy=submittedDate&sortOrder=descending"
    "&max_results={max_results}"
)

# 摘要截断长度（arXiv abstract 通常很长）
SUMMARY_MAX_LEN = 500


def parse_arxiv_feed(xml: str) -> list[dict]:
    """
    解析 arXiv Atom feed（纯函数，便于单测）
    Returns: [{"title", "summary", "authors", "url", "published"}]
    """
    soup = BeautifulSoup(xml, "xml")
    items: list[dict] = []

    for entry in soup.find_all("entry"):
        title_el = entry.find("title")
        title = " ".join(title_el.get_text(strip=True).split()) if title_el else ""
        if not title:
            continue

        summary_el = entry.find("summary")
        summary = ""
        if summary_el:
            summary = " ".join(summary_el.get_text(strip=True).split())
            if len(summary) > SUMMARY_MAX_LEN:
                summary = summary[:SUMMARY_MAX_LEN].rstrip() + "…"

        authors = [
            a.get_text(strip=True)
            for a in entry.find_all("name")
            if a.get_text(strip=True)
        ]

        # 摘要页链接：优先 <id>（形如 http://arxiv.org/abs/xxxx），退化到 link[rel=alternate]
        url = ""
        id_el = entry.find("id")
        if id_el and id_el.get_text(strip=True):
            url = id_el.get_text(strip=True)
        if not url:
            for link in entry.find_all("link"):
                if link.get("rel") == "alternate" and link.get("href"):
                    url = link.get("href")
                    break
        if not url:
            continue

        published_el = entry.find("published")
        published = published_el.get_text(strip=True) if published_el else ""

        items.append({
            "title": title,
            "summary": summary,
            "authors": authors,
            "url": url,
            "published": published,
        })

    return items


class ArxivSpider(SpiderBase):
    """
    arXiv 论文 Spider
    抓取 cs.AI / cs.CL 近期论文，写入 hot_news_raw
    """

    @property
    def name(self) -> str:
        return "Arxiv"

    @property
    def retry_delay(self) -> float:
        return 3.0

    async def do_fetch(self, fetcher: Fetcher, writer: Writer) -> SpiderResult:
        errors: list[str] = []
        total_fetched = 0
        total_written = 0

        cfg = SPIDERS.get("arxiv", {})
        categories: list[str] = cfg.get("categories", ARXIV_CATEGORIES)
        max_results: int = cfg.get("max_results", 50)

        for cat in categories:
            url = ARXIV_API_TMPL.format(cat=cat, max_results=max_results)
            resp = await fetcher.get(url)
            if not resp:
                errors.append(f"获取 {cat} 失败")
                await asyncio.sleep(self.retry_delay)
                continue

            papers = parse_arxiv_feed(resp.text)
            total_fetched += len(papers)
            logger.info(f"[Arxiv] {cat}: {len(papers)} 篇论文")

            total_written += self._write_news(writer, papers)

            await asyncio.sleep(3.0)  # arXiv 建议请求间隔 ≥3s

        return SpiderResult(
            spider_name=self.name,
            success=len(errors) == 0,
            items_fetched=total_fetched,
            items_written=total_written,
            errors=errors,
        )

    def _write_news(self, writer: Writer, papers: list[dict]) -> int:
        """写入 hot_news_raw（source='arxiv', is_ai_related=True，含 24h 去重）"""
        written = 0
        cutoff = (datetime.now(timezone.utc) - timedelta(hours=24)).isoformat()

        for p in papers:
            try:
                existing = writer.client.table("hot_news_raw").select(
                    "id", count="exact"
                ).match({
                    "title": p["title"],
                    "source": "arxiv",
                }).gte("fetched_at", cutoff).execute()

                if existing.count and existing.count > 0:
                    continue

                writer.client.table("hot_news_raw").insert({
                    "source": "arxiv",
                    "title": p["title"],
                    "url": p["url"],
                    "summary": p["summary"],
                    "author": ", ".join(p["authors"][:3]),
                    "score": 0,
                    "is_ai_related": True,
                }).execute()
                written += 1
            except Exception as e:
                logger.error(f"[Arxiv] 写入失败: {e}")

        return written
