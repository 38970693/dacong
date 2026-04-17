"""
GitHub 爬虫集成测试

测试策略：
1. 测试完整的爬取流程（HTTP -> 处理 -> 存储）
2. 测试数据库写入
3. 测试去重逻辑
4. 使用真实的 HTTP 客户端（可选 Mock）
"""
import pytest
import os
from datetime import datetime, timezone

from core.interfaces import MetricSource, DataType
from core.implementations import HttpClient, ContentHashDeduplicator, SpiderLogger
from core.storage import InMemoryStorage, SupabaseStorage
from spiders.github_spider import GitHubSpider, GitHubDataProcessor
from config import config


# ══════════════════════════════════════════════════════════
# 测试配置
# ══════════════════════════════════════════════════════════

USE_REAL_API = os.getenv("TEST_USE_REAL_API", "false").lower() == "true"
USE_REAL_DB = os.getenv("TEST_USE_REAL_DB", "false").lower() == "true"


# ══════════════════════════════════════════════════════════
# 集成测试 - 使用内存存储
# ══════════════════════════════════════════════════════════

@pytest.mark.asyncio
@pytest.mark.integration
async def test_github_spider_full_flow_memory():
    """测试 GitHub 爬虫完整流程（内存存储）"""
    # 创建真实组件
    http_client = HttpClient()
    storage = InMemoryStorage()
    processor = GitHubDataProcessor()
    deduplicator = ContentHashDeduplicator()
    logger = SpiderLogger("github_integration_test")

    # 创建爬虫（使用真实 API token）
    spider = GitHubSpider(
        http_client=http_client,
        data_processor=processor,
        storage=storage,
        deduplicator=deduplicator,
        logger=logger,
        api_token=config.github_token
    )

    try:
        # 执行爬虫
        result = await spider.run()

        # 验证结果
        assert result.success is True, f"爬虫执行失败: {result.errors}"
        assert result.items_fetched > 0, "未抓取到任何数据"
        assert result.items_written > 0, "未写入任何数据"
        assert storage.count() > 0, "存储中没有数据"

        # 验证数据质量
        for key, data in storage.data.items():
            assert data.source == MetricSource.GITHUB
            assert data.data_type == DataType.REPOSITORY
            assert data.source_id, "source_id 不能为空"
            assert data.title, "title 不能为空"
            assert data.url.startswith("https://github.com/"), "URL 格式错误"
            assert data.content_hash, "content_hash 不能为空"
            assert len(data.content_hash) == 32, "content_hash 长度错误"
            assert data.metadata.get("stars") is not None, "缺少 stars 元数据"

        print(f"\n✅ 集成测试通过:")
        print(f"   - 抓取: {result.items_fetched} 条")
        print(f"   - 写入: {result.items_written} 条")
        print(f"   - 耗时: {result.duration_seconds:.2f}s")

    finally:
        await http_client.close()


@pytest.mark.asyncio
@pytest.mark.integration
async def test_github_spider_deduplication_flow():
    """测试 GitHub 爬虫去重流程"""
    http_client = HttpClient()
    storage = InMemoryStorage()
    processor = GitHubDataProcessor()
    deduplicator = ContentHashDeduplicator()
    logger = SpiderLogger("github_dedup_test")

    spider = GitHubSpider(
        http_client=http_client,
        data_processor=processor,
        storage=storage,
        deduplicator=deduplicator,
        logger=logger,
        api_token=config.github_token
    )

    try:
        # 第一次运行
        result1 = await spider.run()
        count1 = storage.count()

        assert result1.success is True
        assert count1 > 0

        # 第二次运行（应该检测到重复）
        result2 = await spider.run()
        count2 = storage.count()

        # 数据量应该相同或略有增加（如果有新数据）
        assert count2 >= count1
        # 第二次写入的数量应该很少（大部分是重复的）
        assert result2.items_written <= result2.items_fetched

        print(f"\n✅ 去重测试通过:")
        print(f"   - 第一次: 抓取 {result1.items_fetched}, 写入 {result1.items_written}")
        print(f"   - 第二次: 抓取 {result2.items_fetched}, 写入 {result2.items_written}")
        print(f"   - 去重率: {(1 - result2.items_written / result2.items_fetched) * 100:.1f}%")

    finally:
        await http_client.close()


