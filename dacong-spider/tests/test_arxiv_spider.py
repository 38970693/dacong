"""
单元测试 - arXiv / AI RSS 解析纯函数

只测试解析逻辑（parse_arxiv_feed / parse_rss_feed），
写入逻辑依赖 Supabase 客户端，由人工/集成测试覆盖。
"""
import pytest

from spiders.arxiv_spider import parse_arxiv_feed
from spiders.ai_news_rss import parse_rss_feed


# ══════════════════════════════════════════════════════════
# parse_arxiv_feed
# ══════════════════════════════════════════════════════════

SAMPLE_ARXIV_XML = """<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <entry>
    <id>http://arxiv.org/abs/2401.00001v1</id>
    <title>  Attention Is   All You Need Again  </title>
    <summary>  We propose a new   transformer architecture.  </summary>
    <published>2024-01-01T00:00:00Z</published>
    <author><name>Jane Doe</name></author>
    <author><name>John Smith</name></author>
  </entry>
  <entry>
    <id>http://arxiv.org/abs/2401.00002v1</id>
    <title>Another Paper</title>
    <summary>Abstract text.</summary>
    <published>2024-01-02T00:00:00Z</published>
    <author><name>Alice</name></author>
  </entry>
</feed>
"""


def test_parse_arxiv_feed_count():
    items = parse_arxiv_feed(SAMPLE_ARXIV_XML)
    assert len(items) == 2


def test_parse_arxiv_feed_fields():
    items = parse_arxiv_feed(SAMPLE_ARXIV_XML)
    first = items[0]
    assert first["title"] == "Attention Is All You Need Again"
    assert first["summary"] == "We propose a new transformer architecture."
    assert first["authors"] == ["Jane Doe", "John Smith"]
    assert first["url"] == "http://arxiv.org/abs/2401.00001v1"
    assert first["published"] == "2024-01-01T00:00:00Z"


def test_parse_arxiv_feed_whitespace_collapsed():
    items = parse_arxiv_feed(SAMPLE_ARXIV_XML)
    # 多空格被合并为单空格，首尾空白去除
    assert "  " not in items[0]["title"]
    assert items[0]["title"] == items[0]["title"].strip()


def test_parse_arxiv_feed_empty():
    assert parse_arxiv_feed("<feed xmlns='http://www.w3.org/2005/Atom'></feed>") == []


def test_parse_arxiv_feed_invalid_xml_returns_empty():
    # 非法 XML 不应抛异常，返回空列表
    assert parse_arxiv_feed("not xml at all") == []


# ══════════════════════════════════════════════════════════
# parse_rss_feed
# ══════════════════════════════════════════════════════════

SAMPLE_RSS_XML = """<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <item>
      <title>  Tech   News Today  </title>
      <link>https://example.com/1</link>
      <description>  Some   description here.  </description>
      <pubDate>Mon, 01 Jan 2024 00:00:00 GMT</pubDate>
    </item>
  </channel>
</rss>
"""


def test_parse_rss_feed_count():
    items = parse_rss_feed(SAMPLE_RSS_XML)
    assert len(items) == 1


def test_parse_rss_feed_fields():
    items = parse_rss_feed(SAMPLE_RSS_XML)
    it = items[0]
    assert it["title"] == "Tech News Today"
    assert it["summary"] == "Some description here."
    assert it["url"] == "https://example.com/1"
    assert it["published"] == "Mon, 01 Jan 2024 00:00:00 GMT"


def test_parse_rss_feed_empty():
    assert parse_rss_feed("<rss version='2.0'><channel></channel></rss>") == []
