"""
单元测试 - Bluesky AI 动态爬虫

使用 Bluesky 公开 API 的真实响应结构（public.api.bsky.app 无需 token）：
  - app.bsky.feed.getAuthorFeed → 账号时间线
  - app.bsky.feed.searchPosts   → 关键词搜索
两者返回结构一致，都由 parse_feed 解析。
"""
import json

import pytest

from spiders.bluesky import (
    BlueskySpider,
    DEFAULT_KOL_ACCOUNTS,
    parse_feed,
    post_url,
    to_utc,
)
from tests.mocks import FakeResponse, MockFetcher, MockWriter


def make_payload(text: str = "AI agents are working now", like: int = 230, repost: int = 5) -> str:
    return json.dumps({
        "feed": [{
            "post": {
                "uri": "at://did:plc:j7gi6r4kh6uof7rfrqpm3fej/app.bsky.feed.post/3jwoneqcave2h",
                "author": {"handle": "karpathy.bsky.social", "displayName": "karpathy"},
                "record": {
                    "$type": "app.bsky.feed.post",
                    "createdAt": "2026-09-15T01:23:45.678Z",
                    "text": text,
                },
                "likeCount": like,
                "repostCount": repost,
                "replyCount": 21,
                "indexedAt": "2026-09-15T01:23:45.678Z",
            }
        }],
        "cursor": "2026-09-15T01:23:45.678Z",
    })


BSKY_CFG = {
    "bluesky": {
        "enabled": True,
        "kol_accounts": "karpathy.bsky.social",
        "keywords": "AI",
    }
}


# ══════════════════════════════════════════════════════════
# 链接构造与解析
# ══════════════════════════════════════════════════════════

def test_post_url_from_at_uri():
    post = {
        "uri": "at://did:plc:abc/app.bsky.feed.post/3jwo123",
        "author": {"handle": "karpathy.bsky.social"},
    }
    assert post_url(post) == "https://bsky.app/profile/karpathy.bsky.social/post/3jwo123"


def test_post_url_missing_parts_returns_empty():
    assert post_url({"uri": ""}) == ""
    assert post_url({}) == ""


def test_parse_feed_basic():
    items = parse_feed(json.loads(make_payload("Hello AI\nsecond line")))

    assert len(items) == 1
    it = items[0]
    assert it["title"] == "Hello AI"
    assert it["url"] == "https://bsky.app/profile/karpathy.bsky.social/post/3jwoneqcave2h"
    assert it["author"] == "karpathy.bsky.social"
    assert it["score"] == 235  # 点赞 230 + 转推 5


def test_parse_feed_empty():
    assert parse_feed({"feed": []}) == []
    assert parse_feed({}) == []


def test_parse_feed_skips_blank_text():
    assert parse_feed(json.loads(make_payload("   "))) == []


def test_to_utc_iso_format():
    dt = to_utc("2026-09-15T01:23:45.678Z")
    assert dt.year == 2026 and dt.hour == 1


def test_to_utc_invalid_falls_back_to_now():
    assert to_utc("nonsense").tzinfo is not None


def test_default_accounts_only_verified():
    """默认列表只放已核实有真实内容的账号，避免抓到抢注的空号"""
    assert "karpathy.bsky.social" in DEFAULT_KOL_ACCOUNTS


# ══════════════════════════════════════════════════════════
# 抓取流程
# ══════════════════════════════════════════════════════════

async def test_do_fetch_writes_bluesky_source(monkeypatch):
    monkeypatch.setattr("spiders.bluesky.SPIDERS", BSKY_CFG)

    writer = MockWriter()
    fetcher = MockFetcher(default=FakeResponse(make_payload()))

    result = await BlueskySpider().do_fetch(fetcher, writer)

    assert result.success is True
    assert result.items_written == 1
    assert writer.hot_news[0].source == "Bluesky"
    assert writer.hot_news[0].score == 235
    # 账号时间线 + 关键词搜索各一次
    assert len(fetcher.requested) == 2


async def test_do_fetch_deduplicates_same_post(monkeypatch):
    """同一条帖同时命中账号时间线与关键词搜索时只写一次"""
    monkeypatch.setattr("spiders.bluesky.SPIDERS", BSKY_CFG)

    writer = MockWriter()
    await BlueskySpider().do_fetch(MockFetcher(default=FakeResponse(make_payload())), writer)

    assert len(writer.hot_news) == 1


async def test_do_fetch_bad_account_reports_error(monkeypatch):
    """账号不存在（HTTP 404）时不抛异常，记入 errors 并继续"""
    monkeypatch.setattr("spiders.bluesky.SPIDERS", BSKY_CFG)

    result = await BlueskySpider().do_fetch(
        MockFetcher(default=FakeResponse("not found", status_code=404)),
        MockWriter(),
    )

    assert result.success is False
    assert result.items_written == 0
    assert any("时间线失败" in e for e in result.errors)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
