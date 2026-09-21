"""
主入口 - 启动爬虫系统

职责：初始化系统并启动调度器
"""
import argparse
import asyncio
import logging
import sys
from typing import Optional

from core.sentry_config import init_sentry, set_tag, capture_exception, report_spider_error
from schedulers.jobs import build_scheduler


def setup_logging(debug: bool = False):
    """配置日志"""
    from config import config
    import os

    # 创建日志目录
    log_dir = os.path.dirname(config.log_file)
    if log_dir and not os.path.exists(log_dir):
        os.makedirs(log_dir)

    # 设置日志级别
    log_level = "DEBUG" if debug else config.log_level

    # 配置日志格式
    logging.basicConfig(
        level=getattr(logging, log_level),
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        handlers=[
            logging.FileHandler(config.log_file, encoding='utf-8'),
            logging.StreamHandler(sys.stdout)
        ]
    )

    # 强制设置 stdout 的编码为 UTF-8
    sys.stdout.reconfigure(encoding='utf-8')


def setup_sentry(debug: bool = False):
    """配置 Sentry"""
    init_sentry(
        environment="development" if debug else "production",
        traces_sample_rate=1.0 if debug else 0.2,
        debug=debug,
    )

    # 设置全局标签
    set_tag("component", "spider")
    set_tag("app", "dacong-spider")


async def run_single_spider(spider_name: str):
    """运行单个爬虫（兼容 registry.py 中的两套架构）"""
    logger = logging.getLogger(__name__)

    try:
        from spiders.registry import get_spider, list_spiders
        from core.fetcher import Fetcher
        from core.writer import Writer
        from spiders.rankings_base import BaseRankingsSpider
    except ImportError as e:
        logger.error(f"导入爬虫注册表失败: {e}")
        return False

    if spider_name not in list_spiders():
        logger.error(f"爬虫 '{spider_name}' 不存在")
        logger.info(f"可用的爬虫: {', '.join(list_spiders())}")
        return False

    try:
        spider = get_spider(spider_name)
        logger.info(f"开始运行爬虫: {spider_name}")
        set_tag("spider_name", spider_name)

        # 架构 A（排行榜）：自带 supabase client，无参 run()
        # 架构 B（SpiderBase）：需传入 fetcher + writer
        if isinstance(spider, BaseRankingsSpider):
            result = await spider.run()
        else:
            result = await spider.run(Fetcher(), Writer())

        logger.info(
            f"爬虫 {spider_name} 运行完成: "
            f"success={result.success} fetched={result.items_fetched} "
            f"written={result.items_written}"
        )
        return result.success

    except Exception as e:
        logger.exception(f"运行爬虫 {spider_name} 时出错: {e}")
        report_spider_error(spider_name, e)
        return False


async def run_all_spiders():
    """运行所有已注册的爬虫（一次性）"""
    logger = logging.getLogger(__name__)

    try:
        from spiders.registry import get_spider, list_spiders
        from core.fetcher import Fetcher
        from core.writer import Writer
        from spiders.rankings_base import BaseRankingsSpider
    except ImportError as e:
        logger.error(f"导入爬虫注册表失败: {e}")
        return False

    names = list_spiders()
    logger.info(f"开始运行所有爬虫: {', '.join(names)}")

    success = 0
    for name in names:
        try:
            spider = get_spider(name)
            if isinstance(spider, BaseRankingsSpider):
                result = await spider.run()
            else:
                result = await spider.run(Fetcher(), Writer())
            if result.success:
                success += 1
            else:
                logger.error(f"爬虫 {name} 失败: {result.errors}")
        except Exception as e:
            logger.exception(f"爬虫 {name} 异常: {e}")

    logger.info(f"所有爬虫运行完成: 成功 {success}/{len(names)}")
    return success == len(names)


