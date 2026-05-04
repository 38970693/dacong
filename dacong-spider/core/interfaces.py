"""
核心接口定义 - 依赖倒置原则 (DIP)

所有具体实现依赖这些抽象接口，而非具体类
这样可以轻松替换实现，提高可测试性
"""
from abc import ABC, abstractmethod
from typing import Any, Optional
from dataclasses import dataclass
from datetime import datetime
from enum import Enum


# ══════════════════════════════════════════════════════════
# 数据传输对象 (DTOs)
# ══════════════════════════════════════════════════════════

class MetricSource(str, Enum):
    """数据源枚举"""
    GITHUB = "github"
    HUGGINGFACE = "huggingface"
    OPENROUTER = "openrouter"
    REDDIT = "reddit"
    HACKERNEWS = "hackernews"
    LM_ARENA = "lm_arena"
    ARTIFICIAL_ANALYSIS = "artificial_analysis"
    AI_PING = "ai_ping"


class DataType(str, Enum):
    """数据类型枚举"""
    REPOSITORY = "repository"
    MODEL = "model"
    PRICING = "pricing"
    POST = "post"
    NEWS = "news"


@dataclass(frozen=True)
class RawData:
    """
    原始数据 DTO（不可变）
    遵循不可变原则，防止意外修改
    """
    source: MetricSource
    data_type: DataType
    source_id: str
    title: str
    description: str
    url: str
    metadata: dict[str, Any]
    raw_content: str
    content_hash: str
    fetched_at: datetime


@dataclass(frozen=True)
class SpiderResult:
    """爬虫执行结果 DTO"""
    spider_name: str
    success: bool
    items_fetched: int = 0
    items_written: int = 0
    errors: list[str] = None
    duration_seconds: float = 0.0

    def __post_init__(self):
        if self.errors is None:
            object.__setattr__(self, 'errors', [])


# ══════════════════════════════════════════════════════════
# 核心接口
# ══════════════════════════════════════════════════════════

class IHttpClient(ABC):
    """
    HTTP 客户端接口
    职责：发起 HTTP 请求，处理重试和超时
    """

    @abstractmethod
    async def get(self, url: str, headers: Optional[dict] = None) -> Optional[str]:
        """
        发起 GET 请求
        Returns: 响应文本，失败返回 None
        """
        pass

    @abstractmethod
    async def get_json(self, url: str, headers: Optional[dict] = None) -> Optional[dict]:
        """
        发起 GET 请求并解析 JSON
        Returns: JSON 对象，失败返回 None
        """
        pass

    @abstractmethod
    async def close(self):
        """关闭客户端，释放资源"""
        pass


class IDataParser(ABC):
    """
    数据解析器接口
    职责：将原始响应解析为结构化数据
    """

    @abstractmethod
    def parse(self, raw_response: str) -> list[dict[str, Any]]:
        """
        解析原始响应
        Returns: 解析后的数据列表
        """
        pass

    @abstractmethod
    def validate(self, data: dict[str, Any]) -> bool:
        """
        验证数据完整性
        Returns: 数据是否有效
        """
        pass


class IDataProcessor(ABC):
    """
    数据处理器接口
    职责：清洗、转换、标准化数据
    """

    @abstractmethod
    def process(self, raw_data: dict[str, Any]) -> Optional[RawData]:
        """
        处理单条原始数据
        Returns: 标准化的 RawData 对象，失败返回 None
        """
        pass

    @abstractmethod
    def generate_content_hash(self, data: dict[str, Any]) -> str:
        """
        生成内容哈希（用于去重）
        Returns: MD5 哈希值
        """
        pass


class IDataStorage(ABC):
    """
    数据存储接口
    职责：持久化数据到数据库
    """

    @abstractmethod
    async def save(self, data: RawData) -> bool:
        """
        保存单条数据（幂等操作）
        Returns: 是否成功
        """
        pass

    @abstractmethod
    async def save_batch(self, data_list: list[RawData]) -> int:
        """
        批量保存数据
        Returns: 成功保存的数量
        """
        pass

    @abstractmethod
    async def exists(self, source: MetricSource, source_id: str) -> bool:
        """
        检查数据是否已存在
        Returns: 是否存在
        """
        pass

    @abstractmethod
    async def get_content_hash(self, source: MetricSource, source_id: str) -> Optional[str]:
        """
        获取已存储数据的内容哈希
        Returns: 哈希值，不存在返回 None
        """
        pass


class IDeduplicator(ABC):
    """
    去重器接口
    职责：识别并过滤重复数据
    """

    @abstractmethod
    async def filter_duplicates(
        self,
        data_list: list[RawData],
        storage: IDataStorage
    ) -> list[RawData]:
        """
        过滤重复数据
        Returns: 去重后的数据列表
        """
        pass


class IRetryStrategy(ABC):
    """
    重试策略接口
    职责：定义失败重试的策略
    """

    @abstractmethod
    def should_retry(self, attempt: int, error: Exception) -> bool:
        """
        判断是否应该重试
        Returns: 是否重试
        """
        pass

    @abstractmethod
    def get_delay(self, attempt: int) -> float:
        """
        获取重试延迟时间（秒）
        Returns: 延迟秒数
        """
        pass


class ISpider(ABC):
    """
    爬虫接口
    职责：定义爬虫的核心行为
    """

    @property
    @abstractmethod
    def name(self) -> str:
        """爬虫名称"""
        pass

    @property
    @abstractmethod
    def source(self) -> MetricSource:
        """数据源"""
        pass

    @abstractmethod
    async def fetch(self) -> list[dict[str, Any]]:
        """
        抓取原始数据
        Returns: 原始数据列表
        """
        pass

    @abstractmethod
    async def run(self) -> SpiderResult:
        """
        执行完整的爬取流程
        Returns: 执行结果
        """
        pass


class IScheduler(ABC):
    """
    调度器接口
    职责：管理爬虫的定时执行
    """

    @abstractmethod
    def register_spider(self, spider: ISpider, interval_hours: int):
        """注册爬虫到调度器"""
        pass

    @abstractmethod
    async def start(self):
        """启动调度器"""
        pass

    @abstractmethod
    async def stop(self):
        """停止调度器"""
        pass


class ILogger(ABC):
    """
    日志记录器接口
    职责：记录爬虫运行日志
    """

    @abstractmethod
    def info(self, message: str):
        """记录信息日志"""
        pass

    @abstractmethod
    def warning(self, message: str):
        """记录警告日志"""
        pass

    @abstractmethod
    def error(self, message: str, exception: Optional[Exception] = None):
        """记录错误日志"""
        pass

    @abstractmethod
    async def log_spider_result(self, result: SpiderResult):
        """记录爬虫执行结果到数据库"""
        pass
