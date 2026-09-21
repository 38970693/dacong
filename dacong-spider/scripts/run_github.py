"""
GitHub Trending 爬虫独立运行脚本（新架构）

用法:
    python scripts/run_github.py
    python scripts/run_github.py --debug

说明：
    新架构通过 spiders.registry 获取爬虫实例，统一用
    spider.run(Fetcher(), Writer()) 执行；Fetcher 负责 HTTP 请求，
    Writer 负责写入 Supabase。不再需要 GitHub token 或 dry-run 开关
    （GitHub Trending 页面为公开页面，无需鉴权）。
"""
import asyncio
import argparse
import logging
import sys
from pathlib import Path

# 添加项目根目录到 Python 路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from spiders.registry import get_spider
from core.fetcher import Fetcher
from core.writer import Writer


def setup_logging(level: str = "INFO"):
    """配置日志"""
    logging.basicConfig(
        level=getattr(logging, level.upper()),
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S"
    )


def parse_args():
    """解析命令行参数"""
    parser = argparse.ArgumentParser(
        description="运行 GitHub Trending 爬虫",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  # 使用默认配置运行
  python scripts/run_github.py

  # 调试模式
  python scripts/run_github.py --debug
        """
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="启用调试模式"
    )
    parser.add_argument(
        "--log-level",
        type=str,
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        default="INFO",
        help="日志级别"
    )
    return parser.parse_args()


async def run_spider(debug: bool = False):
    """
    运行 GitHub Trending 爬虫
    """
    print("=" * 60)
    print("GitHub Trending 爬虫启动")
    print("=" * 60)

    spider = get_spider("github")

    try:
        print("\n🚀 开始爬取...")
        print("-" * 60)

        result = await spider.run(Fetcher(), Writer())

        print("-" * 60)
        print("\n📊 执行结果:")
        print(f"   状态: {'✅ 成功' if result.success else '❌ 失败'}")
        print(f"   抓取数据: {result.items_fetched} 条")
        print(f"   写入数据: {result.items_written} 条")
        print(f"   耗时: {result.duration_seconds:.2f} 秒")

        if result.errors:
            print(f"\n⚠️  错误信息:")
            for error in result.errors:
                print(f"   - {error}")

        print("\n" + "=" * 60)
        print("✅ 爬虫执行完成")
        print("=" * 60)

        return result

    except KeyboardInterrupt:
        print("\n\n⚠️  用户中断")
        return None
    except Exception as e:
        print(f"\n\n❌ 执行失败: {e}")
        if debug:
            import traceback
            traceback.print_exc()
        return None


def main():
    """主函数"""
    args = parse_args()
    setup_logging("DEBUG" if args.debug else args.log_level)

    result = asyncio.run(run_spider(debug=args.debug))

    if result and result.success:
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
