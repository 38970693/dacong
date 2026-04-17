"""
性能监控集成到主爬虫
"""

import sys
import os

# 添加项目根目录到 Python 路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from monitoring.performance_monitor import performance_monitor
from monitoring.example_usage import run_spider_with_monitoring

# 在 main.py 中集成性能监控的示例
#
# 使用方法：
# 1. 导入 performance_monitor
# 2. 在爬虫开始时调用 start_spider_run()
# 3. 每抓取一个条目调用 record_item()
# 4. 在爬虫结束时调用 end_spider_run()
#
# 示例代码：
#
# from monitoring.performance_monitor import performance_monitor
#
# def run_weekly_spider():
#     performance_monitor.start_spider_run('weekly_spider')
#
#     try:
#         for item in scrape_weekly_content():
#             performance_monitor.record_item('weekly_spider', success=True)
#             save_to_database(item)
#     except Exception as e:
#         performance_monitor.record_item('weekly_spider', success=False)
#         raise
#     finally:
#         metric = performance_monitor.end_spider_run('weekly_spider')
#         print(f"Spider completed in {metric.duration_seconds:.2f}s")
