from spiders.ai_news_rss import AINewsRssSpider, parse_rss_feed
from tests.mocks import MockWriter


def test_write_news_preserves_feed_label():
    writer = MockWriter()
    entries = [{
        "title": "A new AI model",
        "url": "https://example.com/model",
        "summary": "Release notes",
        "published": "",
    }]

    written = AINewsRssSpider()._write_news(writer, entries, "OpenAI")

    assert written == 1
    assert writer.hot_news[0].source == "OpenAI"


def test_rss_publication_date_is_preserved_separately_from_collection():
    writer = MockWriter()
    AINewsRssSpider()._write_news(writer, [{"title": "AI release", "url": "https://example.com/ai",
        "summary": "Release", "published": "Tue, 29 Sep 2026 12:00:00 GMT"}], "OpenAI")
    news = writer.hot_news[0]
    assert news.source_published_at.isoformat() == "2026-09-29T12:00:00+00:00"
    assert news.to_dict()["source_published_at"] == "2026-09-29T12:00:00+00:00"


def test_atom_links_html_summary_and_invalid_dates():
    xml = '''<feed xmlns="http://www.w3.org/2005/Atom"><entry><title>AI tools</title>
      <link rel="self" href="https://example.com/feed"/><link rel="alternate" href="https://example.com/news"/>
      <summary type="html">&lt;p&gt;New &lt;b&gt;AI&lt;/b&gt; tools&lt;/p&gt;</summary>
      <published>2026-09-29T12:00:00Z</published></entry></feed>'''
    entry = parse_rss_feed(xml)[0]
    assert entry["url"] == "https://example.com/news"
    assert entry["summary"] == "New AI tools"
    writer = MockWriter()
    AINewsRssSpider()._write_news(writer, [{**entry, "published": "not a date"}], "HuggingFace")
    assert writer.hot_news[0].source_published_at is None
