"""
爬虫优化集成示例

展示如何在实际爬虫中使用代理池、增量爬取、去重和监控功能
"""
import asyncio
from datetime import timedelta
from typing import List, Dict

from core.proxy_pool import ProxyPool
from core.incremental_crawler import IncrementalCrawler
from core.deduplicator import Deduplicator
from monitoring.crawler_monitor import get_monitor


class OptimizedSpiderExample:
    """
    优化后的爬虫示例

    集成了所有优化功能：
    - 代理池管理
    - 增量爬取
    - 数据去重
    - 实时监控
    """

    def __init__(self, name: str, proxies: List[str] = None):
        """
        初始化优化爬虫

        Args:
            name: 爬虫名称
            proxies: 代理列表
        """
        self.name = name

        # 初始化代理池
        self.proxy_pool = ProxyPool(
            proxies=proxies or [],
            max_failures=3,
            health_check_interval=300
        )

        # 初始化增量爬取器
        self.incremental = IncrementalCrawler(
            state_dir="data/crawler_state"
        )

        # 初始化去重器
        self.deduplicator = Deduplicator(
            use_url=True,
            use_content_hash=True,
            use_database=False
        )

        # 获取监控器
        self.monitor = get_monitor()

        print(f"爬虫初始化完成: {self.name}")

    async def run(self, min_interval: timedelta = None, force: bool = False):
        """
        执行爬取

        Args:
            min_interval: 最小爬取间隔
            force: 是否强制爬取
        """
        # 检查是否需要爬取
        if not force and min_interval:
            if not self.incremental.should_crawl(self.name, min_interval):
                print(f"跳过爬取（间隔不足）: {self.name}")
                return

        # 开始监控
        crawl_id = self.monitor.start_crawl(self.name)
        print(f"开始爬取: {self.name}")

        proxy = None

        try:
            # 获取最佳代理
            proxy = self.proxy_pool.get_best_proxy()
            if proxy:
                print(f"使用代理: {proxy}")

            # 执行爬取
            items = await self.fetch_data(proxy)
            print(f"抓取到 {len(items)} 条原始数据")

            # 去重
            unique_items = await self.deduplicator.filter_duplicates(items)
            print(f"去重后 {len(unique_items)} 条数据")

            # 过滤已爬取的数据
            new_items = [
                item for item in unique_items
                if self.incremental.should_crawl_item(self.name, item)
            ]
            print(f"增量过滤后 {len(new_items)} 条新数据")

            # 保存数据
            saved_count = await self.save_data(new_items)
            print(f"成功保存 {saved_count} 条数据")

            # 标记已爬取
            for item in new_items:
                self.incremental.mark_item_crawled(self.name, item)

            # 更新爬取时间
            self.incremental.update_crawl_time(
                self.name,
                item_count=len(new_items),
                metadata={"proxy": proxy}
            )

            # 标记代理成功
            if proxy:
                self.proxy_pool.mark_success(proxy, response_time=2.5)

            # 结束监控（成功）
            self.monitor.end_crawl(
                crawl_id,
                success=True,
                items_fetched=len(items),
                items_written=saved_count
            )

            print(f"爬取完成: {self.name}")

        except Exception as e:
            print(f"爬取失败: {self.name} - {e}")

            # 标记代理失败
            if proxy:
                self.proxy_pool.mark_failed(proxy)

            # 结束监控（失败）
            self.monitor.end_crawl(
                crawl_id,
                success=False,
                error_message=str(e)
            )

            raise

    async def fetch_data(self, proxy: str = None) -> List[Dict]:
        """
        抓取数据（需要子类实现）

        Args:
            proxy: 代理 URL

        Returns:
            数据列表
        """
        # 模拟抓取数据
        await asyncio.sleep(0.5)

        return [
            {"url": f"https://example.com/{i}", "title": f"Item {i}"}
            for i in range(1, 11)
        ]

    async def save_data(self, items: List[Dict]) -> int:
        """
        保存数据（需要子类实现）

        Args:
            items: 数据列表

        Returns:
            保存的数据量
        """
        # 模拟保存数据
        await asyncio.sleep(0.2)
        return len(items)

    def get_stats(self) -> Dict:
        """
        获取爬虫统计信息

        Returns:
            统计信息字典
        """
        return {
            "proxy_pool": self.proxy_pool.get_stats(),
            "incremental": self.incremental.get_stats(self.name),
            "monitor": self.monitor.get_spider_stats(self.name)
        }

    async def health_check(self):
        """执行健康检查"""
        print(f"\n健康检查: {self.name}")
        print("-" * 60)

        # 代理池健康检查
        await self.proxy_pool.health_check()
        proxy_stats = self.proxy_pool.get_stats()
        print(f"代理池: {proxy_stats['healthy']}/{proxy_stats['total']} 健康")

        # 监控健康检查
        health = self.monitor.check_health()
        print(f"监控: {'健康' if health['healthy'] else '有问题'}")

        if health['issues']:
            print("发现问题:")
            for issue in health['issues']:
                print(f"  - {issue}")


async def main():
    """示例：使用优化爬虫"""
    print("=" * 60)
    print("爬虫优化集成示例")
    print("=" * 60)

    # 创建优化爬虫
    spider = OptimizedSpiderExample(
        name="example_spider",
        proxies=[
            "http://proxy1.example.com:8080",
            "http://proxy2.example.com:8080"
        ]
    )

    # 首次爬取
    print("\n第一次爬取:")
    await spider.run(min_interval=timedelta(seconds=10))

    # 立即再次爬取（应该跳过）
    print("\n第二次爬取（间隔不足）:")
    await spider.run(min_interval=timedelta(seconds=10))

    # 强制爬取
    print("\n第三次爬取（强制）:")
    await spider.run(force=True)

    # 获取统计信息
    print("\n统计信息:")
    print("-" * 60)
    stats = spider.get_stats()

    print(f"\n代理池:")
    print(f"  总代理: {stats['proxy_pool']['total']}")
    print(f"  健康代理: {stats['proxy_pool']['healthy']}")

    print(f"\n增量爬取:")
    print(f"  上次爬取: {stats['incremental']['last_crawl_time']}")
    print(f"  上次数据量: {stats['incremental']['last_item_count']}")

    if stats['monitor']:
        print(f"\n监控:")
        print(f"  总运行次数: {stats['monitor'].total_runs}")
        print(f"  成功率: {stats['monitor'].success_rate:.1f}%")
        print(f"  平均响应时间: {stats['monitor'].avg_response_time:.2f}s")

    # 健康检查
    await spider.health_check()

    # 生成监控报告
    print("\n监控报告:")
    print("-" * 60)
    monitor = get_monitor()
    print(monitor.generate_report())


if __name__ == "__main__":
    asyncio.run(main())
