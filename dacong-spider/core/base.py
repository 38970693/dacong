"""
Spider 抽象基类 - Strategy 模式
所有具体 Spider 必须继承 SpiderBase，实现 do_fetch() + name 属性
调度器通过统一接口调用，不关心具体实现
"""
import asyncio
import logging
import time
from abc import ABC, abstractmethod
from typing import Optional

from core.fetcher import Fetcher
from core.writer import Writer
from models.metrics import SpiderResult


class SpiderBase(ABC):
    """
    Spider 抽象基类

    设计模式：
    - Strategy 策略模式：每个 Spider 是一个独立策略
    - Template Method：run() 定了执行模板，子类只需实现 do_fetch()
    """

    # ─── 必须由子类覆盖 ────────────────────────────────
    @property
    @abstractmethod
    def name(self) -> str:
        """Spider 名称，用于日志"""
        ...

    @property
    @abstractmethod
    async def do_fetch(self, fetcher: Fetcher, writer: Writer) -> SpiderResult:
        """
        执行爬取逻辑
        由子类实现，负责：
        - 调用 fetcher.get() 获取页面
        - 解析数据，构造 model metrics
        - 调用 writer 写入数据库
        返回 SpiderResult
        """
        ...

    # ─── 可选覆盖 ─────────────────────────────────────
    async def on_start(self):
        """爬取开始前的回调（如需初始化）"""
        pass

    async def on_end(self, result: SpiderResult):
        """爬取结束后的回调（如资源清理）"""
        pass

    @property
    def retry_delay(self) -> float:
        """爬取失败重试延迟（秒），子类可覆盖"""
        return 2.0

    # ─── 模板方法（无需子类覆盖）────────────────────────
    async def run(self, fetcher: Fetcher, writer: Writer) -> SpiderResult:
        """
        Spider 执行模板（Template Method Pattern）
        固定流程：on_start → do_fetch → on_end → 返回结果
        """
        logger = logging.getLogger(self.name)
        start_time = time.monotonic()

        logger.info(f"🚀 {self.name} 开始执行")

        try:
            await self.on_start()
            result = await self.do_fetch(fetcher, writer)
            await self.on_end(result)
        except Exception as e:
            logger.exception(f"💥 {self.name} 执行异常: {e}")
            result = SpiderResult(
                spider_name=self.name,
                success=False,
                errors=[str(e)],
            )

        result.duration_seconds = time.monotonic() - start_time
        logger.info(str(result))
        return result


class AsyncSpiderRunner:
    """
    Spider 调度器 - 负责并发/串行执行多个 Spider
    支持：全部并发 / 按组顺序执行 / 单个 Spider
    """

    def __init__(self, spiders: list[SpiderBase], concurrency: int = 3):
        self.spiders = spiders
        self.concurrency = concurrency  # 并发数限制

    async def run_all(self) -> list[SpiderResult]:
        """
        并发执行所有 Spider（受 concurrency 限制）
        返回所有 Spider 的执行结果
        """
        logger = logging.getLogger("Runner")
        results: list[SpiderResult] = []

        # 分批并发执行
        for i in range(0, len(self.spiders), self.concurrency):
            batch = self.spiders[i:i + self.concurrency]
            tasks = [spider.run(Fetcher(), Writer()) for spider in batch]
            batch_results = await asyncio.gather(*tasks, return_exceptions=True)

            for sp, res in zip(batch, batch_results):
                if isinstance(res, Exception):
                    logger.exception(f"{sp.name} gather 异常: {res}")
                    results.append(SpiderResult(
                        spider_name=sp.name,
                        success=False,
                        errors=[str(res)],
                    ))
                else:
                    results.append(res)

            # 相邻批次之间短暂间隔，避免瞬间并发过大
            if i + self.concurrency < len(self.spiders):
                await asyncio.sleep(1)

        success_count = sum(1 for r in results if r.success)
        logger.info(
            f"═══ Spider Runner 完成 ═══ "
            f"成功 {success_count}/{len(results)} 个"
        )
        return results

    async def run_one(self, spider: SpiderBase) -> SpiderResult:
        """单独执行一个 Spider"""
        return await spider.run(Fetcher(), Writer())
