"""
核心接口的基础实现

遵循单一职责原则 (SRP)，每个类只负责一件事
"""
import asyncio
import hashlib
import json
import logging
from typing import Optional, Any
from datetime import datetime, timezone

import httpx

from core.interfaces import (
    IHttpClient, IDataProcessor, IDeduplicator, IRetryStrategy,
    IDataStorage, ILogger, RawData, MetricSource, SpiderResult
)
from config import REQUEST_TIMEOUT, MAX_RETRIES, RETRY_DELAY, USER_AGENT


# ══════════════════════════════════════════════════════════
# HTTP 客户端实现
# ══════════════════════════════════════════════════════════

class HttpClient(IHttpClient):
    """
    基于 httpx 的 HTTP 客户端实现
    职责：发起 HTTP 请求，处理超时和重定向
    """

    def __init__(
        self,
        timeout: int = REQUEST_TIMEOUT,
        user_agent: str = USER_AGENT,
        retry_strategy: Optional[IRetryStrategy] = None
    ):
        self.timeout = timeout
        self.user_agent = user_agent
        self.retry_strategy = retry_strategy or ExponentialBackoffRetry()
        self._client: Optional[httpx.AsyncClient] = None

    async def _get_client(self) -> httpx.AsyncClient:
        """懒加载客户端"""
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(
                timeout=httpx.Timeout(self.timeout),
                follow_redirects=True,
                headers={"User-Agent": self.user_agent},
                http2=True,
            )
        return self._client

    async def get(self, url: str, headers: Optional[dict] = None) -> Optional[str]:
        """发起 GET 请求，返回文本"""
        client = await self._get_client()
        merged_headers = {**client.headers, **(headers or {})}

        attempt = 0
        while True:
            try:
                response = await client.get(url, headers=merged_headers)

                # 处理 rate limit
                if response.status_code == 403:
                    retry_after = int(response.headers.get("Retry-After", 60))
                    logging.warning(f"Rate limited, waiting {retry_after}s: {url}")
                    await asyncio.sleep(retry_after)
                    attempt += 1
                    if not self.retry_strategy.should_retry(attempt, None):
                        return None
                    continue

                if response.status_code != 200:
                    logging.warning(f"HTTP {response.status_code}: {url}")
                    return None

                return response.text

            except (httpx.TimeoutException, httpx.ConnectError) as e:
                if not self.retry_strategy.should_retry(attempt, e):
                    logging.error(f"Request failed after retries: {url}")
                    return None

                delay = self.retry_strategy.get_delay(attempt)
                logging.warning(f"Retry {attempt + 1} after {delay}s: {url}")
                await asyncio.sleep(delay)
                attempt += 1

    async def get_json(self, url: str, headers: Optional[dict] = None) -> Optional[dict]:
        """发起 GET 请求，返回 JSON"""
        text = await self.get(url, headers)
        if text is None:
            return None

        try:
            return json.loads(text)
        except json.JSONDecodeError as e:
            logging.error(f"JSON decode error: {url}, {e}")
            return None

    async def close(self):
        """关闭客户端"""
        if self._client and not self._client.is_closed:
            await self._client.aclose()
            self._client = None


# ══════════════════════════════════════════════════════════
# 数据处理器基类
# ══════════════════════════════════════════════════════════

class BaseDataProcessor(IDataProcessor):
    """
    数据处理器基类
    提供通用的哈希生成和数据转换逻辑
    """

    def __init__(self, source: MetricSource, data_type: str):
        self.source = source
        self.data_type = data_type

    def generate_content_hash(self, data: dict[str, Any]) -> str:
        """生成内容哈希（MD5）"""
        content = json.dumps(data, sort_keys=True, ensure_ascii=False)
        return hashlib.md5(content.encode()).hexdigest()

    def process(self, raw_data: dict[str, Any]) -> Optional[RawData]:
        """
        处理原始数据，转换为 RawData DTO
        子类可以覆盖此方法实现自定义逻辑
        """
        try:
            source_id = self._extract_source_id(raw_data)
            title = self._extract_title(raw_data)
            description = self._extract_description(raw_data)
            url = self._extract_url(raw_data)
            metadata = self._extract_metadata(raw_data)

            return RawData(
                source=self.source,
                data_type=self.data_type,
                source_id=source_id,
                title=title,
                description=description,
                url=url,
                metadata=metadata,
                raw_content=json.dumps(raw_data, ensure_ascii=False),
                content_hash=self.generate_content_hash(raw_data),
                fetched_at=datetime.now(timezone.utc)
            )
        except Exception as e:
            logging.error(f"Failed to process data: {e}")
            return None

    # 子类需要实现的抽象方法
    def _extract_source_id(self, data: dict) -> str:
        """提取唯一标识"""
        raise NotImplementedError

    def _extract_title(self, data: dict) -> str:
        """提取标题"""
        raise NotImplementedError

    def _extract_description(self, data: dict) -> str:
        """提取描述"""
        raise NotImplementedError

    def _extract_url(self, data: dict) -> str:
        """提取 URL"""
        raise NotImplementedError

    def _extract_metadata(self, data: dict) -> dict:
        """提取元数据"""
        raise NotImplementedError


