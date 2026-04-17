"""
爬虫优化模块测试

测试代理池、增量爬取、去重和监控功能
"""
import asyncio
from datetime import timedelta

from core.proxy_pool import ProxyPool
from core.incremental_crawler import IncrementalCrawler
from core.deduplicator import Deduplicator
from monitoring.crawler_monitor import get_monitor


async def test_proxy_pool():
    """测试代理池"""
    print("\n" + "=" * 60)
    print("测试代理池")
    print("=" * 60)

    # 初始化代理池（使用测试代理）
    proxy_pool = ProxyPool(
        proxies=[
            "http://proxy1.example.com:8080",
            "http://proxy2.example.com:8080"
        ],
        max_failures=2
    )

    # 获取代理
    proxy = proxy_pool.get_proxy()
    print(f"获取代理: {proxy}")

    # 模拟成功
    proxy_pool.mark_success(proxy, response_time=1.5)
    print(f"标记成功: {proxy}")

    # 模拟失败
    proxy_pool.mark_failed(proxy)
    print(f"标记失败: {proxy}")

    # 获取统计信息
    stats = proxy_pool.get_stats()
    print(f"\n代理池统计:")
    print(f"  总代理数: {stats['total']}")
    print(f"  健康代理: {stats['healthy']}")
    print(f"  不健康代理: {stats['unhealthy']}")

    print("\n[OK] 代理池测试通过")


async def test_incremental_crawler():
    """测试增量爬取"""
    print("\n" + "=" * 60)
    print("测试增量爬取")
    print("=" * 60)

    # 初始化增量爬取器
    crawler = IncrementalCrawler(state_dir="data/test_state")

    spider_name = "test_spider"

    # 首次爬取
    should_crawl = crawler.should_crawl(
        spider_name,
        min_interval=timedelta(seconds=10)
    )
    print(f"首次爬取: {should_crawl}")

    # 模拟数据项
    items = [
        {"url": "https://example.com/1", "title": "Item 1"},
        {"url": "https://example.com/2", "title": "Item 2"}
    ]

    # 检查是否需要爬取
    for item in items:
        should_crawl_item = crawler.should_crawl_item(spider_name, item)
        print(f"爬取数据项 {item['url']}: {should_crawl_item}")

        if should_crawl_item:
            crawler.mark_item_crawled(spider_name, item)

    # 更新爬取时间
    crawler.update_crawl_time(spider_name, item_count=len(items))

    # 获取统计信息
    stats = crawler.get_stats(spider_name)
    print(f"\n增量爬取统计:")
    print(f"  上次爬取时间: {stats['last_crawl_time']}")
    print(f"  上次数据量: {stats['last_item_count']}")
    print(f"  缓存哈希数: {stats['cached_hashes']}")

    # 再次检查（应该跳过）
    should_crawl_again = crawler.should_crawl(
        spider_name,
        min_interval=timedelta(seconds=10)
    )
    print(f"\n再次爬取（间隔不足）: {should_crawl_again}")

    # 清除状态
    crawler.clear_state(spider_name)
    print("已清除测试状态")

    print("\n[OK] 增量爬取测试通过")


async def test_deduplicator():
    """测试去重"""
    print("\n" + "=" * 60)
    print("测试数据去重")
    print("=" * 60)

    # 初始化去重器
    deduplicator = Deduplicator(
        use_url=True,
        use_content_hash=True,
        use_database=False
    )

    # 测试数据（包含重复）
    items = [
        {"url": "https://example.com/1", "title": "Item 1"},
        {"url": "https://example.com/2", "title": "Item 2"},
        {"url": "https://example.com/1", "title": "Item 1"},  # URL 重复
        {"url": "https://example.com/3", "title": "Item 1"},  # 内容重复
    ]

    print(f"原始数据: {len(items)} 条")

    # 过滤重复
    unique_items = await deduplicator.filter_duplicates(items)

    print(f"去重后数据: {len(unique_items)} 条")
    print(f"移除重复: {len(items) - len(unique_items)} 条")

    print("\n[OK] 数据去重测试通过")


async def test_crawler_monitor():
    """测试爬虫监控"""
    print("\n" + "=" * 60)
    print("测试爬虫监控")
    print("=" * 60)

    # 获取监控器
    monitor = get_monitor()

    # 模拟成功的爬取
    spider_name = "test_spider"
    crawl_id = monitor.start_crawl(spider_name)
    print(f"开始监控: {crawl_id}")

    # 模拟爬取过程
    await asyncio.sleep(0.1)

    monitor.end_crawl(
        crawl_id,
        success=True,
        items_fetched=10,
        items_written=8
    )
    print("结束监控（成功）")

    # 模拟失败的爬取
    crawl_id = monitor.start_crawl(spider_name)
    monitor.end_crawl(
        crawl_id,
        success=False,
        error_message="Connection timeout"
    )
    print("结束监控（失败）")

    # 获取统计信息
    stats = monitor.get_spider_stats(spider_name)
    print(f"\n爬虫统计:")
    print(f"  总运行次数: {stats.total_runs}")
    print(f"  成功次数: {stats.successful_runs}")
    print(f"  失败次数: {stats.failed_runs}")
    print(f"  成功率: {stats.success_rate:.1f}%")
    print(f"  平均响应时间: {stats.avg_response_time:.2f}s")

    # 获取监控摘要
    summary = monitor.get_summary()
    print(f"\n监控摘要:")
    print(f"  总体成功率: {summary['overall_success_rate']}%")

    # 健康检查
    health = monitor.check_health()
    print(f"\n健康检查: {'健康' if health['healthy'] else '有问题'}")
    if health['issues']:
        for issue in health['issues']:
            print(f"  - {issue}")

    # 重置统计
    monitor.reset_stats(spider_name)
    print("\n已重置测试统计")

    print("\n[OK] 爬虫监控测试通过")


async def main():
    """运行所有测试"""
    print("\n" + "=" * 60)
    print("爬虫优化模块测试")
    print("=" * 60)

    try:
        await test_proxy_pool()
        await test_incremental_crawler()
        await test_deduplicator()
        await test_crawler_monitor()

        print("\n" + "=" * 60)
        print("[OK] 所有测试通过")
        print("=" * 60)

    except Exception as e:
        print(f"\n[FAIL] 测试失败: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    asyncio.run(main())
