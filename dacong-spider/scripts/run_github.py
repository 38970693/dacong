"""
GitHub 爬虫独立运行脚本

用途：
1. 独立运行 GitHub 爬虫
2. 显示进度和统计信息
3. 支持命令行参数配置

使用方法：
    python scripts/run_github.py
    python scripts/run_github.py --token YOUR_TOKEN
    python scripts/run_github.py --dry-run
"""
import asyncio
import argparse
import logging
import sys
from pathlib import Path

# 添加项目根目录到 Python 路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from core.implementations import HttpClient, ContentHashDeduplicator, SpiderLogger
from core.storage import SupabaseStorage, InMemoryStorage
from spiders.github_spider import GitHubSpider, GitHubDataProcessor
from config import config


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
        description="运行 GitHub 爬虫",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  # 使用默认配置运行
  python scripts/run_github.py

  # 使用自定义 token
  python scripts/run_github.py --token ghp_xxxxx

  # 干运行模式（不写入数据库）
  python scripts/run_github.py --dry-run

  # 调试模式
  python scripts/run_github.py --debug
        """
    )

    parser.add_argument(
        "--token",
        type=str,
        default=None,
        help="GitHub Personal Access Token（默认从环境变量读取）"
    )

    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="干运行模式：只抓取数据，不写入数据库"
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


async def run_spider(
    api_token: str = None,
    dry_run: bool = False,
    debug: bool = False
):
    """
    运行 GitHub 爬虫

    Args:
        api_token: GitHub API token
        dry_run: 是否为干运行模式
        debug: 是否启用调试模式
    """
    print("=" * 60)
    print("GitHub 爬虫启动")
    print("=" * 60)

    # 创建组件
    http_client = HttpClient()
    processor = GitHubDataProcessor()
    deduplicator = ContentHashDeduplicator()

    # 选择存储方式
    if dry_run:
        print("📝 模式: 干运行（不写入数据库）")
        storage = InMemoryStorage()
    else:
        print("💾 模式: 正常运行（写入 Supabase）")
        try:
            storage = SupabaseStorage()
        except Exception as e:
            print(f"❌ Supabase 连接失败: {e}")
            print("💡 切换到内存存储模式")
            storage = InMemoryStorage()

    logger = SpiderLogger("github_spider")

    # 创建爬虫
    spider = GitHubSpider(
        http_client=http_client,
        data_processor=processor,
        storage=storage,
        deduplicator=deduplicator,
        logger=logger,
        api_token=api_token or config.github_token
    )

    try:
        print("\n🚀 开始爬取...")
        print("-" * 60)

        # 执行爬虫
        result = await spider.run()

        # 显示结果
        print("-" * 60)
        print("\n📊 执行结果:")
        print(f"   状态: {'✅ 成功' if result.success else '❌ 失败'}")
        print(f"   抓取数据: {result.items_fetched} 条")
        print(f"   写入数据: {result.items_written} 条")
        print(f"   去重率: {(1 - result.items_written / result.items_fetched) * 100:.1f}%" if result.items_fetched > 0 else "   去重率: N/A")
        print(f"   耗时: {result.duration_seconds:.2f} 秒")

        if result.errors:
            print(f"\n⚠️  错误信息:")
            for error in result.errors:
                print(f"   - {error}")

        # 如果是内存存储，显示数据样例
        if isinstance(storage, InMemoryStorage) and storage.count() > 0:
            print(f"\n📦 数据样例（共 {storage.count()} 条）:")
            for i, (key, data) in enumerate(list(storage.data.items())[:3]):
                print(f"\n   [{i+1}] {data.title}")
                print(f"       URL: {data.url}")
                print(f"       Stars: {data.metadata.get('stars', 0)}")
                print(f"       Language: {data.metadata.get('language', 'N/A')}")
                print(f"       Topics: {', '.join(data.metadata.get('topics', []))}")

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

    finally:
        await http_client.close()


def main():
    """主函数"""
    args = parse_args()

    # 配置日志
    log_level = "DEBUG" if args.debug else args.log_level
    setup_logging(log_level)

    # 运行爬虫
    result = asyncio.run(run_spider(
        api_token=args.token,
        dry_run=args.dry_run,
        debug=args.debug
    ))

    # 返回退出码
    if result and result.success:
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
