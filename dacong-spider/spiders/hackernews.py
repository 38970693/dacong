"""
HackerNews Spider
策略：解析 https://news.ycombinator.com 列表页
只抓取 AI 相关帖子（标题含关键词）
"""
import asyncio
import logging
import re
from datetime import datetime, timezone

from bs4 import BeautifulSoup

from config import SPIDERS
from core.base import SpiderBase
from core.fetcher import Fetcher
from core.writer import Writer
from models.metrics import HotNewsItem, SpiderResult

logger = logging.getLogger(__name__)

# AI 相关关键词
AI_KEYWORDS = [
    "AI", "LLM", "GPT", "Claude", "Gemini", "Mistral", "OpenAI",
    "Anthropic", "language model", "neural", "diffusion",
    "stable diffusion", "RAG", "embedding", "fine-tuning",
    "ChatGPT", "artificial intelligence", "hugging face",
    "machine learning", "deep learning", "transformer",
    "Stable Diffusion", "Midjourney", "Sora", "Llama",
    "LangChain", "vector database", "embedding model",
    "文心", "通义", "智谱", "盘古", "混元",
]


class HackerNewsSpider(SpiderBase):
    """
    HackerNews AI 资讯 Spider
    抓取 HN 首页 + Ask HN + Show HN，过滤 AI 相关帖子
    """

    @property
    def name(self) -> str:
        return "HackerNews"

    @property
    def retry_delay(self) -> float:
        return 2.0

    def _is_ai_related(self, title: str) -> bool:
        """判断标题是否 AI 相关"""
        title_lower = title.lower()
        return any(kw.lower() in title_lower for kw in AI_KEYWORDS)

    def _parse_page(self, html: str) -> list[dict]:
        """
        解析 HN 列表页 HTML
        Returns: [{"title", "url", "score", "author", "hn_id", "comments"}]
        """
        soup = BeautifulSoup(html, "lxml")
        items: list[dict] = []

        # HN 的结构：tr.athing 是标题行，后续 tr 是分数/作者行
        rows = soup.select("tr.athing")
        for row in rows:
            # 标题行
            titleline = row.select_one("span.titleline")
            if not titleline:
                continue

            a_tag = titleline.select_one("a")
            if not a_tag:
                continue

            title: str = a_tag.get_text(strip=True)
            url: str = a_tag.get("href", "")

            # 跳过外部链接为空的情况
            if not url:
                continue

            # 获取 HN ID（用于构建评论链接）
            story_id: str = row.get("id", "")
            if story_id.isdigit():
                hn_id = int(story_id)
            else:
                hn_id = 0

            # 分数（在下一行）
            subtext = row.find_next_sibling("tr")
            score_el = subtext.select_one("span.score") if subtext else None
            score = 0
            if score_el:
                try:
                    score = int(re.sub(r"[^\d]", "", score_el.get_text(strip=True)))
                except ValueError:
                    score = 0

            # 作者
            author_el = subtext.select_one("a.hnuser") if subtext else None
            author: str = author_el.get_text(strip=True) if author_el else ""

            # 评论数
            comments_el = subtext.select_one("a[href^='item?id=']") if subtext else None
            comments = 0
            if comments_el:
                try:
                    comments = int(re.sub(r"[^\d]", "", comments_el.get_text(strip=True)))
                except ValueError:
                    comments = 0

            items.append({
                "title": title,
                "url": url,
                "score": score,
                "author": author,
                "hn_id": hn_id,
                "comments": comments,
            })

        return items

    async def do_fetch(self, fetcher: Fetcher, writer: Writer) -> SpiderResult:
        """
        执行 HackerNews 爬取
        页面：首页 + Ask HN + Show HN
        """
        errors: list[str] = []
        total_fetched = 0
        total_written = 0

        pages = [
            ("HN-Main", "https://news.ycombinator.com"),
            ("HN-Ask",  "https://news.ycombinator.com/ask"),
            ("HN-Show", "https://news.ycombinator.com/show"),
        ]

        # 从配置读取要抓取的页面
        cfg_pages = SPIDERS.get("hackernews", {}).get("pages", None)
        if cfg_pages:
            pages = [(p["label"], p["url"]) for p in cfg_pages]

        for label, url in pages:
            resp = await fetcher.get(url)
            if not resp:
                errors.append(f"获取 {label} 失败")
                await asyncio.sleep(self.retry_delay)
                continue

            all_stories = self._parse_page(resp.text)

            # AI 过滤
            ai_stories = [s for s in all_stories if self._is_ai_related(s["title"])]

            total_fetched += len(ai_stories)
            logger.info(
                f"[HackerNews] {label}: "
                f"全量 {len(all_stories)} 条，AI相关 {len(ai_stories)} 条"
            )

            # 写入
            written = await self._write_news(writer, ai_stories)
            total_written += written

            await asyncio.sleep(1.0)

        return SpiderResult(
            spider_name=self.name,
            success=len(errors) == 0,
            items_fetched=total_fetched,
            items_written=total_written,
            errors=errors,
        )

    async def _write_news(self, writer: Writer, stories: list[dict]) -> int:
        """将新闻条目写入 hot_news_raw"""
        written = 0
        for story in stories:
            news = HotNewsItem(
                source="HN",
                title=story["title"],
                url=story["url"],
                summary="",       # HN 无摘要字段
                author=story["author"],
                score=story["score"],
            )
            if writer.upsert_hot_news(news):
                written += 1
        return written