async def start_scheduler():
    """启动调度器（持续运行）

    统一走 spiders/registry + schedulers/jobs.build_scheduler
    （与 run-crawler-daily 生产调度器同一套，不再使用老的
    core.factory 注册表 / schedulers.scheduler）。
    """
    logger = logging.getLogger(__name__)

    logger.info("=" * 60)
    logger.info("DaCong Spider 调度器启动")
    logger.info("=" * 60)

    try:
        # 基于新注册表构建调度器（按 config.SPIDERS 配置注册定时任务）
        scheduler = build_scheduler()
        if not scheduler.get_jobs():
            logger.error("没有注册任何调度任务，请检查 config.SPIDERS 配置")
            return

        logger.info(f"已注册 {len(scheduler.get_jobs())} 个调度任务")
        scheduler.start()
        logger.info("调度器已启动，按 Ctrl+C 退出")

        # 保持运行
        try:
            while True:
                await asyncio.sleep(3600)  # 每小时检查一次
        except (KeyboardInterrupt, SystemExit):
            logger.info("收到中断信号，正在关闭...")

    except Exception as e:
        logger.exception(f"调度器异常: {e}")
        sys.exit(1)
    finally:
        logger.info("系统已关闭")


def parse_args():
    """解析命令行参数"""
    parser = argparse.ArgumentParser(
        description="DaCong Spider - AI 模型数据爬虫系统",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  # 启动调度器（默认）
  python main.py

  # 运行单个爬虫
  python main.py --spider github

  # 运行所有爬虫（一次性）
  python main.py --all

  # 列出所有可用爬虫
  python main.py --list

  # 调试模式
  python main.py --debug
        """
    )

    parser.add_argument(
        "--spider", "-s",
        type=str,
        help="运行指定的爬虫（例如: github, huggingface, hackernews）"
    )

    parser.add_argument(
        "--all", "-a",
        action="store_true",
        help="运行所有启用的爬虫（一次性，不启动调度器）"
    )

    parser.add_argument(
        "--list", "-l",
        action="store_true",
        help="列出所有可用的爬虫"
    )

    parser.add_argument(
        "--debug", "-d",
        action="store_true",
        help="启用调试模式"
    )

    parser.add_argument(
        "--validate-config", "-v",
        action="store_true",
        help="验证配置文件"
    )

    return parser.parse_args()


async def list_spiders():
    """列出所有可用的爬虫"""
    from spiders.registry import list_spiders as reg_list

    names = reg_list()

    print("\n[Spider List]")
    print("=" * 60)

    for name in names:
        print(f"  {name}")

    print("=" * 60)
    print(f"Total: {len(names)} spiders\n")


def validate_config():
    """验证配置文件"""
    from config import config

    print("\n[Config Validation]")
    print("=" * 60)

    try:
        # 检查必需配置
        print(f"[OK] Supabase URL: {config.supabase_url[:30]}...")
        print(f"[OK] Supabase Key: {'*' * 20}")
        print(f"[OK] Log Level: {config.log_level}")
        print(f"[OK] Log File: {config.log_file}")

        # 检查可选配置
        if config.github_token:
            print(f"[OK] GitHub Token: configured")
        else:
            print(f"[WARN] GitHub Token: not configured (optional)")

        if config.openrouter_api_key:
            print(f"[OK] OpenRouter API Key: configured")
        else:
            print(f"[WARN] OpenRouter API Key: not configured (optional)")

        if config.reddit_client_id:
            print(f"[OK] Reddit API: configured")
        else:
            print(f"[WARN] Reddit API: not configured (optional)")

        print("=" * 60)
        print("[OK] Config validation passed\n")
        return True

    except Exception as e:
        print(f"[FAIL] Config validation failed: {e}\n")
        return False


async def main():
    """主函数"""
    args = parse_args()

    # 配置日志
    setup_logging(debug=args.debug)
    logger = logging.getLogger(__name__)

    # 配置 Sentry
    setup_sentry(debug=args.debug)

    try:
        # 验证配置
        if args.validate_config:
            success = validate_config()
            sys.exit(0 if success else 1)

        # 列出爬虫
        if args.list:
            await list_spiders()
            return

        # 运行单个爬虫
        if args.spider:
            success = await run_single_spider(args.spider)
            sys.exit(0 if success else 1)

        # 运行所有爬虫
        if args.all:
            success = await run_all_spiders()
            sys.exit(0 if success else 1)

        # 默认：启动调度器
        await start_scheduler()

    except KeyboardInterrupt:
        logger.info("收到中断信号，正在关闭...")
    except Exception as e:
        logger.exception(f"系统异常: {e}")
        capture_exception(e, level="fatal", extras={"context": "main"})
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
