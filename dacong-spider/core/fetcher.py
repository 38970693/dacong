"""
HTTP 请求封装 - Fetcher
职责：统一发起 HTTP 请求，处理重试、超时、UA 伪装
不对 HTML 做解析，只负责获取响应
"""
import asyncio
import logging
from typing import Optional

import httpx

from config import REQUEST_TIMEOUT, MAX_RETRIES, RETRY_DELAY, USER_AGENT

logger = logging.getLogger(__name__)


class Fetcher:
    """
    异步 HTTP 客户端
    封装重试逻辑、超时控制、UA 设置
    """

    def __init__(self):
        self._client: Optional[httpx.AsyncClient] = None

    async def _get_client(self) -> httpx.AsyncClient:
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(
                timeout=httpx.Timeout(REQUEST_TIMEOUT),
                follow_redirects=True,
                headers={"User-Agent": USER_AGENT},
                http2=True,
            )
        return self._client

    async def close(self):
        """关闭客户端，生命周期结束后必须调用"""
        if self._client and not self._client.is_closed:
            await self._client.aclose()
            self._client = None

    async def get(self, url: str, retries: int = MAX_RETRIES) -> Optional[httpx.Response]:
        """
        GET 请求，自动重试
        Returns: httpx.Response 或 None（重试耗尽后）
        """
        client = await self._get_client()

        for attempt in range(retries):
            try:
                response = await client.get(url)
                # GitHub API 有 rate limit，403 时 sleep 更久
                if response.status_code == 403:
                    wait_seconds = int(response.headers.get("Retry-After", 60))
                    logger.warning(
                        f"[Fetcher] 403 rate limited, waiting {wait_seconds}s "
                        f"(attempt {attempt + 1}/{retries}): {url}"
                    )
                    if attempt < retries - 1:
                        await asyncio.sleep(wait_seconds)
                        continue

                if response.status_code != 200:
                    logger.warning(
                        f"[Fetcher] HTTP {response.status_code} "
                        f"(attempt {attempt + 1}/{retries}): {url}"
                    )
                    if attempt < retries - 1:
                        await asyncio.sleep(RETRY_DELAY * (attempt + 1))
                        continue
                    return None

                logger.debug(f"[Fetcher] OK {response.status_code}: {url}")
                return response

            except (httpx.TimeoutException, httpx.ConnectError) as e:
                logger.warning(
                    f"[Fetcher] {type(e).__name__} "
                    f"(attempt {attempt + 1}/{retries}): {url}"
                )
                if attempt < retries - 1:
                    await asyncio.sleep(RETRY_DELAY * (attempt + 1))
                else:
                    logger.error(f"[Fetcher] 完全失败 {url}: {e}")
                    return None

        return None