# ══════════════════════════════════════════════════════════
# 去重器实现
# ══════════════════════════════════════════════════════════

class ContentHashDeduplicator(IDeduplicator):
    """
    基于内容哈希的去重器
    职责：通过比对内容哈希识别重复数据
    """

    async def filter_duplicates(
        self,
        data_list: list[RawData],
        storage: IDataStorage
    ) -> list[RawData]:
        """
        过滤重复数据
        策略：
        1. 内存去重（同批次）
        2. 数据库去重（检查已存在的数据）
        3. 内容变化检测（哈希不同则更新）
        """
        # 1. 内存去重
        seen = set()
        unique_in_batch = []
        for data in data_list:
            key = f"{data.source}:{data.source_id}"
            if key not in seen:
                seen.add(key)
                unique_in_batch.append(data)

        # 2. 数据库去重
        final = []
        for data in unique_in_batch:
            existing_hash = await storage.get_content_hash(data.source, data.source_id)

            if existing_hash is None:
                # 不存在，添加
                final.append(data)
            elif existing_hash != data.content_hash:
                # 存在但内容变化，更新
                final.append(data)
            # else: 完全相同，跳过

        return final


# ══════════════════════════════════════════════════════════
# 重试策略实现
# ══════════════════════════════════════════════════════════

class ExponentialBackoffRetry(IRetryStrategy):
    """
    指数退避重试策略
    职责：定义重试次数和延迟时间
    """

    def __init__(self, max_retries: int = MAX_RETRIES, base_delay: float = RETRY_DELAY):
        self.max_retries = max_retries
        self.base_delay = base_delay

    def should_retry(self, attempt: int, error: Optional[Exception]) -> bool:
        """判断是否应该重试"""
        return attempt < self.max_retries

    def get_delay(self, attempt: int) -> float:
        """获取重试延迟（指数增长）"""
        return self.base_delay * (2 ** attempt)


class FixedDelayRetry(IRetryStrategy):
    """
    固定延迟重试策略
    职责：每次重试使用相同的延迟时间
    """

    def __init__(self, max_retries: int = MAX_RETRIES, delay: float = RETRY_DELAY):
        self.max_retries = max_retries
        self.delay = delay

    def should_retry(self, attempt: int, error: Optional[Exception]) -> bool:
        return attempt < self.max_retries

    def get_delay(self, attempt: int) -> float:
        return self.delay


# ══════════════════════════════════════════════════════════
# 日志记录器实现
# ══════════════════════════════════════════════════════════

class SpiderLogger(ILogger):
    """
    爬虫日志记录器
    职责：记录日志到文件和数据库
    """

    def __init__(self, name: str, storage: Optional[IDataStorage] = None):
        self.logger = logging.getLogger(name)
        self.storage = storage

    def info(self, message: str):
        self.logger.info(message)

    def warning(self, message: str):
        self.logger.warning(message)

    def error(self, message: str, exception: Optional[Exception] = None):
        if exception:
            self.logger.error(message, exc_info=exception)
        else:
            self.logger.error(message)

    async def log_spider_result(self, result: SpiderResult):
        """记录爬虫执行结果"""
        status = "✅ 成功" if result.success else "❌ 失败"
        self.info(
            f"{status} | {result.spider_name} | "
            f"抓取: {result.items_fetched} | 写入: {result.items_written} | "
            f"耗时: {result.duration_seconds:.2f}s"
        )

        if result.errors:
            for error in result.errors:
                self.error(f"错误: {error}")

        # 可选：写入数据库
        if self.storage:
            # TODO: 实现写入 spider_logs 表
            pass
