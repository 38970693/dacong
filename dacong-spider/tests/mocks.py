"""
测试替身 - Fetcher / Writer

新架构（SpiderBase.do_fetch(fetcher, writer)）下，爬虫不直接碰 HTTP 与数据库，
因此单测只需替换这两个协作者。

MockWriter 刻意复刻真实 Writer 的「24h 去重」语义：相同业务键第二次写入返回 False。
这样去重相关的断言在测试里依然成立，不会因为换了写入器而失真。
"""
import json
from typing import Optional


class FakeResponse:
    """最小化的 httpx.Response 替身，提供爬虫用到的 .text / .status_code / .json()"""

    def __init__(self, text: str, status_code: int = 200):
        self.text = text
        self.status_code = status_code

    def json(self):
        return json.loads(self.text)


class MockFetcher:
    """按 URL 返回预设页面；未命中返回 default，default 为 None 即模拟请求失败"""

    def __init__(self, pages: Optional[dict] = None, default: Optional[FakeResponse] = None):
        self.pages = pages or {}
        self.default = default
        self.requested: list[str] = []

    async def get(self, url: str, retries: int = 3) -> Optional[FakeResponse]:
        self.requested.append(url)
        return self.pages.get(url, self.default)

    async def close(self) -> None:
        pass


class MockWriter:
    """内存写入器，记录写入内容并模拟 24h 去重"""

    def __init__(self):
        self.models: dict[str, dict] = {}
        self.model_metrics: list = []
        self.repo_metrics: list = []
        self.hot_news: list = []
        self._seen_metrics: set = set()
        self._seen_repos: set = set()
        self._seen_news: set = set()

    def upsert_model(self, name: str, vendor: str, category: str,
                     description: str = "", website_url: str = "",
                     tags: Optional[list] = None) -> str:
        model_id = f"{vendor}::{name}"
        self.models[model_id] = {
            "name": name,
            "vendor": vendor,
            "category": category,
            "description": description,
            "website_url": website_url,
            "tags": tags or [],
        }
        return model_id

    def upsert_model_metrics(self, metric) -> bool:
        key = (metric.model_id, metric.source, metric.metric_type)
        if key in self._seen_metrics:
            return False
        self._seen_metrics.add(key)
        self.model_metrics.append(metric)
        return True

    def upsert_repository_metrics(self, repo) -> bool:
        if repo.full_name in self._seen_repos:
            return False
        self._seen_repos.add(repo.full_name)
        self.repo_metrics.append(repo)
        return True

    def upsert_hot_news(self, news) -> bool:
        if news.url in self._seen_news:
            return False
        self._seen_news.add(news.url)
        self.hot_news.append(news)
        return True
