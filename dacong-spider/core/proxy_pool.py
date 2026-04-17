"""
代理池管理模块

职责：
- 管理代理列表
- 健康检查
- 自动切换失败代理
- 支持多种代理源
"""
import asyncio
import logging
import time
from dataclasses import dataclass, field
from typing import Optional
from datetime import datetime, timedelta

import httpx

logger = logging.getLogger(__name__)


@dataclass
class ProxyInfo:
    """代理信息"""
    url: str
    failed_count: int = 0
    last_check: Optional[datetime] = None
    last_success: Optional[datetime] = None
    avg_response_time: float = 0.0
    is_healthy: bool = True


class ProxyPool:
    """
    代理池管理器

    特性：
    - 自动健康检查
    - 失败代理自动降级
    - 响应时间统计
    - 支持代理轮询
    """

    def __init__(
        self,
        proxies: list[str] | None = None,
        max_failures: int = 3,
        health_check_interval: int = 300,
        health_check_url: str = "https://httpbin.org/ip"
    ):
        """
        初始化代理池

        Args:
            proxies: 代理列表 ["http://proxy1:port", "http://proxy2:port"]
            max_failures: 最大失败次数，超过后标记为不健康
            health_check_interval: 健康检查间隔（秒）
            health_check_url: 健康检查使用的 URL
        """
        self.proxies: dict[str, ProxyInfo] = {}
        self.max_failures = max_failures
        self.health_check_interval = health_check_interval
        self.health_check_url = health_check_url
        self._current_index = 0

        # 初始化代理列表
        if proxies:
            for proxy_url in proxies:
                self.add_proxy(proxy_url)

        logger.info(f"代理池初始化完成，共 {len(self.proxies)} 个代理")

    def add_proxy(self, proxy_url: str):
        """添加代理到池中"""
        if proxy_url not in self.proxies:
            self.proxies[proxy_url] = ProxyInfo(url=proxy_url)
            logger.info(f"添加代理: {proxy_url}")

    def remove_proxy(self, proxy_url: str):
        """从池中移除代理"""
        if proxy_url in self.proxies:
            del self.proxies[proxy_url]
            logger.info(f"移除代理: {proxy_url}")

    def get_proxy(self) -> Optional[str]:
        """
        获取可用代理（轮询策略）

        Returns:
            代理 URL，如果没有可用代理返回 None
        """
        if not self.proxies:
            return None

        # 获取健康的代理列表
        healthy_proxies = [
            proxy for proxy in self.proxies.values()
            if proxy.is_healthy
        ]

        if not healthy_proxies:
            logger.warning("没有健康的代理可用")
            return None

        # 轮询选择
        proxy = healthy_proxies[self._current_index % len(healthy_proxies)]
        self._current_index += 1

        return proxy.url

    def get_best_proxy(self) -> Optional[str]:
        """
        获取最佳代理（基于响应时间）

        Returns:
            响应时间最短的健康代理
        """
        healthy_proxies = [
            proxy for proxy in self.proxies.values()
            if proxy.is_healthy
        ]

        if not healthy_proxies:
            return None

        # 按响应时间排序，选择最快的
        best_proxy = min(
            healthy_proxies,
            key=lambda p: p.avg_response_time if p.avg_response_time > 0 else float('inf')
        )

        return best_proxy.url

    def mark_failed(self, proxy_url: str):
        """
        标记代理失败

        Args:
            proxy_url: 失败的代理 URL
        """
        if proxy_url not in self.proxies:
            return

        proxy = self.proxies[proxy_url]
        proxy.failed_count += 1

        logger.warning(
            f"代理失败 ({proxy.failed_count}/{self.max_failures}): {proxy_url}"
        )

        # 超过最大失败次数，标记为不健康
        if proxy.failed_count >= self.max_failures:
            proxy.is_healthy = False
            logger.error(f"代理已标记为不健康: {proxy_url}")

    def mark_success(self, proxy_url: str, response_time: float):
        """
        标记代理成功

        Args:
            proxy_url: 成功的代理 URL
            response_time: 响应时间（秒）
        """
        if proxy_url not in self.proxies:
            return

        proxy = self.proxies[proxy_url]
        proxy.failed_count = 0  # 重置失败计数
        proxy.last_success = datetime.now()

        # 更新平均响应时间（指数移动平均）
        if proxy.avg_response_time == 0:
            proxy.avg_response_time = response_time
        else:
            proxy.avg_response_time = 0.7 * proxy.avg_response_time + 0.3 * response_time

        logger.debug(
            f"代理成功 (响应时间: {response_time:.2f}s, "
            f"平均: {proxy.avg_response_time:.2f}s): {proxy_url}"
        )

    async def health_check(self):
        """
        健康检查所有代理

        对每个代理发起测试请求，更新健康状态
        """
        if not self.proxies:
            logger.info("代理池为空，跳过健康检查")
            return

        logger.info(f"开始健康检查，共 {len(self.proxies)} 个代理")

        tasks = [
            self._check_single_proxy(proxy_url)
            for proxy_url in self.proxies.keys()
        ]

        results = await asyncio.gather(*tasks, return_exceptions=True)

        # 统计结果
        healthy_count = sum(1 for r in results if r is True)
        logger.info(
            f"健康检查完成: {healthy_count}/{len(self.proxies)} 个代理健康"
        )

    async def _check_single_proxy(self, proxy_url: str) -> bool:
        """
        检查单个代理

        Args:
            proxy_url: 代理 URL

        Returns:
            是否健康
        """
        proxy = self.proxies[proxy_url]
        proxy.last_check = datetime.now()

        try:
            start_time = time.monotonic()

            async with httpx.AsyncClient(
                proxies={"http://": proxy_url, "https://": proxy_url},
                timeout=10.0
            ) as client:
                response = await client.get(self.health_check_url)

                if response.status_code == 200:
                    response_time = time.monotonic() - start_time
                    self.mark_success(proxy_url, response_time)

                    # 如果之前不健康，现在恢复了
                    if not proxy.is_healthy:
                        proxy.is_healthy = True
                        logger.info(f"代理已恢复健康: {proxy_url}")

                    return True
                else:
                    self.mark_failed(proxy_url)
                    return False

        except Exception as e:
            logger.debug(f"代理健康检查失败 {proxy_url}: {e}")
            self.mark_failed(proxy_url)
            return False

    async def start_health_check_loop(self):
        """
        启动健康检查循环（后台任务）
        """
        logger.info(
            f"启动代理健康检查循环，间隔 {self.health_check_interval} 秒"
        )

        while True:
            await self.health_check()
            await asyncio.sleep(self.health_check_interval)

    def get_stats(self) -> dict:
        """
        获取代理池统计信息

        Returns:
            统计数据字典
        """
        healthy_proxies = [p for p in self.proxies.values() if p.is_healthy]

        return {
            "total": len(self.proxies),
            "healthy": len(healthy_proxies),
            "unhealthy": len(self.proxies) - len(healthy_proxies),
            "avg_response_time": (
                sum(p.avg_response_time for p in healthy_proxies) / len(healthy_proxies)
                if healthy_proxies else 0
            ),
            "proxies": [
                {
                    "url": p.url,
                    "is_healthy": p.is_healthy,
                    "failed_count": p.failed_count,
                    "avg_response_time": p.avg_response_time,
                    "last_success": p.last_success.isoformat() if p.last_success else None
                }
                for p in self.proxies.values()
            ]
        }
