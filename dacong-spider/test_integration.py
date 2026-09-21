"""
简化的集成测试 - 验证代码结构，不依赖网络
"""
import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from core.factory import SpiderFactory


def test_factory_creation():
    """测试工厂能正确创建所有爬虫"""
    print("\n" + "="*60)
    print("测试 1: SpiderFactory 创建爬虫")
    print("="*60)

    factory = SpiderFactory()

    try:
        # YouTube 爬虫
        yt = factory.create_youtube_spider(keywords=["AI"], max_results=5)
        assert yt is not None
        print("[OK] YouTube 爬虫创建成功")

        # RSS 爬虫 (默认 Google News)
        rss = factory.create_googlenews_spider(search_topics=["AI"])
        assert rss is not None
        print("[OK] RSS 爬虫创建成功")

        # Twitter 爬虫
        twitter = factory.create_twitter_spider(search_keywords=["AI"])
        assert twitter is not None
        print("[OK] Twitter 爬虫创建成功")

        # Google News 爬虫
        gn = factory.create_googlenews_spider(search_topics=["ML"])
        assert gn is not None
        print("[OK] Google News 爬虫创建成功")

        return True
    except Exception as e:
        print(f"[FAIL] 工厂创建失败: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_spider_properties():
    """测试爬虫属性配置"""
    print("\n" + "="*60)
    print("测试 2: 爬虫属性验证")
    print("="*60)

    factory = SpiderFactory()

    try:
        yt = factory.create_youtube_spider(keywords=["AI"], max_results=5)
        assert yt.name == "YouTube Spider"
        assert yt.source.value == "youtube"
        print(f"[OK] YouTube: name={yt.name}, source={yt.source.value}")

        twitter = factory.create_twitter_spider(search_keywords=["AI"])
        assert twitter.name == "Twitter Spider"
        assert twitter.source.value == "twitter"
        print(f"[OK] Twitter: name={twitter.name}, source={twitter.source.value}")

        gn = factory.create_googlenews_spider(search_topics=["AI"])
        assert gn.name == "Google News Spider"
        assert gn.source.value == "google_news"
        print(f"[OK] GoogleNews: name={gn.name}, source={gn.source.value}")

        return True
    except Exception as e:
        print(f"[FAIL] 属性验证失败: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_processor_registration():
    """测试处理器注册"""
    print("\n" + "="*60)
    print("测试 3: 处理器注册")
    print("="*60)

    from spiders.processors import get_processor_for_spider
    from spiders.youtube_spider import YouTubeSpider
    from spiders.rss_spider import TwitterSpider, GoogleNewsSpider, RSSSpider

    try:
        # YouTube 处理器
        yt_proc = get_processor_for_spider(YouTubeSpider)
        assert yt_proc is not None
        print("[OK] YouTube 处理器已注册")

        # Twitter 处理器
        tw_proc = get_processor_for_spider(TwitterSpider)
        assert tw_proc is not None
        print("[OK] Twitter 处理器已注册")

        # Google News 处理器
        gn_proc = get_processor_for_spider(GoogleNewsSpider)
        assert gn_proc is not None
        print("[OK] Google News 处理器已注册")

        # RSS 处理器
        rss_proc = get_processor_for_spider(RSSSpider)
        assert rss_proc is not None
        print("[OK] RSS 处理器已注册")

        return True
    except Exception as e:
        print(f"[FAIL] 处理器注册失败: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_data_processing():
    """测试数据处理逻辑"""
    print("\n" + "="*60)
    print("测试 4: 数据处理单元测试")
    print("="*60)

    from spiders.youtube_spider import YouTubeDataProcessor
    from spiders.rss_spider import RSSDataProcessor

    try:
        # YouTube 处理器
        yt_proc = YouTubeDataProcessor()

        # 模拟 YouTube 数据
        yt_data = {
            "id": "dQw4w9WgXcQ",
            "title": "Test Video - AI Tutorial",
            "description": "Learn about AI and machine learning",
            "channel": "Test Channel",
            "channel_id": "UC123456",
            "duration": 600,
            "view_count": 1000,
            "upload_date": "20240101"
        }

        result = yt_proc.process(yt_data)
        assert result is not None
        assert result.source.value == "youtube"
        assert result.title == "Test Video - AI Tutorial"
        print("[OK] YouTube 数据处理正确")

        # RSS 处理器
        rss_proc = RSSDataProcessor()

        # 模拟 RSS 数据
        rss_data = {
            "id": "rss-123",
            "title": "AI News Article",
            "description": "Latest AI developments",
            "link": "https://example.com/article",
            "source": "google_news",
            "source_type": "google_news",
            "feed_name": "Google News - AI",
            "pub_date": "2024-01-01"
        }

        result = rss_proc.process(rss_data)
        assert result is not None
        assert result.source.value == "google_news"
        print("[OK] RSS 数据处理正确")

        return True
    except Exception as e:
        print(f"[FAIL] 数据处理失败: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_hash_consistency():
    """测试内容哈希一致性"""
    print("\n" + "="*60)
    print("测试 5: 内容哈希一致性")
    print("="*60)

    from spiders.youtube_spider import YouTubeDataProcessor
    from spiders.rss_spider import RSSDataProcessor

    try:
        yt_proc = YouTubeDataProcessor()
        rss_proc = RSSDataProcessor()

        # 相同数据应生成相同哈希
        data = {"id": "test", "title": "Test"}

        hash1 = yt_proc.generate_content_hash(data)
        hash2 = yt_proc.generate_content_hash(data)
        assert hash1 == hash2
        print("[OK] YouTube 哈希一致")

        hash3 = rss_proc.generate_content_hash(data)
        hash4 = rss_proc.generate_content_hash(data)
        assert hash3 == hash4
        print("[OK] RSS 哈希一致")

        # 不同数据应生成不同哈希
        hash5 = yt_proc.generate_content_hash({"id": "other"})
        assert hash1 != hash5
        print("[OK] 不同数据哈希不同")

        return True
    except Exception as e:
        print(f"[FAIL] 哈希测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    print("="*60)
    print("集成测试 (不依赖网络)")
    print("="*60)

    results = {
        "Factory创建": test_factory_creation(),
        "爬虫属性": test_spider_properties(),
        "处理器注册": test_processor_registration(),
        "数据处理": test_data_processing(),
        "哈希一致性": test_hash_consistency(),
    }

    print("\n" + "="*60)
    print("测试结果汇总")
    print("="*60)

    passed = sum(1 for v in results.values() if v)
    total = len(results)

    for name, success in results.items():
        status = "[PASS]" if success else "[FAIL]"
        print(f"{status} {name}")

    print(f"\n通过: {passed}/{total}")

    if passed == total:
        print("\n所有集成测试通过!")
        print("注意: 实际网络抓取测试需要稳定网络连接")
    else:
        print("\n部分测试失败，请检查代码")