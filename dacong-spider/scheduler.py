"""
AI 排行榜定时抓取调度器

功能：
- 定时执行排行榜数据抓取
- 支持 Cron 表达式
- 自动生成日志

用法:
    python scheduler.py              # 启动调度器（默认每6小时运行一次）
    python scheduler.py --interval 2  # 每2小时运行一次
    python scheduler.py --daily       # 每天早上8点运行
"""
import asyncio
import logging
import argparse
from datetime import datetime
from pathlib import Path

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.interval import IntervalTrigger
from apscheduler.triggers.cron import CronTrigger

# 导入主脚本的抓取函数
from run_all_rankings import run_lmarena, run_artificial_analysis

# 配置日志
LOG_DIR = Path(__file__).parent / "logs"
LOG_DIR.mkdir(exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(message)s",
    handlers=[
        logging.FileHandler(LOG_DIR / f"scheduler_{datetime.now().strftime('%Y%m')}.log"),
        logging.StreamHandler(),
    ],
)

logger = logging.getLogger(__name__)


async def fetch_all_rankings():
    """执行所有排行榜抓取任务"""
    logger.info("=" * 50)
    logger.info("🕐 定时任务开始执行")
    logger.info("=" * 50)

    try:
        # 执行 LMArena 抓取
        logger.info("▶ 正在抓取 LMArena...")
        lmarena_result = await run_lmarena(save_db=True)
        logger.info(f"   LMArena 结果: {lmarena_result}")

        # 执行 Artificial Analysis 抓取
        logger.info("▶ 正在抓取 Artificial Analysis...")
        aa_result = await run_artificial_analysis(save_db=True)
        logger.info(f"   Artificial Analysis 结果: {aa_result}")

        logger.info("✅ 定时任务完成")
        return True

    except Exception as e:
        logger.error(f"❌ 定时任务失败: {e}")
        return False


async def main():
    parser = argparse.ArgumentParser(description="AI 排行榜定时调度器")
    parser.add_argument(
        "--interval",
        type=int,
        default=6,
        help="运行间隔（小时），默认 6 小时"
    )
    parser.add_argument(
        "--daily",
        action="store_true",
        help="每天固定时间运行（早上8点）"
    )
    parser.add_argument(
        "--hour",
        type=int,
        default=8,
        help="每日运行的小时（默认 8，即早上8点）"
    )

    args = parser.parse_args()

    scheduler = AsyncIOScheduler()

    if args.daily:
        # 每日定时运行
        trigger = CronTrigger(hour=args.hour, minute=0)
        schedule_desc = f"每天 {args.hour}:00"
    else:
        # 间隔运行
        trigger = IntervalTrigger(hours=args.interval)
        schedule_desc = f"每 {args.interval} 小时"

    scheduler.add_job(
        fetch_all_rankings,
        trigger=trigger,
        id="rankings_fetch",
        name="AI 排行榜抓取任务",
        replace_existing=True,
    )

    scheduler.start()
    logger.info(f"🚀 调度器已启动 - {schedule_desc}")

    print("\n" + "=" * 50)
    print(f"🕐 AI 排行榜调度器已启动")
    print(f"📅 运行策略: {schedule_desc}")
    print(f"⏰ 首次执行: 立即")
    print("=" * 50)
    print("\n按 Ctrl+C 停止调度器")
    print("-" * 50)

    # 立即执行一次
    await fetch_all_rankings()

    # 保持调度器运行
    try:
        while True:
            await asyncio.sleep(3600)  # 每小时检查一次
    except (KeyboardInterrupt, asyncio.CancelledError):
        logger.info("🛑 调度器已停止")
        scheduler.shutdown()


if __name__ == "__main__":
    asyncio.run(main())