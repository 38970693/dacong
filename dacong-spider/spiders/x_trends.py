"""
X (Twitter) AI 动态 Spider —— 可插拔双通道

本爬虫是**唯一需要付费**的数据源，因此默认不产生任何流量：

1. **官方 API v2**：配置了 `X_BEARER_TOKEN` 时启用，数据完整、能拿到点赞/转推数
2. **免费镜像（Nitter 系）**：仅当显式配置了 `X_MIRRORS` 时才启用。Nitter 与 xcancel
   已于 2026-08-24 被 X Corp 一纸律师函关停，公共镜像基本全灭，所以默认是空的
3. **都不配 → 直接跳过**（success=True、0 条），不再浪费调度周期去撞死掉的域名

免费社交源请走 `spiders/bluesky.py`（公开 API，无需 token）。

追踪范围 = KOL 账号时间线 + 关键词搜索（关键词作为兜底，覆盖没进列表的新账号）。

数据写入 `hot_news_raw`，`source = 'X'`（前端据此把 X 排到最前）。
"""
import asyncio
import logging
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
from typing import Optional

import httpx

from config import SPIDERS, REQUEST_TIMEOUT, USER_AGENT
from core.base import SpiderBase
from core.fetcher import Fetcher
from core.writer import Writer
from models.metrics import HotNewsItem, SpiderResult
from spiders.ai_news_rss import parse_rss_feed

logger = logging.getLogger(__name__)

# AI 领域活跃的账号（可用 X_KOL_ACCOUNTS 覆盖）
DEFAULT_KOL_ACCOUNTS = [
    "thsottiaux",      # Tibo (Thibault Sottiaux)，OpenAI Codex & ChatGPT 产品负责人（67.8w 粉 / 2951 帖）
    "karpathy",        # Andrej Karpathy
    "sama",            # Sam Altman
    "ylecun",          # Yann LeCun
    "AndrewYNg",       # 吴恩达
    "drfeifei",        # 李飞飞
    "jimfan",          # Jim Fan (NVIDIA)
    "demishassabis",   # Demis Hassabis (DeepMind)
    "hardmaru",        # David Ha
    "_jasonwei",       # Jason Wei
    "bindureddy",      # Bindu Reddy
]

# 关键词兜底（可用 X_KEYWORDS 覆盖）
DEFAULT_KEYWORDS = ["AI", "LLM", "GPT"]

X_API_SEARCH = "https://api.twitter.com/2/tweets/search/recent"

# 单账号/关键词最多取多少条
MAX_RESULTS = 20
# 镜像之间的请求间隔（秒），避免打得太急
MIRROR_DELAY = 1.0


def build_search_query(account: str) -> str:
    """KOL 时间线查询：排除转推与回复，只要原创推文"""
    return f"from:{account} -is:retweet -is:reply"


def build_keyword_query(keyword: str) -> str:
    """关键词查询：排除转推，限制英文减少噪音"""
    return f"{keyword} -is:retweet lang:en"


def parse_api_payload(payload: dict, author: str = "") -> list[dict]:
    """
    解析 X API v2 的 search/recent 响应。
    推文没有标题，取首行作为 title，全文作为 summary。
    """
    results: list[dict] = []

    for tweet in payload.get("data", []) or []:
        text = (tweet.get("text") or "").strip()
        if not text:
            continue

        metrics = tweet.get("public_metrics") or {}
        score = int(metrics.get("like_count", 0)) + int(metrics.get("retweet_count", 0))

        results.append({
            "title": text.split("\n")[0][:140],
            "summary": text[:500],
            "url": f"https://x.com/i/status/{tweet.get('id')}",
            "author": author,
            "score": score,
            "published": tweet.get("created_at"),
        })

    return results


def parse_mirror_rss(xml: str, author: str = "") -> list[dict]:
    """解析 Nitter 镜像的 RSS（结构与标准 RSS 2.0 一致，复用 ai_news_rss 的解析器）"""
    items = parse_rss_feed(xml)
    results: list[dict] = []

    for it in items:
        results.append({
            "title": it["title"],
            "summary": it.get("summary", ""),
            "url": it["url"],
            "author": author or it.get("author", ""),
            "score": 0,  # 镜像 RSS 不提供互动数
            "published": it.get("published"),
        })

    return results


def to_utc(published: Optional[str]) -> datetime:
    """把 RSS / API 的时间串转成 UTC；解析不了就用当前时间"""
    if not published:
        return datetime.now(timezone.utc)
    try:
        # API: 2024-01-01T00:00:00.000Z / RSS: Mon, 01 Jan 2024 00:00:00 GMT
        cleaned = published.replace("Z", "+00:00")
        dt = datetime.fromisoformat(cleaned)
    except ValueError:
        try:
            # RSS 的时区是**字面量**（GMT / UT / EST…），而 `%z` 只吃 +0000 这类
            # 数字偏移，所以原来那句 strptime(..., "%z") 对最常见的
            # `Mon, 01 Jan 2024 00:00:00 GMT` 一律抛 ValueError，
            # 再被静默兜底成「现在」——镜像通道抓到的每条都会拿到错误的发布时间。
            # parsedate_to_datetime 是 stdlib 里专门处理 RFC 822 日期的正解。
            dt = parsedate_to_datetime(published)
        except (TypeError, ValueError):
            return datetime.now(timezone.utc)

    return dt.astimezone(timezone.utc) if dt.tzinfo else dt.replace(tzinfo=timezone.utc)


