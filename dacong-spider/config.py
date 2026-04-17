"""
DaCong Spider - 全局配置

使用 Pydantic 进行配置验证和管理
"""
import os
from typing import Dict, List
from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class SpiderConfig(BaseSettings):
    """爬虫系统配置"""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore"
    )

    # ── Supabase ──────────────────────────────────
    supabase_url: str = Field(default="", description="Supabase 项目 URL")
    supabase_service_role_key: str = Field(default="", alias="SUPABASE_SERVICE_ROLE_KEY", description="Supabase Service Role Key")

    # ── GitHub API ──────────────────────────────────
    github_token: str = Field(default="", description="GitHub Personal Access Token")

    # ── Reddit API ──────────────────────────────────
    reddit_client_id: str = Field(default="", description="Reddit Client ID")
    reddit_client_secret: str = Field(default="", description="Reddit Client Secret")
    reddit_user_agent: str = Field(default="DaCong-Spider/1.0", description="Reddit User Agent")

    # ── OpenRouter API ──────────────────────────────
    openrouter_api_key: str = Field(default="", description="OpenRouter API Key")

    # ── Claude API ──────────────────────────────────
    anthropic_api_key: str = Field(default="", description="Anthropic API Key for content generation")

    # ── 爬虫开关 ──────────────────────────────────
    spider_github_enabled: bool = Field(default=True, description="启用 GitHub 爬虫")
    spider_huggingface_enabled: bool = Field(default=True, description="启用 HuggingFace 爬虫")
    spider_hackernews_enabled: bool = Field(default=True, description="启用 HackerNews 爬虫")
    spider_openrouter_enabled: bool = Field(default=True, description="启用 OpenRouter 爬虫")
    spider_reddit_enabled: bool = Field(default=True, description="启用 Reddit 爬虫")

    # ── 调度配置 ──────────────────────────────────
    github_interval_hours: int = Field(default=1, ge=1, description="GitHub 爬虫间隔（小时）")
    huggingface_interval_hours: int = Field(default=6, ge=1, description="HuggingFace 爬虫间隔（小时）")
    hackernews_interval_hours: int = Field(default=1, ge=1, description="HackerNews 爬虫间隔（小时）")
    openrouter_interval_hours: int = Field(default=24, ge=1, description="OpenRouter 爬虫间隔（小时）")
    reddit_interval_hours: int = Field(default=24, ge=1, description="Reddit 爬虫间隔（小时）")

    # ── HTTP 配置 ──────────────────────────────────
    request_timeout: int = Field(default=30, ge=1, description="HTTP 请求超时（秒）")
    max_retries: int = Field(default=3, ge=0, description="最大重试次数")
    retry_delay: int = Field(default=5, ge=1, description="重试间隔（秒）")
    user_agent: str = Field(
        default="Mozilla/5.0 (compatible; DaCong-Spider/1.0; +https://dacong.example.com/bot)",
        description="User Agent"
    )

    # ── 代理配置 ──────────────────────────────────
    http_proxy: str = Field(default="", description="HTTP 代理")
    https_proxy: str = Field(default="", description="HTTPS 代理")

    # ── 日志配置 ──────────────────────────────────
    log_level: str = Field(default="INFO", description="日志级别")
    log_file: str = Field(default="logs/dacong_spider.log", description="日志文件路径")
    spider_debug: bool = Field(default=False, description="调试模式")

    # ── 数据库配置 ──────────────────────────────────
    batch_size: int = Field(default=100, ge=1, description="批量写入大小")

    @field_validator("supabase_url")
    @classmethod
    def validate_supabase_url(cls, v: str) -> str:
        """验证 Supabase URL"""
        if not v:
            raise ValueError("SUPABASE_URL 不能为空")
        if not v.startswith("https://"):
            raise ValueError("SUPABASE_URL 必须以 https:// 开头")
        return v

    @field_validator("supabase_service_role_key")
    @classmethod
    def validate_supabase_key(cls, v: str) -> str:
        """验证 Supabase Service Role Key"""
        if not v:
            raise ValueError("SUPABASE_SERVICE_ROLE_KEY 不能为空")
        return v

    @field_validator("log_level")
    @classmethod
    def validate_log_level(cls, v: str) -> str:
        """验证日志级别"""
        valid_levels = ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
        v_upper = v.upper()
        if v_upper not in valid_levels:
            raise ValueError(f"LOG_LEVEL 必须是以下之一: {', '.join(valid_levels)}")
        return v_upper

    def get_spider_config(self, spider_name: str) -> Dict[str, any]:
        """获取指定爬虫的配置"""
        config_map = {
            "github": {
                "enabled": self.spider_github_enabled,
                "interval_hours": self.github_interval_hours,
                "token": self.github_token
            },
            "huggingface": {
                "enabled": self.spider_huggingface_enabled,
                "interval_hours": self.huggingface_interval_hours
            },
            "hackernews": {
                "enabled": self.spider_hackernews_enabled,
                "interval_hours": self.hackernews_interval_hours
            },
            "openrouter": {
                "enabled": self.spider_openrouter_enabled,
                "interval_hours": self.openrouter_interval_hours,
                "api_key": self.openrouter_api_key
            },
            "reddit": {
                "enabled": self.spider_reddit_enabled,
                "interval_hours": self.reddit_interval_hours,
                "client_id": self.reddit_client_id,
                "client_secret": self.reddit_client_secret,
                "user_agent": self.reddit_user_agent
            }
        }
        return config_map.get(spider_name, {"enabled": False})

    def get_proxies(self) -> Dict[str, str] | None:
        """获取代理配置"""
        if self.http_proxy or self.https_proxy:
            return {
                "http": self.http_proxy,
                "https": self.https_proxy
            }
        return None


# ── AI 关键词（供 GitHub/HuggingFace 过滤用）───
HUGGINGFACE_AI_KEYWORDS: List[str] = [
    "llm", "gpt", "bert", "transformer", "language model",
    "pytorch", "tensorflow", "jax",
    "diffusion", "stable diffusion", "midjourney",
    "langchain", "llama", "mistral", "chatgpt", "openai",
    "anthropic", "gemini", "embedding", "rag", "fine-tuning",
    "文心", "通义", "智谱", "混元", "盘古",
]


# ── 全局配置实例 ──────────────────────────────
try:
    config = SpiderConfig()
except Exception as e:
    print(f"配置加载失败: {e}")
    print("请检查 .env 文件是否存在并正确配置")
    raise


# ── 向后兼容的配置导出 ──────────────────────────────
SUPABASE_URL = config.supabase_url
SUPABASE_SERVICE_ROLE_KEY = config.supabase_service_role_key
DEBUG_MODE = config.spider_debug
REQUEST_TIMEOUT = config.request_timeout
MAX_RETRIES = config.max_retries
RETRY_DELAY = config.retry_delay
USER_AGENT = config.user_agent
LOG_LEVEL = config.log_level
LOG_FILE = config.log_file

# 爬虫配置（向后兼容）
SPIDERS = {
    "github": config.get_spider_config("github"),
    "huggingface": config.get_spider_config("huggingface"),
    "hackernews": config.get_spider_config("hackernews"),
    "openrouter": config.get_spider_config("openrouter"),
    "reddit": config.get_spider_config("reddit"),
}
