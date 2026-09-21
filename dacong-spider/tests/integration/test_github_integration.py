"""
GitHub 爬虫集成测试（registry 新架构）

与单元测试的区别：这里用**真实的 Fetcher** 打 github.com/trending，
验证「真实页面结构 → 解析 → 写入」整条链路没有断。写入侧仍用 MockWriter，
避免污染数据库。

真实网络测试默认跳过，需要显式开启：
    TEST_USE_REAL_API=true  pytest tests/integration -m integration
数据库测试另需：
    TEST_USE_REAL_DB=true
"""
import os

import pytest

from core.fetcher import Fetcher
from core.writer import Writer
from spiders.github_trending import GitHubTrendingSpider
from tests.mocks import MockFetcher, MockWriter


USE_REAL_API = os.getenv("TEST_USE_REAL_API", "false").lower() == "true"
USE_REAL_DB = os.getenv("TEST_USE_REAL_DB", "false").lower() == "true"

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(
        not USE_REAL_API,
        reason="需要真实网络，设置 TEST_USE_REAL_API=true 开启",
    ),
]


@pytest.fixture
def github_spider(monkeypatch) -> GitHubTrendingSpider:
    """只爬首页，不爬 6 个语言子页（避免 9 秒以上的礼貌 sleep）"""

    async def _no_enrich(self, repos, cache):
        return None

    monkeypatch.setattr(GitHubTrendingSpider, "languages", property(lambda self: []))
    monkeypatch.setattr(GitHubTrendingSpider, "_enrich_total_stars", _no_enrich)
    return GitHubTrendingSpider()


async def test_github_spider_full_flow(github_spider):
    """真实页面 → 解析 → 写入，数据字段合法"""
    fetcher = Fetcher()
    writer = MockWriter()

    try:
        result = await github_spider.do_fetch(fetcher, writer)
    finally:
        await fetcher.close()

    assert result.success is True, f"爬取失败: {result.errors}"
    assert result.items_fetched > 0, "未抓取到任何数据"
    assert len(writer.repo_metrics) > 0, "未写入任何仓库"

    for repo in writer.repo_metrics:
        assert "/" in repo.full_name, "full_name 必须是 owner/repo"
        assert repo.url.startswith("https://github.com/"), "URL 格式错误"
        assert isinstance(repo.total_stars, int)

    print(f"\n抓取 {result.items_fetched} 条，写入 {result.items_written} 条，"
          f"耗时 {result.duration_seconds:.2f}s")


async def test_github_spider_deduplication_flow(github_spider):
    """连续两次爬取：第二次因 24h 去重几乎不再写入"""
    writer = MockWriter()

    try:
        fetcher = Fetcher()
        result1 = await github_spider.do_fetch(fetcher, writer)
        await fetcher.close()

        fetcher = Fetcher()
        result2 = await github_spider.do_fetch(fetcher, writer)
        await fetcher.close()
    finally:
        pass

    assert result1.success is True
    assert result2.items_written <= result1.items_written, "第二次不应比首次写入更多"

    print(f"\n首次写入 {result1.items_written}，第二次写入 {result2.items_written}")


@pytest.mark.skipif(not USE_REAL_DB, reason="需要设置 TEST_USE_REAL_DB=true")
async def test_github_spider_full_flow_supabase(github_spider):
    """写入真实 Supabase（需配置环境变量）"""
    fetcher = Fetcher()
    writer = Writer()

    try:
        result = await github_spider.do_fetch(fetcher, writer)
    finally:
        await fetcher.close()

    assert result.success is True
    assert result.items_fetched > 0
    assert result.items_written >= 0  # 可能全部命中 24h 去重

    print(f"\n抓取 {result.items_fetched} 条，写入 {result.items_written} 条")


@pytest.mark.performance
async def test_github_spider_performance(github_spider):
    """单页爬取应在 60 秒内完成"""
    fetcher = Fetcher()
    writer = MockWriter()

    try:
        result = await github_spider.do_fetch(fetcher, writer)
    finally:
        await fetcher.close()

    assert result.duration_seconds < 60, f"耗时过长: {result.duration_seconds:.2f}s"
    assert result.items_fetched > 0


async def test_github_spider_error_recovery(github_spider):
    """网络不可用时 run() 不抛异常，返回 success=False 的 SpiderResult"""
    result = await github_spider.run(MockFetcher(default=None), MockWriter())

    assert result is not None
    assert result.success is False
    assert result.errors, "失败原因应记录到 errors"


if __name__ == "__main__":
    pytest.main([__file__, "-v", "-m", "integration", "--tb=short"])
