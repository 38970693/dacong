from spiders.ai_news_rss import AINewsRssSpider
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