# ══════════════════════════════════════════════════════════
# 集成测试 - 使用真实数据库（可选）
# ══════════════════════════════════════════════════════════

@pytest.mark.asyncio
@pytest.mark.integration
@pytest.mark.skipif(not USE_REAL_DB, reason="需要设置 TEST_USE_REAL_DB=true")
async def test_github_spider_full_flow_supabase():
    """测试 GitHub 爬虫完整流程（Supabase 存储）"""
    http_client = HttpClient()
    storage = SupabaseStorage()
    processor = GitHubDataProcessor()
    deduplicator = ContentHashDeduplicator()
    logger = SpiderLogger("github_supabase_test")

    spider = GitHubSpider(
        http_client=http_client,
        data_processor=processor,
        storage=storage,
        deduplicator=deduplicator,
        logger=logger,
        api_token=config.github_token
    )

    try:
        result = await spider.run()

        assert result.success is True
        assert result.items_fetched > 0
        assert result.items_written >= 0  # 可能全部是重复数据

        print(f"\n✅ Supabase 集成测试通过:")
        print(f"   - 抓取: {result.items_fetched} 条")
        print(f"   - 写入: {result.items_written} 条")
        print(f"   - 耗时: {result.duration_seconds:.2f}s")

    finally:
        await http_client.close()


# ══════════════════════════════════════════════════════════
# 性能测试
# ══════════════════════════════════════════════════════════

@pytest.mark.asyncio
@pytest.mark.integration
@pytest.mark.performance
async def test_github_spider_performance():
    """测试 GitHub 爬虫性能"""
    http_client = HttpClient()
    storage = InMemoryStorage()
    processor = GitHubDataProcessor()
    deduplicator = ContentHashDeduplicator()
    logger = SpiderLogger("github_perf_test")

    spider = GitHubSpider(
        http_client=http_client,
        data_processor=processor,
        storage=storage,
        deduplicator=deduplicator,
        logger=logger,
        api_token=config.github_token
    )

    try:
        result = await spider.run()

        # 性能要求（放宽到 120 秒，因为 GitHub API 有 rate limit）
        assert result.duration_seconds < 120, f"爬取时间超过 120 秒: {result.duration_seconds:.2f}s"
        assert result.items_fetched > 50, "抓取数据量太少"

        # 计算吞吐量
        throughput = result.items_fetched / result.duration_seconds if result.duration_seconds > 0 else 0
        print(f"\n✅ 性能测试通过:")
        print(f"   - 总耗时: {result.duration_seconds:.2f}s")
        print(f"   - 吞吐量: {throughput:.2f} items/s")

    finally:
        await http_client.close()


# ══════════════════════════════════════════════════════════
# 错误恢复测试
# ══════════════════════════════════════════════════════════

@pytest.mark.asyncio
@pytest.mark.integration
async def test_github_spider_error_recovery():
    """测试 GitHub 爬虫错误恢复"""
    # 使用无效的 token
    http_client = HttpClient()
    storage = InMemoryStorage()
    processor = GitHubDataProcessor()
    deduplicator = ContentHashDeduplicator()
    logger = SpiderLogger("github_error_test")

    spider = GitHubSpider(
        http_client=http_client,
        data_processor=processor,
        storage=storage,
        deduplicator=deduplicator,
        logger=logger,
        api_token="invalid_token_12345"
    )

    try:
        result = await spider.run()

        # 即使 token 无效，爬虫也不应该崩溃
        # GitHub API 在没有 token 时有更低的 rate limit，但仍然可以工作
        assert result is not None
        # 可能成功（使用匿名访问）或失败（rate limit）
        print(f"\n✅ 错误恢复测试通过:")
        print(f"   - 状态: {'成功' if result.success else '失败'}")
        print(f"   - 抓取: {result.items_fetched} 条")

    finally:
        await http_client.close()


if __name__ == "__main__":
    pytest.main([
        __file__,
        "-v",
        "-m", "integration",
        "--tb=short"
    ])
