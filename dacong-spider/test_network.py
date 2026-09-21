"""
实际网络测试 - 测试 YouTube、Twitter、Google News 爬虫
"""
import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from core.factory import SpiderFactory
from core.storage import InMemoryStorage


async def test_youtube_network():
    """测试 YouTube 爬虫网络抓取"""
    print("\n" + "="*60)
    print("测试 1: YouTube 爬虫 (网络)")
    print("="*60)

    factory = SpiderFactory()
    storage = InMemoryStorage()

    try:
        spider = factory.create_youtube_spider(
            keywords=["AI", "machine learning"],
            max_results=5
        )
        spider.storage = storage

        print(f"开始抓取 YouTube (关键词: {spider.keywords})...")
        result = await spider.run()

        print(f"抓取成功: {result.success}")
        print(f"获取条目: {result.items_fetched}")
        print(f"写入条目: {result.items_written}")

        if storage.count() > 0:
            print("\n示例数据:")
            for i, item in enumerate(list(storage.data.values())[:3]):
                print(f"  [{i+1}] {item.title[:60]}...")
                print(f"      URL: {item.url}")
                print(f"      Source: {item.source.value}")

        return result.success and result.items_fetched > 0

    except Exception as e:
        print(f"[FAIL] YouTube 爬虫失败: {e}")
        import traceback
        traceback.print_exc()
        return False


async def test_twitter_network():
    """测试 Twitter 爬虫网络抓取"""
    print("\n" + "="*60)
    print("测试 2: Twitter 爬虫 (网络)")
    print("="*60)

    factory = SpiderFactory()
    storage = InMemoryStorage()

    try:
        spider = factory.create_twitter_spider(
            search_keywords=["AI", "ChatGPT"]
        )
        spider.storage = storage

        print(f"开始抓取 Twitter (关键词: {spider.keywords})...")
        result = await spider.run()

        print(f"抓取成功: {result.success}")
        print(f"获取条目: {result.items_fetched}")
        print(f"写入条目: {result.items_written}")

        return result.success

    except Exception as e:
        print(f"[FAIL] Twitter 爬虫失败: {e}")
        import traceback
        traceback.print_exc()
        return False


async def test_googlenews_network():
    """测试 Google News 爬虫网络抓取"""
    print("\n" + "="*60)
    print("测试 3: Google News 爬虫 (网络)")
    print("="*60)

    factory = SpiderFactory()
    storage = InMemoryStorage()

    try:
        spider = factory.create_googlenews_spider(
            search_topics=["AI", "machine learning"]
        )
        spider.storage = storage

        print(f"开始抓取 Google News (主题: {spider.keywords})...")
        result = await spider.run()

        print(f"抓取成功: {result.success}")
        print(f"获取条目: {result.items_fetched}")
        print(f"写入条目: {result.items_written}")

        if result.items_fetched > 0:
            print("\n成功! Google News 数据抓取正常")

        return result.success

    except Exception as e:
        print(f"[FAIL] Google News 爬虫失败: {e}")
        import traceback
        traceback.print_exc()
        return False


async def main():
    print("="*60)
    print("实际网络测试")
    print("="*60)

    results = {}

    # 测试 YouTube (使用 yt-dlp)
    results["YouTube"] = await test_youtube_network()

    # 测试 Twitter (使用 RSSHub)
    results["Twitter"] = await test_twitter_network()

    # 测试 Google News (使用 RSSHub)
    results["GoogleNews"] = await test_googlenews_network()

    print("\n" + "="*60)
    print("网络测试结果汇总")
    print("="*60)

    passed = sum(1 for v in results.values() if v)
    total = len(results)

    for name, success in results.items():
        status = "[PASS]" if success else "[FAIL]"
        print(f"{status} {name}")

    print(f"\n通过: {passed}/{total}")

    if passed == total:
        print("\n所有网络测试通过!")
    else:
        print(f"\n{total - passed} 个测试失败 (可能是网络问题)")


if __name__ == "__main__":
    asyncio.run(main())