class XTrendsSpider(SpiderBase):
    """X 上 AI 相关动态：KOL 时间线 + 关键词搜索"""

    @property
    def name(self) -> str:
        return "X Trends"

    @property
    def retry_delay(self) -> float:
        return 3.0

    # ── 配置读取（环境变量可覆盖）──────────────────
    def _cfg(self) -> dict:
        return SPIDERS.get("x", {})

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

    def _mirrors(self) -> list[str]:
        raw = self._cfg().get("mirrors", "")
        return [m.strip().rstrip("/") for m in raw.split(",") if m.strip()]

    # ── 通道一：官方 API ──────────────────────────
    async def _fetch_via_api(self, token: str) -> tuple[list[dict], list[str]]:
        headers = {
            "Authorization": f"Bearer {token}",
            "User-Agent": USER_AGENT,
        }

        queries: list[tuple[str, str]] = []
        for acc in self._accounts():
            queries.append((build_search_query(acc), acc))
        for kw in self._keywords():
            queries.append((build_keyword_query(kw), ""))

        items: list[dict] = []
        errors: list[str] = []

        async with httpx.AsyncClient(
            timeout=httpx.Timeout(REQUEST_TIMEOUT), headers=headers
        ) as client:
            for query, author in queries:
                try:
                    resp = await client.get(
                        X_API_SEARCH,
                        params={
                            "query": query,
                            "max_results": MAX_RESULTS,
                            "tweet.fields": "created_at,public_metrics,lang",
                        },
                    )
                except httpx.HTTPError as e:
                    errors.append(f"X API 请求失败 [{query}]: {e}")
                    continue

                if resp.status_code == 429:
                    errors.append("X API 触发限流，停止本轮")
                    break
                if resp.status_code != 200:
                    errors.append(f"X API HTTP {resp.status_code} [{query}]")
                    continue

                items.extend(parse_api_payload(resp.json(), author))
                await asyncio.sleep(0.2)

        return items, errors

    # ── 通道二：免费镜像 ──────────────────────────
    async def _fetch_via_mirror(self, fetcher: Fetcher) -> tuple[list[dict], list[str]]:
        mirrors = self._mirrors()
        if not mirrors:
            return [], ["未配置 Nitter 镜像且无 X_BEARER_TOKEN，无法抓取"]

        items: list[dict] = []
        errors: list[str] = []
        working: Optional[str] = None

        # 先探活，确定一个可用镜像，避免每个账号都试一遍全部域名
        for mirror in mirrors:
            probe = await fetcher.get(f"https://{mirror}/karpathy/rss")
            if probe and probe.status_code == 200 and probe.text:
                working = mirror
                break

        if not working:
            return [], [f"所有 Nitter 镜像均不可用: {', '.join(mirrors)}"]

        logger.info(f"[X] 使用镜像 {working}")

        for acc in self._accounts():
            resp = await fetcher.get(f"https://{working}/{acc}/rss")
            if resp and resp.status_code == 200:
                items.extend(parse_mirror_rss(resp.text, acc))
            else:
                errors.append(f"镜像抓取 {acc} 失败")
            await asyncio.sleep(MIRROR_DELAY)

        for kw in self._keywords():
            resp = await fetcher.get(
                f"https://{working}/search/rss?f=tweets&q={kw}"
            )
            if resp and resp.status_code == 200:
                items.extend(parse_mirror_rss(resp.text))
            else:
                errors.append(f"镜像搜索 {kw} 失败")
            await asyncio.sleep(MIRROR_DELAY)

        return items, errors

    # ── 主流程 ───────────────────────────────────
    async def do_fetch(self, fetcher: Fetcher, writer: Writer) -> SpiderResult:
        token = self._cfg().get("bearer_token", "")

        if token:
            logger.info("[X] 使用官方 API v2 通道")
            items, errors = await self._fetch_via_api(token)
        elif self._mirrors():
            logger.info("[X] 未配置 X_BEARER_TOKEN，使用免费镜像通道")
            items, errors = await self._fetch_via_mirror(fetcher)
        else:
            # 免费优先策略：没有付费 token 就不折腾，直接跳过
            logger.warning(
                "[X] 既无 X_BEARER_TOKEN 也未配置 X_MIRRORS → 跳过本轮"
                "（Nitter 镜像已于 2026-08 关停；免费社交源请用 bluesky 爬虫）"
            )
            return SpiderResult(
                spider_name=self.name,
                success=True,
                items_fetched=0,
                items_written=0,
            )

        written = 0
        seen: set[str] = set()

        for it in items:
            if not it["title"] or not it["url"]:
                continue
            if it["url"] in seen:
                continue
            seen.add(it["url"])

            news = HotNewsItem(
                source="X",
                title=it["title"],
                url=it["url"],
                summary=it["summary"],
                author=it["author"],
                score=it["score"],
                fetched_at=to_utc(it.get("published")),
            )
            if writer.upsert_hot_news(news):
                written += 1

        logger.info(f"[X] 抓取 {len(items)} 条，写入 {written} 条")

        return SpiderResult(
            spider_name=self.name,
            success=len(errors) == 0,
            items_fetched=len(items),
            items_written=written,
            errors=errors,
        )
