"""
爬虫监控集成示例
展示如何在爬虫中集成性能监控
"""

from monitoring.performance_monitor import performance_monitor
import logging

logger = logging.getLogger(__name__)


def run_spider_with_monitoring(spider_name: str, spider_func):
    """
    运行爬虫并监控性能

    Args:
        spider_name: 爬虫名称
        spider_func: 爬虫函数，应该是一个生成器，yield 抓取的条目
    """
    # 开始监控
    performance_monitor.start_spider_run(spider_name)

    try:
        # 运行爬虫
        for item in spider_func():
            # 记录成功抓取的条目
            performance_monitor.record_item(spider_name, success=True)
            yield item

    except Exception as e:
        logger.error(f"Spider {spider_name} failed: {e}")
        # 记录失败
        performance_monitor.record_item(spider_name, success=False)
        raise

    finally:
        # 结束监控
        metric = performance_monitor.end_spider_run(spider_name)

        if metric:
            logger.info(f"Spider {spider_name} completed:")
            logger.info(f"  Duration: {metric.duration_seconds:.2f}s")
            logger.info(f"  Items: {metric.items_count}")
            logger.info(f"  Throughput: {metric.items_per_second:.2f} items/s")
            logger.info(f"  Success rate: {metric.success_rate:.1%}")


# 使用示例
if __name__ == '__main__':
    def example_spider():
        """示例爬虫"""
        for i in range(100):
            yield {'id': i, 'title': f'Item {i}'}

    # 运行爬虫
    items = list(run_spider_with_monitoring('example_spider', example_spider))
    print(f"Collected {len(items)} items")

    # 获取统计
    stats = performance_monitor.get_stats('example_spider')
    print(f"Stats: {stats}")
