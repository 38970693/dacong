"""
AI Rankings Spider 调度器
用于运行所有 AI 评测平台爬虫
"""
import asyncio
import logging
import sys
from pathlib import Path

# 添加项目根目录到路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from core.base import AsyncSpiderRunner
from spiders.swebench import SWEBenchSpider
from spiders.arena import ArenaSpider
from spiders.artificial_analysis import ArtificialAnalysisSpider

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('logs/rankings_spider.log', encoding='utf-8'),
    ]
)

logger = logging.getLogger(__name__)


async def main():
    """主函数"""
    logger.info("=" * 50)
    logger.info("AI Rankings Spider 调度器启动")
    logger.info("=" * 50)

    # 创建所有爬虫实例（按优先级排序）
    spiders = [
        SWEBenchSpider(),      # SWE-bench.org - 代码能力评测
        ArenaSpider(),         # LMArena.ai - 社区投票
        ArtificialAnalysisSpider(),  # Artificial Analysis - 性能/价格
    ]

    # 创建调度器（并发数 2，避免同时请求过多）
    runner = AsyncSpiderRunner(spiders, concurrency=2)

    # 运行所有爬虫
    results = await runner.run_all()

    # 输出汇总
    logger.info("=" * 50)
    logger.info("执行结果汇总:")
    for result in results:
        status = "✓ 成功" if result.success else "✗ 失败"
        logger.info(
            f"  {result.spider_name}: {status} | "
            f"获取 {result.items_fetched} | 写入 {result.items_written}"
        )
        if result.errors:
            for err in result.errors:
                logger.error(f"    错误: {err}")
    logger.info("=" * 50)

    # 返回成功/失败
    all_success = all(r.success for r in results)
    return 0 if all_success else 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)