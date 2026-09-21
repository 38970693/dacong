"""
示例脚本 - 演示如何使用爬虫系统（新架构）

新架构基于 spiders.registry + core.base.SpiderBase：
- 爬虫通过 @register_spider 自动注册
- 统一通过 spider.run(Fetcher(), Writer()) 执行
- 不再使用老的工厂 / DI 风格（HttpClient + DataProcessor + Storage）

运行：
    python examples.py
"""
import asyncio
import logging

from spiders.registry import list_spiders, get_spider
from core.fetcher import Fetcher
from core.writer import Writer


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)


async def example_1_single_spider():
    """示例 1: 执行单个爬虫（GitHub Trending）"""
    print("\n" + "=" * 60)
    print("示例 1: 执行单个 GitHub Trending 爬虫")
    print("=" * 60)

    spider = get_spider("github")
    result = await spider.run(Fetcher(), Writer())

    print(f"\n执行结果:")
    print(f"  成功: {result.success}")
    print(f"  抓取: {result.items_fetched} 条")
    print(f"  写入: {result.items_written} 条")
    print(f"  耗时: {result.duration_seconds:.2f} 秒")
    if result.errors:
        print(f"  错误: {result.errors}")


async def example_2_multiple_spiders():
    """示例 2: 批量执行多个爬虫"""
    print("\n" + "=" * 60)
    print("示例 2: 批量执行多个爬虫")
    print("=" * 60)

    names = ["github", "huggingface", "hackernews"]
    spiders = [get_spider(name) for name in names]

    results = await asyncio.gather(
        *(spider.run(Fetcher(), Writer()) for spider in spiders),
        return_exceptions=True,
    )

    print(f"\n执行结果:")
    for name, result in zip(names, results):
        if isinstance(result, Exception):
            print(f"  ❌ {name}: {result}")
            continue
        status = "✅" if result.success else "❌"
        print(f"  {status} {name}: 抓取 {result.items_fetched} 条, "
              f"写入 {result.items_written} 条, 耗时 {result.duration_seconds:.2f}s")


async def example_3_list_all():
    """示例 3: 列出所有已注册爬虫"""
    print("\n" + "=" * 60)
    print("示例 3: 列出所有已注册爬虫")
    print("=" * 60)
    print("可用爬虫:")
    for name in list_spiders():
        print(f"  - {name}")


async def main():
    print("\n" + "=" * 60)
    print("DaCong Spider - 示例脚本（新架构）")
    print("=" * 60)
    await example_1_single_spider()
    await example_2_multiple_spiders()
    await example_3_list_all()
    print("\n" + "=" * 60)
    print("所有示例执行完成")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
