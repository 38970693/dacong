"""
主入口 - 启动爬虫系统

职责：初始化系统并启动调度器
"""
import argparse
import asyncio
import logging
import sys
from typing import Optional

from core.factory import create_default_registry
from core.sentry_config import init_sentry, set_tag, capture_exception, report_spider_error
from schedulers.scheduler import create_default_scheduler


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
            logging.FileHandler(config.log_file),
            logging.StreamHandler(sys.stdout)
        ]
    )


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
    """运行单个爬虫"""
    logger = logging.getLogger(__name__)

    try:
        # 创建爬虫注册表
        registry = create_default_registry()

        # 检查爬虫是否存在
        if spider_name not in registry.list_names():
            logger.error(f"爬虫 '{spider_name}' 不存在")
            logger.info(f"可用的爬虫: {', '.join(registry.list_names())}")
            return False

        # 获取爬虫实例
        spider = registry.get(spider_name)
        logger.info(f"开始运行爬虫: {spider_name}")

        # 设置爬虫标签
        set_tag("spider_name", spider_name)

        # 运行爬虫
        await spider.run()

        logger.info(f"爬虫 {spider_name} 运行完成")
        return True

    except Exception as e:
        logger.exception(f"运行爬虫 {spider_name} 时出错: {e}")
        report_spider_error(spider_name, e)
        return False
    finally:
        # 清理资源
        await registry.factory.cleanup()


async def run_all_spiders():
    """运行所有启用的爬虫（一次性）"""
    logger = logging.getLogger(__name__)

    try:
        # 创建爬虫注册表
        registry = create_default_registry()
        spiders = registry.list_names()

        logger.info(f"开始运行所有爬虫: {', '.join(spiders)}")

        # 并发运行所有爬虫
        tasks = [registry.get(name).run() for name in spiders]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        # 统计结果
        success_count = sum(1 for r in results if not isinstance(r, Exception))
        logger.info(f"所有爬虫运行完成: 成功 {success_count}/{len(spiders)}")

        return success_count == len(spiders)

    except Exception as e:
        logger.exception(f"运行所有爬虫时出错: {e}")
        return False
    finally:
        # 清理资源
        await registry.factory.cleanup()


async def start_scheduler():
    """启动调度器（持续运行）"""
    logger = logging.getLogger(__name__)

    logger.info("=" * 60)
    logger.info("DaCong Spider 调度器启动")
    logger.info("=" * 60)

    try:
        # 创建爬虫注册表
        registry = create_default_registry()
        logger.info(f"已注册爬虫: {', '.join(registry.list_names())}")

        # 创建调度器
        scheduler = create_default_scheduler(registry)
        logger.info(f"已配置 {len(scheduler.list_jobs())} 个调度任务")

        # 启动调度器
        await scheduler.start()

    except KeyboardInterrupt:
        logger.info("收到中断信号，正在关闭...")
    except Exception as e:
        logger.exception(f"调度器异常: {e}")
        sys.exit(1)
    finally:
        # 清理资源
        logger.info("正在清理资源...")
        await registry.factory.cleanup()
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
    from config import config

    registry = create_default_registry()
    spiders = registry.list_names()

    print("\n可用的爬虫:")
    print("=" * 60)

    for name in spiders:
        spider_config = config.get_spider_config(name)
        status = "✅ 启用" if spider_config.get("enabled", False) else "❌ 禁用"
        interval = spider_config.get("interval_hours", "N/A")
        print(f"  {name:20s} {status:10s} 间隔: {interval} 小时")

    print("=" * 60)
    print(f"总计: {len(spiders)} 个爬虫\n")

    await registry.factory.cleanup()


def validate_config():
    """验证配置文件"""
    from config import config

    print("\n配置验证:")
    print("=" * 60)

    try:
        # 检查必需配置
        print(f"✅ Supabase URL: {config.supabase_url[:30]}...")
        print(f"✅ Supabase Key: {'*' * 20}")
        print(f"✅ 日志级别: {config.log_level}")
        print(f"✅ 日志文件: {config.log_file}")

        # 检查可选配置
        if config.github_token:
            print(f"✅ GitHub Token: 已配置")
        else:
            print(f"⚠️  GitHub Token: 未配置（可选）")

        if config.openrouter_api_key:
            print(f"✅ OpenRouter API Key: 已配置")
        else:
            print(f"⚠️  OpenRouter API Key: 未配置（可选）")

        if config.reddit_client_id:
            print(f"✅ Reddit API: 已配置")
        else:
            print(f"⚠️  Reddit API: 未配置（可选）")

        print("=" * 60)
        print("✅ 配置验证通过\n")
        return True

    except Exception as e:
        print(f"❌ 配置验证失败: {e}\n")
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
