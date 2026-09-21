"""
数据模型 - 定义 Spider 系统的核心数据结构
采用 dataclass 简化对象创建，便于类型提示和序列化
"""
from dataclasses import dataclass, field, asdict
from datetime import datetime, timezone
from typing import Optional
from enum import Enum


class MetricSource(Enum):
    """数据来源枚举"""
    GITHUB = "github"
    HUGGINGFACE = "huggingface"
    HACKERNEWS = "hackernews"


class MetricType(Enum):
    """指标类型枚举"""
    GITHUB_TRENDING = "github_trending"
    HF_TEXT_GENERATION = "hf_text-generation"
    HF_TEXT_TO_IMAGE = "hf_text-to-image"
    HF_IMAGE_TO_TEXT = "hf_image-to-text"
    HF_AUTOMATIC_SPEECH_RECOGNITION = "hf_automatic-speech-recognition"
    HF_TEXT_TO_SPEECH = "hf_text-to-speech"
    HF_FEATURE_EXTRACTION = "hf_feature-extraction"
    HF_FILL_MASK = "hf_fill-mask"
    HN_AI_NEWS = "hn_ai_news"


@dataclass
class RawMetric:
    """
    单条原始指标数据
    由各 Spider 爬取后生成，交由 Writer 写入数据库
    """
    model_id: str
    source: MetricSource
    metric_type: MetricType
    metric_value: dict
    fetched_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def to_dict(self) -> dict:
        """转为字典，用于 Supabase upsert"""
        return {
            "model_id": self.model_id,
            "source": self.source.value,
            "metric_type": self.metric_type.value,
            "metric_value": self.metric_value,
            "fetched_at": self.fetched_at.isoformat(),
        }


@dataclass
class RepositoryMetric:
    """
    仓库指标数据（GitHub Trending repo）
    """
    full_name: str          # "owner/repo"
    description: str
    language: str
    stars_today: int
    total_stars: int
    forks: int
    url: str
    fetched_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def to_dict(self) -> dict:
        # 注意：字段名必须匹配 repository_metrics 表实际列名
        # （历史 bug：曾输出 full_name/url/total_stars，导致写入被 except 吞掉）
        owner = self.full_name.split("/")[0] if "/" in self.full_name else ""
        return {
            "repo_name": self.full_name,
            "repo_url": self.url,
            "stars": self.total_stars,
            "forks": self.forks,
            "language": self.language,
            "description": self.description,
            "author": owner,
            "source": "github",
            "fetched_at": self.fetched_at.isoformat(),
        }


@dataclass
class HotNewsItem:
    """
    快讯条目（HackerNews / ProductHunt 等）
    """
    source: str             # "HN" / "PH"
    title: str
    url: str
    summary: str = ""
    author: str = ""
    score: int = 0
    fetched_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def to_dict(self) -> dict:
        return {
            "source": self.source,
            "title": self.title,
            "url": self.url,
            "summary": self.summary,
            "author": self.author,
            "score": self.score,
            "fetched_at": self.fetched_at.isoformat(),
        }


@dataclass
class SpiderResult:
    """
    Spider 执行结果（供调度器日志汇总）
    """
    spider_name: str
    success: bool
    items_fetched: int = 0
    items_written: int = 0
    errors: list = field(default_factory=list)
    duration_seconds: float = 0.0

    def __str__(self) -> str:
        status = "✅" if self.success else "❌"
        return (f"{status} [{self.spider_name}] "
                f"获取 {self.items_fetched} 条 / "
                f"写入 {self.items_written} 条 / "
                f"耗时 {self.duration_seconds:.2f}s"
                + (f" | 错误: {', '.join(self.errors)}" if self.errors else ""))
