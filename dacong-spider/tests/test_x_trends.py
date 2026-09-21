"""
单元测试 - X (Twitter) 动态爬虫

覆盖两条通道的纯逻辑：
  - 官方 API：查询构造 + 响应解析
  - 免费镜像：RSS 解析 + do_fetch 编排（镜像探活、写入 source='X'）
真实网络调用不进入单测（API 走 mock payload，镜像走 MockFetcher）。
"""
from datetime import datetime, timezone

import pytest

from spiders.x_trends import (
    DEFAULT_KOL_ACCOUNTS,
    XTrendsSpider,
    build_keyword_query,
    build_search_query,
    parse_api_payload,
    parse_mirror_rss,
    to_utc,
)
from tests.mocks import FakeResponse, MockFetcher, MockWriter


SAMPLE_RSS = """<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>karpathy</title>
    <item>
      <title>AI agents are finally working</title>
      <link>https://x.com/karpathy/status/1234567890</link>
      <description>Some thoughts on agents</description>
      <pubDate>Mon, 15 Sep 2026 10:00:00 GMT</pubDate>
    </item>
  </channel>
</rss>
"""

MIRROR_CFG = {
    "x": {
        "bearer_token": "",
        "kol_accounts": "karpathy",
        "keywords": "AI",
        "mirrors": "xcancel.com",
    }
}


# ══════════════════════════════════════════════════════════
# 查询构造
# ══════════════════════════════════════════════════════════

def test_build_search_query_excludes_noise():
    """KOL 时间线只要原创推文，排除转推与回复"""
    assert build_search_query("karpathy") == "from:karpathy -is:retweet -is:reply"


def test_build_keyword_query_limits_language():
    assert build_keyword_query("LLM") == "LLM -is:retweet lang:en"


def test_default_kol_accounts_not_empty():
    assert len(DEFAULT_KOL_ACCOUNTS) > 0


# ══════════════════════════════════════════════════════════
# 官方 API 解析
# ══════════════════════════════════════════════════════════

def test_parse_api_payload_basic():
    payload = {
        "data": [{
            "id": "123",
            "text": "Hello AI\nsecond line",
            "created_at": "2026-09-15T00:00:00.000Z",
            "public_metrics": {"like_count": 10, "retweet_count": 5},
        }]
    }

    items = parse_api_payload(payload, "karpathy")

    assert len(items) == 1
    it = items[0]
    assert it["title"] == "Hello AI"          # 推文无标题，取首行
    assert it["url"] == "https://x.com/i/status/123"
    assert it["score"] == 15                   # 点赞 + 转推
    assert it["author"] == "karpathy"


def test_parse_api_payload_missing_metrics_is_zero():
    payload = {"data": [{"id": "1", "text": "hi"}]}
    assert parse_api_payload(payload)[0]["score"] == 0


def test_parse_api_payload_empty():
    assert parse_api_payload({"data": []}) == []
    assert parse_api_payload({}) == []


def test_parse_api_payload_skips_blank_text():
    payload = {"data": [{"id": "1", "text": "   "}]}
    assert parse_api_payload(payload) == []


# ══════════════════════════════════════════════════════════
# 时间解析
# ══════════════════════════════════════════════════════════

def test_to_utc_api_format():
    dt = to_utc("2026-09-15T00:00:00.000Z")
    assert dt.year == 2026 and dt.month == 9


def test_to_utc_rss_format():
    # 断言到具体时刻而不是只查 day：原来只查 `day == 15`，而兜底路径返回的是
    # 「现在」——只要当天正好是 15 号，一个把 GMT 判成解析失败的实现也能蒙混过关。
    # 这几种写法都是 RSS 里真实存在的，`%z` 对它们全部失败（只吃 +0000）。
    expected = datetime(2026, 9, 15, 10, 0, tzinfo=timezone.utc)
    for published in (
        "Mon, 15 Sep 2026 10:00:00 GMT",   # 最常见
        "Mon, 15 Sep 2026 10:00:00 UT",
        "Mon, 15 Sep 2026 10:00:00 +0000",
        "15 Sep 2026 10:00:00 GMT",        # 无星期几
    ):
        assert to_utc(published) == expected, published


def test_to_utc_invalid_falls_back_to_now():
    assert to_utc("not-a-date").tzinfo is not None


# ══════════════════════════════════════════════════════════
# 镜像通道
# ══════════════════════════════════════════════════════════

def test_parse_mirror_rss():
    items = parse_mirror_rss(SAMPLE_RSS, "karpathy")

    assert len(items) == 1
    assert items[0]["title"] == "AI agents are finally working"
    assert items[0]["url"] == "https://x.com/karpathy/status/1234567890"
    assert items[0]["author"] == "karpathy"
    assert items[0]["score"] == 0  # 镜像 RSS 无互动数


async def test_do_fetch_via_mirror_writes_x_source(monkeypatch):
    """镜像可用时：抓取 KOL + 关键词，写入 hot_news_raw 且 source 为 X"""
    monkeypatch.setattr("spiders.x_trends.SPIDERS", MIRROR_CFG)

    spider = XTrendsSpider()
    writer = MockWriter()
    fetcher = MockFetcher(default=FakeResponse(SAMPLE_RSS))

    result = await spider.do_fetch(fetcher, writer)

    assert result.success is True
    assert result.items_written >= 1
    assert all(n.source == "X" for n in writer.hot_news)
    # 探活 + KOL + 关键词，共 3 次请求
    assert len(fetcher.requested) == 3


async def test_do_fetch_deduplicates_by_url(monkeypatch):
    """同一条推文在 KOL 与关键词结果中重复出现时只写一次"""
    monkeypatch.setattr("spiders.x_trends.SPIDERS", MIRROR_CFG)

    writer = MockWriter()
    await XTrendsSpider().do_fetch(MockFetcher(default=FakeResponse(SAMPLE_RSS)), writer)

    urls = [n.url for n in writer.hot_news]
    assert len(urls) == len(set(urls))


async def test_do_fetch_all_mirrors_down_reports_error(monkeypatch):
    """镜像全挂：不抛异常，错误信息进 errors"""
    monkeypatch.setattr("spiders.x_trends.SPIDERS", MIRROR_CFG)

    result = await XTrendsSpider().do_fetch(MockFetcher(default=None), MockWriter())

    assert result.success is False
    assert result.items_written == 0
    assert any("镜像" in e for e in result.errors)


async def test_do_fetch_no_token_no_mirror_skips(monkeypatch):
    """免费优先：既无 token 又无镜像时跳过，且不报错污染调度日志"""
    monkeypatch.setattr(
        "spiders.x_trends.SPIDERS",
        {"x": {"bearer_token": "", "kol_accounts": "", "keywords": "", "mirrors": ""}},
    )

    result = await XTrendsSpider().do_fetch(MockFetcher(default=None), MockWriter())

    assert result.success is True
    assert result.items_fetched == 0
    assert result.errors == []


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
