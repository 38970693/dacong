"""
测试 AI Rankings 爬虫
用于验证爬虫是否能正常运行
"""
import asyncio
import sys
from pathlib import Path

project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))


async def test_spider(spider_instance) -> bool:
    """测试单个爬虫"""
    try:
        result = await spider_instance.run()
        return result.success
    except Exception as e:
        print(f"  错误: {e}")
        import traceback
        traceback.print_exc()
        return False


async def main():
    """主函数"""
    print("=" * 50)
    print("AI Rankings 爬虫测试")
    print("=" * 50)

    # 导入爬虫
    from spiders.swebench import SWEBenchSpider
    from spiders.arena import ArenaSpider
    from spiders.artificial_analysis import ArtificialAnalysisSpider
    from spiders.aiping import AIPingSpider

    # 创建爬虫实例
    spiders = [
        (SWEBenchSpider(), "SWE-bench"),
        (ArenaSpider(), "Arena.ai"),
        (ArtificialAnalysisSpider(), "Artificial Analysis"),
        (AIPingSpider(), "AI Ping"),
    ]

    results = []
    for i, (spider, spider_name) in enumerate(spiders, 1):
        print(f"\n[{i}/4] 测试 {spider_name} 爬虫...")
        try:
            result = await test_spider(spider)
            print(f"  结果: {'成功' if result else '失败'}")
            print(f"  获取: {spider.items_fetched} 条数据")
            print(f"  写入: {spider.items_written} 条数据")
            results.append(result)
        except Exception as e:
            print(f"  错误: {e}")
            results.append(False)

    print("\n" + "=" * 50)
    print(f"汇总: {sum(results)}/{len(results)} 成功")
    print("=" * 50)

    return 0 if all(results) else 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)