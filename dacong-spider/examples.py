"""
示例脚本 - 演示如何使用爬虫系统

展示了：
1. 手动执行单个爬虫
2. 批量执行多个爬虫
3. 使用内存存储进行测试
4. 自定义配置
"""
import asyncio
import logging

from core.factory import SpiderFactory, SpiderRegistry
from core.storage import InMemoryStorage
from core.implementations import HttpClient, ContentHashDeduplicator


# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)


async def example_1_single_spider():
    """示例 1: 执行单个爬虫"""
    print("\n" + "=" * 60)
    print("示例 1: 执行单个 GitHub 爬虫")
    print("=" * 60)

    # 创建工厂（使用内存存储进行测试）
    factory = SpiderFactory(storage=InMemoryStorage())

    # 创建爬虫
    spider = factory.create_github_spider()

    # 执行爬虫
    result = await spider.run()

    # 输出结果
    print(f"\n执行结果:")
    print(f"  成功: {result.success}")
    print(f"  抓取: {result.items_fetched} 条")
    print(f"  写入: {result.items_written} 条")
    print(f"  耗时: {result.duration_seconds:.2f} 秒")

    if result.errors:
        print(f"  错误: {result.errors}")

    # 清理
    await factory.cleanup()


async def example_2_multiple_spiders():
    """示例 2: 批量执行多个爬虫"""
    print("\n" + "=" * 60)
    print("示例 2: 批量执行多个爬虫")
    print("=" * 60)

    # 创建注册表
    factory = SpiderFactory(storage=InMemoryStorage())
    registry = SpiderRegistry(factory)

    # 注册爬虫
    from spiders.github_spider import GitHubSpider
    from spiders.huggingface_spider import HuggingFaceSpider
    from spiders.openrouter_spider import OpenRouterSpider

    registry.register("github", GitHubSpider)
    registry.register("huggingface", HuggingFaceSpider)
    registry.register("openrouter", OpenRouterSpider)

    # 获取所有爬虫
    spiders = registry.get_all()

    # 并发执行
    tasks = [spider.run() for spider in spiders]
    results = await asyncio.gather(*tasks)

    # 输出结果
    print(f"\n执行结果:")
    for result in results:
        status = "✅" if result.success else "❌"
        print(f"  {status} {result.spider_name}: "
              f"抓取 {result.items_fetched} 条, "
              f"写入 {result.items_written} 条, "
              f"耗时 {result.duration_seconds:.2f}s")

    # 清理
    await factory.cleanup()


async def example_3_custom_config():
    """示例 3: 自定义配置"""
    print("\n" + "=" * 60)
    print("示例 3: 自定义配置")
    print("=" * 60)

    # 自定义 HTTP 客户端（更长的超时时间）
    from core.implementations import ExponentialBackoffRetry

    http_client = HttpClient(
        timeout=60,  # 60 秒超时
        retry_strategy=ExponentialBackoffRetry(max_retries=5)
    )

    # 使用内存存储
    storage = InMemoryStorage()

    # 创建工厂
    factory = SpiderFactory(
        http_client=http_client,
        storage=storage
    )

    # 创建爬虫
    spider = factory.create_github_spider()

    # 执行
    result = await spider.run()

    print(f"\n执行结果:")
    print(f"  成功: {result.success}")
    print(f"  存储中的数据量: {storage.count()}")

    # 清理
    await factory.cleanup()


async def example_4_test_deduplication():
    """示例 4: 测试去重功能"""
    print("\n" + "=" * 60)
    print("示例 4: 测试去重功能")
    print("=" * 60)

    storage = InMemoryStorage()
    factory = SpiderFactory(storage=storage)

    # 第一次执行
    spider = factory.create_github_spider()
    result1 = await spider.run()

    print(f"\n第一次执行:")
    print(f"  抓取: {result1.items_fetched} 条")
    print(f"  写入: {result1.items_written} 条")
    print(f"  存储中的数据: {storage.count()} 条")

    # 第二次执行（应该检测到重复）
    spider = factory.create_github_spider()
    result2 = await spider.run()

    print(f"\n第二次执行:")
    print(f"  抓取: {result2.items_fetched} 条")
    print(f"  写入: {result2.items_written} 条 (应该是 0，因为数据重复)")
    print(f"  存储中的数据: {storage.count()} 条 (应该不变)")

    # 清理
    await factory.cleanup()


async def main():
    """主函数"""
    print("\n" + "=" * 60)
    print("DaCong Spider - 示例脚本")
    print("=" * 60)

    # 运行示例
    await example_1_single_spider()
    await example_2_multiple_spiders()
    await example_3_custom_config()
    await example_4_test_deduplication()

    print("\n" + "=" * 60)
    print("所有示例执行完成")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
