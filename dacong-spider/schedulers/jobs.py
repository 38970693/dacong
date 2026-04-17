"""
APScheduler 定时任务调度器
负责：加载 Spider 注册表 → 按配置注册定时任务 → 启动调度器

设计模式：
  - Strategy: 每个 Spider 是独立策略
  - Factory + Registry: SpiderFactory 管理 Spider 实例
  - Template Method: SpiderBase.run() 定义执行模板
"""
import asyncio
import logging
import sys
import os
from datetime import datetime, timezone
from pathlib import Path

# ── 确保项目根目录在 sys.path ──────────────────
PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.interval import IntervalTrigger
from apscheduler.triggers.cron import CronTrigger

from config import (
    SPIDERS, LOG_LEVEL, LOG_FILE, DEBUG_MODE,
)
from core.base import AsyncSpiderRunner
from spiders.registry import create_all_spiders, list_spiders, get_spider

# ── 日志配置 ─────────────────────────────────
def _setup_logging():
    log_format = (
        "%(asctime)s [%(levelname)s] %(name)s - %(message)s"
    )
    handlers = [logging.StreamHandler(sys.stdout)]
    if LOG_FILE:
        os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
        handlers.append(logging.FileHandler(LOG_FILE, encoding="utf-8"))

    logging.basicConfig(
        level=getattr(logging, LOG_LEVEL),
        format=log_format,
        handlers=handlers,
    )


# ── 任务函数 ─────────────────────────────────
async def _run_spider_task(spider_name: str):
    """调度器触发单个 Spider 任务"""
    logger = logging.getLogger("Scheduler")
    logger.info(f"⏰ 触发 Spider: {spider_name}")

    spider = get_spider(spider_name)
    runner = AsyncSpiderRunner(spiders=[spider], concurrency=1)
    results = await runner.run_all()

    for result in results:
        if not result.success:
            logger.error(f"   {result}")
        else:
            logger.info(f"   {result}")


async def _run_all_spiders_task():
    """调度器触发所有 Spider（每日全量运行）"""
    logger = logging.getLogger("Scheduler")
    logger.info("⏰ 触发全量 Spider 任务")

    spiders = create_all_spiders()
    if not spiders:
        logger.warning("没有已注册的 Spider，退出")
        return

    runner = AsyncSpiderRunner(spiders=spiders, concurrency=3)
    await runner.run_all()


# ── 调度器核心 ────────────────────────────────
def build_scheduler() -> AsyncIOScheduler:
    """
    从 SPIDERS 配置构建调度器
    配置格式（config.py）：
        SPIDERS = {
            "github": {"enabled": True, "interval_hours": 1},
            "huggingface": {"enabled": True, "interval_hours": 6},
            "hackernews": {"enabled": True, "interval_minutes": 15},
        }
    """
    scheduler = AsyncIOScheduler(timezone="UTC")
    logger = logging.getLogger("Scheduler")

    # ── 逐个注册 Spider ───────────────────────
    for name, cfg in SPIDERS.items():
        if not cfg.get("enabled", False):
            logger.info(f"[Scheduler] {name} 已禁用，跳过")
            continue

        spider_cls_exists = name in list_spiders()
        if not spider_cls_exists:
            logger.warning(f"[Scheduler] Spider '{name}' 未注册，跳过")
            continue

        interval_h = cfg.get("interval_hours", 1)
        interval_m = cfg.get("interval_minutes", 0)

        if interval_m > 0:
            trigger = IntervalTrigger(minutes=interval_m, timezone="UTC")
            interval_desc = f"每 {interval_m} 分钟"
        else:
            trigger = IntervalTrigger(hours=interval_h, timezone="UTC")
            interval_desc = f"每 {interval_h} 小时"

        scheduler.add_job(
            _run_spider_task,
            trigger=trigger,
            kwargs={"spider_name": name},
            id=f"spider_{name}",
            name=f"Spider: {name}",
            replace_existing=True,
            misfire_grace_time=600,
        )
        logger.info(f"[Scheduler] ✅ {name} 注册完成（{interval_desc}）")

    # ── 全量汇总任务：每天凌晨 3 点（UTC）─────────
    scheduler.add_job(
        _run_all_spiders_task,
        trigger=CronTrigger(hour=3, minute=0, timezone="UTC"),
        id="daily_full_run",
        name="每日全量汇总",
        replace_existing=True,
        misfire_grace_time=3600,
    )
    logger.info("[Scheduler] ✅ 每日全量汇总任务已注册（03:00 UTC）")

    return scheduler


# ── 入口 ────────────────────────────────────
def start():
    """
    主入口：配置日志 → 构建调度器 → 启动
    """
    _setup_logging()
    logger = logging.getLogger("Scheduler")

    now_utc = datetime.now(timezone.utc)
    logger.info("═══════════════════════════════════════════")
    logger.info(f"  DaCong Spider Scheduler 启动")
    logger.info(f"  时间: {now_utc.isoformat()} UTC")
    logger.info(f"  注册 Spider: {list_spiders()}")
    logger.info("═══════════════════════════════════════════")

    scheduler = build_scheduler()

    if not scheduler.get_jobs():
        logger.error("没有注册任何任务，请检查 SPIDERS 配置是否正确")
        return

    scheduler.start()
    logger.info("调度器已启动，Spider 将按配置频率执行...")
    logger.info("按 Ctrl+C 退出")

    try:
        asyncio.get_event_loop().run_forever()
    except (KeyboardInterrupt, SystemExit):
        logger.info("收到退出信号，正在关闭调度器...")
        scheduler.shutdown(wait=False)


if __name__ == "__main__":
    start()
