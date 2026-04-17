"""
具体爬虫实现 - GitHub

职责：抓取 GitHub Trending 和 API 数据
"""
import os
from typing import Optional

from core.spider_base import ApiSpider
from core.interfaces import MetricSource, IDataProcessor
from config import HUGGINGFACE_AI_KEYWORDS


class GitHubSpider(ApiSpider):
    """
    GitHub 爬虫

    数据源：
    1. GitHub REST API - 搜索 AI 相关仓库
    2. GitHub Trending - 热门仓库

    策略：
    - 优先使用 API（有 rate limit）
    - API 失败时降级到 HTML 解析
    """

    def __init__(self, *args, api_token: Optional[str] = None, **kwargs):
        super().__init__(*args, **kwargs)
        self.api_token = api_token or os.getenv("GITHUB_TOKEN")

    @property
    def name(self) -> str:
        return "GitHub Spider"

    @property
    def source(self) -> MetricSource:
        return MetricSource.GITHUB

    @property
    def api_base_url(self) -> str:
        return "https://api.github.com"

    def get_headers(self) -> dict:
        """添加 GitHub API 认证"""
        headers = super().get_headers()
        if self.api_token:
            headers["Authorization"] = f"token {self.api_token}"
        return headers

    async def fetch(self) -> list[dict]:
        """
        抓取 GitHub 数据

        策略：
        1. 搜索 AI 相关主题的仓库
        2. 按 stars 排序
        3. 获取至少 100 个仓库
        4. 处理分页和 API 限流
        """
        all_repos = []

        # AI 相关主题
        topics = [
            "artificial-intelligence",
            "machine-learning",
            "deep-learning",
            "llm",
            "transformer",
            "pytorch",
            "tensorflow"
        ]

        for topic in topics:
            self.logger.info(f"搜索主题: {topic}")
            repos = await self._search_repos_by_topic(topic, per_page=30)
            if repos:
                all_repos.extend(repos)
                self.logger.info(f"主题 {topic} 获取到 {len(repos)} 个仓库")

        # 去重（同一个仓库可能有多个主题）
        unique_repos = self._deduplicate_by_full_name(all_repos)

        self.logger.info(f"抓取到 {len(unique_repos)} 个唯一仓库")
        return unique_repos

    async def _search_repos_by_topic(
        self,
        topic: str,
        per_page: int = 30,
        max_pages: int = 2
    ) -> list[dict]:
        """
        按主题搜索仓库（支持分页）

        Args:
            topic: GitHub 主题
            per_page: 每页数量（最大 100）
            max_pages: 最大页数

        Returns:
            仓库列表
        """
        all_items = []

        for page in range(1, max_pages + 1):
            endpoint = (
                f"search/repositories"
                f"?q=topic:{topic}"
                f"&sort=stars"
                f"&order=desc"
                f"&per_page={per_page}"
                f"&page={page}"
            )

            data = await self.fetch_json(endpoint)

            if not data or "items" not in data:
                self.logger.warning(f"搜索主题 {topic} 第 {page} 页失败")
                break

            items = data["items"]
            if not items:
                break

            all_items.extend(items)
            self.logger.info(f"主题 {topic} 第 {page} 页获取到 {len(items)} 个仓库")

            # 检查是否还有更多数据
            total_count = data.get("total_count", 0)
            if len(all_items) >= total_count:
                break

        return all_items

    def _deduplicate_by_full_name(self, repos: list[dict]) -> list[dict]:
        """根据 full_name 去重"""
        seen = set()
        unique = []

        for repo in repos:
            full_name = repo.get("full_name")
            if full_name and full_name not in seen:
                seen.add(full_name)
                unique.append(repo)

        return unique


class GitHubDataProcessor(IDataProcessor):
    """
    GitHub 数据处理器

    职责：将 GitHub API 响应转换为标准化的 RawData
    """

    def __init__(self):
        from core.implementations import BaseDataProcessor
        from core.interfaces import DataType

        self.base = BaseDataProcessor(MetricSource.GITHUB, DataType.REPOSITORY)

        # 绑定提取方法到 base
        self.base._extract_source_id = self._extract_source_id
        self.base._extract_title = self._extract_title
        self.base._extract_description = self._extract_description
        self.base._extract_url = self._extract_url
        self.base._extract_metadata = self._extract_metadata

    def process(self, raw_data: dict):
        """处理 GitHub 仓库数据"""
        # 数据验证
        if not self._validate_data(raw_data):
            return None
        return self.base.process(raw_data)

    def generate_content_hash(self, data: dict) -> str:
        return self.base.generate_content_hash(data)

    def _validate_data(self, data: dict) -> bool:
        """验证数据完整性"""
        required_fields = ["full_name", "name", "html_url"]
        for field in required_fields:
            if field not in data:
                return False
        return True

    def _extract_source_id(self, data: dict) -> str:
        """提取唯一标识：owner/repo"""
        return data["full_name"]

    def _extract_title(self, data: dict) -> str:
        """提取标题：仓库名"""
        return data["name"]

    def _extract_description(self, data: dict) -> str:
        """提取描述"""
        return data.get("description") or ""

    def _extract_url(self, data: dict) -> str:
        """提取 URL"""
        return data["html_url"]

    def _extract_metadata(self, data: dict) -> dict:
        """提取元数据"""
        return {
            "stars": data.get("stargazers_count", 0),
            "forks": data.get("forks_count", 0),
            "language": data.get("language"),
            "topics": data.get("topics", []),
            "created_at": data.get("created_at"),
            "updated_at": data.get("updated_at"),
            "owner": data.get("owner", {}).get("login") if data.get("owner") else None,
            "is_fork": data.get("fork", False),
            "open_issues": data.get("open_issues_count", 0),
            "watchers": data.get("watchers_count", 0),
            "default_branch": data.get("default_branch", "main"),
            "license": data.get("license", {}).get("name") if data.get("license") else None
        }
