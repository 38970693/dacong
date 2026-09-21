"""
Bluesky AI 动态 Spider

Bluesky 的公开只读端点 `public.api.bsky.app` **不需要任何 token**，且有完整的
点赞 / 转推 / 回复计数，是目前追踪 AI 从业者动态最省心的免费源
（X 的 Nitter 系镜像已于 2026-08 被 X Corp 关停）。

追踪范围 = 已验证账号时间线 + 关键词搜索。

⚠️ handle 不能靠猜：X 上的同名账号在 Bluesky 常被抢注成空号（例如 sama.bsky.social
是 0 帖子的假号）。默认只放已核实有真实内容的账号，其余走 `BSKY_KOL_ACCOUNTS` 配置。

数据写入 `hot_news_raw`，`source = 'Bluesky'`（与 X 一同在资讯流里优先展示）。
"""
import asyncio
import logging
from datetime import datetime, timezone
from typing import Optional

from config import SPIDERS
from core.base import SpiderBase
from core.fetcher import Fetcher
from core.writer import Writer
from models.metrics import HotNewsItem, SpiderResult

logger = logging.getLogger(__name__)

BSKY_PUBLIC_API = "https://public.api.bsky.app/xrpc"

# 已核实有真实内容的账号（可用 BSKY_KOL_ACCOUNTS 覆盖）
# 括号内为 2026-09-15 实测的 粉丝数/发帖数，凡 postsCount=0 的抢注空号一律不收
DEFAULT_KOL_ACCOUNTS = [
    "simonwillison.net",      # Simon Willison（50.0k / 4909）已认证
    "emollick.bsky.social",   # Ethan Mollick，Wharton（36.8k / 3154）已认证
    "karpathy.bsky.social",   # Andrej Karpathy（34.2k / 20）
    "natolambert.bsky.social",  # Nathan Lambert，Interconnects（14.5k / 2145）
    "thomwolf.bsky.social",   # Thomas Wolf，HuggingFace 联创（12.7k / 122）
    "rasbt.bsky.social",      # Sebastian Raschka（10.4k / 319）
    "drfeifei.bsky.social",   # 李飞飞（4.8k / 4）低频但确实是本人
    "hardmaru.bsky.social",   # David Ha，Sakana AI CEO（4.7k / 234）
    "sakanaai.bsky.social",   # Sakana AI 官方（1.6k / 470）
]

DEFAULT_KEYWORDS = ["LLM", "AI agent", "open source AI"]

MAX_RESULTS = 25
REQUEST_DELAY = 0.5


def post_url(post: dict, fallback_handle: str = "") -> str:
    """
    由 at:// _uri 拼出可点击的 bsky.app 链接
    at://did:plc:xxx/app.bsky.feed.post/3jwo...  →  https://bsky.app/profile/{handle}/post/{rkey}
    """
    uri = post.get("uri", "")
    rkey = uri.rsplit("/", 1)[-1] if uri else ""
    handle = (post.get("author") or {}).get("handle") or fallback_handle
    if not rkey or not handle:
        return ""
    return f"https://bsky.app/profile/{handle}/post/{rkey}"


def parse_feed(payload: dict) -> list[dict]:
    """解析 getAuthorFeed / searchPosts 的响应（两者结构一致）"""
    results: list[dict] = []

    for item in payload.get("feed", []) or []:
        post = item.get("post") or {}
        record = post.get("record") or {}
        text = (record.get("text") or "").strip()
        if not text:
            continue

        url = post_url(post)
        if not url:
            continue

        results.append({
            "title": text.split("\n")[0][:140],
            "summary": text[:500],
            "url": url,
            "author": (post.get("author") or {}).get("handle", ""),
            "score": int(post.get("likeCount", 0)) + int(post.get("repostCount", 0)),
            "published": record.get("createdAt") or post.get("indexedAt"),
        })

    return results


def to_utc(published: Optional[str]) -> datetime:
    """Bluesky 返回 2023-05-27T03:56:08.230Z 这类 ISO 串"""
    if not published:
        return datetime.now(timezone.utc)
    try:
        dt = datetime.fromisoformat(published.replace("Z", "+00:00"))
    except ValueError:
        return datetime.now(timezone.utc)

    return dt.astimezone(timezone.utc) if dt.tzinfo else dt.replace(tzinfo=timezone.utc)


class BlueskySpider(SpiderBase):
    """Bluesky 上 AI 相关动态：已验证账号 + 关键词搜索"""

    @property
    def name(self) -> str:
        return "Bluesky"

    @property
    def retry_delay(self) -> float:
        return 3.0

    def _cfg(self) -> dict:
        return SPIDERS.get("bluesky", {})

    def _accounts(self) -> list[str]:
        raw = self._cfg().get("kol_accounts", "")
        if raw:
            return [a.strip().lstrip("@") for a in raw.split(",") if a.strip()]
        return DEFAULT_KOL_ACCOUNTS

    def _keywords(self) -> list[str]:
        raw = self._cfg().get("keywords", "")
        if raw:
            return [k.strip() for k in raw.split(",") if k.strip()]
        return DEFAULT_KEYWORDS

    async def _get_json(self, fetcher: Fetcher, path: str, params: dict) -> Optional[dict]:
        query = "&".join(f"{k}={v}" for k, v in params.items())
        resp = await fetcher.get(f"{BSKY_PUBLIC_API}/{path}?{query}")
        if not resp or resp.status_code != 200:
            return None
        return resp.json()

    async def do_fetch(self, fetcher: Fetcher, writer: Writer) -> SpiderResult:
        errors: list[str] = []
        items: list[dict] = []

        for acc in self._accounts():
            payload = await self._get_json(
                fetcher,
                "app.bsky.feed.getAuthorFeed",
                {"actor": acc, "limit": MAX_RESULTS},
            )
            if payload is None:
                errors.append(f"Bluesky 获取 {acc} 时间线失败（账号可能不存在）")
            else:
                items.extend(parse_feed(payload))
            await asyncio.sleep(REQUEST_DELAY)

        for kw in self._keywords():
            payload = await self._get_json(
                fetcher,
                "app.bsky.feed.searchPosts",
                {"q": kw, "limit": MAX_RESULTS, "sort": "latest"},
            )
            if payload is None:
                errors.append(f"Bluesky 搜索 {kw} 失败")
            else:
                items.extend(parse_feed(payload))
            await asyncio.sleep(REQUEST_DELAY)

        written = 0
        seen: set[str] = set()

        for it in items:
            if not it["title"] or it["url"] in seen:
                continue
            seen.add(it["url"])

            news = HotNewsItem(
                source="Bluesky",
                title=it["title"],
                url=it["url"],
                summary=it["summary"],
                author=it["author"],
                score=it["score"],
                fetched_at=to_utc(it.get("published")),
            )
            if writer.upsert_hot_news(news):
                written += 1

        logger.info(f"[Bluesky] 抓取 {len(items)} 条，写入 {written} 条")

        return SpiderResult(
            spider_name=self.name,
            success=len(errors) == 0,
            items_fetched=len(items),
            items_written=written,
            errors=errors,
        )
