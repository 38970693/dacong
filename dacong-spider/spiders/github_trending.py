"""
GitHub Trending Spider
策略：解析 https://github.com/trending 页面
数据输出：
  - AI 相关仓库 → model_raw_metrics（作为模型数据）
  - 所有语言仓库 → repository_metrics
"""
import asyncio
import logging
import re
from datetime import datetime, timezone

import httpx
from bs4 import BeautifulSoup

from config import SPIDERS, HUGGINGFACE_AI_KEYWORDS, REQUEST_TIMEOUT, USER_AGENT
from core.base import SpiderBase
from core.fetcher import Fetcher
from core.writer import Writer
from models.metrics import (
    MetricSource, MetricType, RawMetric,
    RepositoryMetric, SpiderResult,
)

logger = logging.getLogger(__name__)

# AI 相关关键词（用于过滤 GitHub Trending）
AI_KEYWORDS = HUGGINGFACE_AI_KEYWORDS

# GitHub REST API（用于补全精确 stargazers_count）
GITHUB_API_BASE = "https://api.github.com"
# 带 token 时限额 5000 次/小时，两次请求之间的礼貌间隔
GITHUB_API_DELAY = 0.1


# ── rising stars 评分（纯函数）─────────────────────────────
# 说明：这是 M1 飙升榜评分的参考实现，与 Supabase Edge Function
# `compute-rising-stars` 中的 TS 版本保持一致，改动需同步两边。

def compute_velocity(points: list[tuple[float, int]]) -> float:
    """
    对 (天数, 累计 star 数) 序列做最小二乘线性拟合，返回斜率（stars/day）。
    不足 2 个点或 x 无变化时返回 0.0。
    """
    n = len(points)
    if n < 2:
        return 0.0

    sum_x = sum(x for x, _ in points)
    sum_y = sum(y for _, y in points)
    sum_xy = sum(x * y for x, y in points)
    sum_xx = sum(x * x for x, _ in points)

    denominator = n * sum_xx - sum_x * sum_x
    if denominator == 0:
        return 0.0

    return (n * sum_xy - sum_x * sum_y) / denominator


def compute_rank_score(stars_1d: int, stars_7d: int, velocity: float) -> float:
    """综合排序分：0.5*stars_7d + 0.3*velocity + 0.2*stars_1d"""
    return 0.5 * stars_7d + 0.3 * velocity + 0.2 * stars_1d


class GitHubTrendingSpider(SpiderBase):
    """
    GitHub Trending Spider
    爬取 github.com/trending 页面，支持按语言过滤
    """

    @property
    def name(self) -> str:
        return "GitHub Trending"

    @property
    def retry_delay(self) -> float:
        return 3.0

    @property
    def languages(self) -> list[str]:
        """爬取的语言列表"""
        return SPIDERS.get("github", {}).get("languages",
            ["python", "typescript", "javascript", "go", "rust", "java"]
        )

    def _is_ai_repo(self, description: str, language: str) -> bool:
        """判断是否为 AI 相关仓库"""
        desc_lower = description.lower()
        lang_lower = language.lower()

        # 明确的 AI 相关语言/领域
        ai_indicators = [
            "python", "llm", "gpt", "bert", "transformer",
            "pytorch", "tensorflow", "jax", "diffusion",
            "stable-diffusion", "langchain", "llam", "mistral",
            "chatgpt", "openai", "anthropic", "gemini",
            "huggingface", "rag", "embedding", "fine-tuning",
        ]
        if any(ind in desc_lower for ind in ai_indicators):
            return True
        if lang_lower in ["python", "jupyter notebook"]:
            # Python 仓库更可能是 AI
            return any(kw in desc_lower for kw in AI_KEYWORDS)

        return False

    def _parse_trending_page(self, html: str, language: str = "all") -> tuple[list[dict], list[dict]]:
        """
        解析 Trending 页面 HTML
        Returns: (ai_repos, all_repos)
        """
        soup = BeautifulSoup(html, "lxml")
        articles = soup.select("article.Box-row")

        ai_metrics: list[dict] = []
        all_repos: list[dict] = []

        for article in articles:
            # 仓库名：owner/repo
            a_tag = article.select_one("h2 a")
            if not a_tag:
                continue
            href: str = a_tag.get("href", "")
            full_name = href.lstrip("/")  # "owner/repo"
            if "/" not in full_name:
                continue

            # 描述
            desc_tag = article.select_one("p")
            description: str = desc_tag.get_text(strip=True) if desc_tag else ""

            # 编程语言
            lang_tag = article.select_one("span[itemprop='programmingLanguage']")
            lang = lang_tag.get_text(strip=True) if lang_tag else ""

            # 星标（今日）
            star_text = article.select_one("a[href$='/stargazers']")
            if not star_text:
                star_text = article.select_one("svg.octicon-star + *")
            stars_today_str = star_text.get_text(strip=True).replace(",", "") if star_text else "0"
            try:
                stars_today = self._parse_stars(stars_today_str)
            except ValueError:
                stars_today = 0

            # 总星标（从 meta 获取）
            meta_stars = article.select_one("meta[property='og:description']")
            total_stars = stars_today  # Trending 页面只有今日数据

            # Fork 数
            fork_text = article.select_one("a[href$='/members']")
            forks = 0
            if fork_text:
                fork_str = fork_text.get_text(strip=True).replace(",", "")
                try:
                    forks = self._parse_stars(fork_str)
                except ValueError:
                    pass

            url = f"https://github.com/{full_name}"
            owner = full_name.split("/")[0]
            repo = full_name.split("/")[1]

            repo_data = {
                "full_name": full_name,
                "description": description,
                "language": lang,
                "stars_today": stars_today,
                "total_stars": total_stars,
                "forks": forks,
                "url": url,
                "owner": owner,
                "repo": repo,
            }

            # AI 相关 → model_raw_metrics
            if self._is_ai_repo(description, lang):
                ai_metrics.append(repo_data)

            # 全量 → repository_metrics
            all_repos.append(repo_data)

        return ai_metrics, all_repos

    def _parse_stars(self, text: str) -> int:
        """
        解析星标数字字符串：'1,234' → 1234, '2.3k' → 2300
        """
        text = text.strip().lower()
        if "," in text:
            text = text.replace(",", "")

        multipliers = {"k": 1000, "m": 1000000, "b": 1000000000}
        for suffix, mult in multipliers.items():
            if text.endswith(suffix):
                num = float(text[:-1])
                return int(num * mult)

        # 处理 'today' 等后缀
        text = re.sub(r"\s*(today|stars?)\s*", "", text, flags=re.IGNORECASE).strip()
        return int(float(text))

    async def _enrich_total_stars(self, repos: list[dict], cache: dict[str, int]) -> None:
        """
        用 GitHub API `GET /repos/{owner}/{repo}` 补全精确 stargazers_count，
        原地覆盖 repo["total_stars"]（Trending 页面只有今日增量，不是总星数）。

        未配置 GITHUB_TOKEN 时直接跳过：匿名限额仅 60 次/小时，
        一轮 Trending 就会耗尽，反而拖垮整个爬取流程。
        """
        token = SPIDERS.get("github", {}).get("token", "")
        if not token:
            logger.info("[GitHub] 未配置 GITHUB_TOKEN，跳过精确 star 数补全")
            return

        headers = {
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {token}",
            "User-Agent": USER_AGENT,
        }

        async with httpx.AsyncClient(
            timeout=httpx.Timeout(REQUEST_TIMEOUT), headers=headers
        ) as client:
            for repo in repos:
                full_name = repo["full_name"]

                if full_name in cache:
                    repo["total_stars"] = cache[full_name]
                    continue

                try:
                    resp = await client.get(f"{GITHUB_API_BASE}/repos/{full_name}")
                except httpx.HTTPError as e:
                    logger.warning(f"[GitHub] API 请求失败 {full_name}: {e}")
                    continue

                if resp.status_code != 200:
                    logger.warning(
                        f"[GitHub] API HTTP {resp.status_code} {full_name}，保留页面解析值"
                    )
                    # 限额耗尽时后续请求也会失败，直接放弃本批补全
                    if resp.status_code in (403, 429):
                        logger.warning("[GitHub] 触发 API 限额，停止本批 star 补全")
                        return
                    continue

                stars = resp.json().get("stargazers_count")
                if isinstance(stars, int):
                    cache[full_name] = stars
                    repo["total_stars"] = stars

                await asyncio.sleep(GITHUB_API_DELAY)

    async def do_fetch(self, fetcher: Fetcher, writer: Writer) -> SpiderResult:
        """
        执行 GitHub Trending 爬取
        流程：爬取各语言 Trending → 解析 → 写入数据库
        """
        errors: list[str] = []
        total_fetched = 0
        total_written = 0
        # 跨语言页面复用同一份 star 结果，避免重复调用 GitHub API
        stars_cache: dict[str, int] = {}

        # 1. 爬取消语言过滤的首页（AI 相关全量）
        base_url = "https://github.com/trending"

        resp = await fetcher.get(base_url)
        if not resp:
            errors.append(f"获取 {base_url} 失败")
            return SpiderResult(
                spider_name=self.name,
                success=False,
                errors=errors,
            )

        ai_repos, all_repos = self._parse_trending_page(resp.text)
        # ai_repos 与 all_repos 共享同一批 dict 对象，补全一次即可
        await self._enrich_total_stars(all_repos, stars_cache)
        total_fetched += len(ai_repos) + len(all_repos)
        logger.info(f"[GitHub] 全量 {len(all_repos)} 条，AI 相关 {len(ai_repos)} 条")

        # 2. 写入 AI 仓库（作为 model_raw_metrics）
        written = await self._write_ai_metrics(writer, ai_repos)
        total_written += written

        # 3. 写入所有仓库（repository_metrics）
        written = await self._write_repo_metrics(writer, all_repos)
        total_written += written

        # 4. 按语言分别爬取（增量数据）
        for lang in self.languages:
            url = f"https://github.com/trending/{lang}"
            resp = await fetcher.get(url)
            if not resp:
                errors.append(f"获取 {lang} 失败")
                await asyncio.sleep(self.retry_delay)
                continue

            ai_lang, all_lang = self._parse_trending_page(resp.text, lang)
            await self._enrich_total_stars(all_lang, stars_cache)
            total_fetched += len(ai_lang) + len(all_lang)

            written = await self._write_ai_metrics(writer, ai_lang)
            total_written += written
            written = await self._write_repo_metrics(writer, all_lang)
            total_written += written

            logger.info(f"[GitHub] 语言={lang}: AI {len(ai_lang)} 条，All {len(all_lang)} 条")
            await asyncio.sleep(1.5)  # 礼貌爬取

        return SpiderResult(
            spider_name=self.name,
            success=len(errors) == 0,
            items_fetched=total_fetched,
            items_written=total_written,
            errors=errors,
        )

    async def _write_ai_metrics(self, writer: Writer, repos: list[dict]) -> int:
        """将 AI 仓库写入 model_raw_metrics"""
        written = 0
        for repo in repos:
            # 确保模型存在
            model_id = writer.upsert_model(
                name=repo["repo"],
                vendor="GitHub",
                category="LLM/AI",
                description=repo["description"],
                website_url=repo["url"],
                tags=["github-trending", repo.get("language", "").lower()],
            )
            if not model_id:
                continue

            # 写入原始指标
            metric = RawMetric(
                model_id=model_id,
                source=MetricSource.GITHUB,
                metric_type=MetricType.GITHUB_TRENDING,
                metric_value={
                    "owner": repo["owner"],
                    "repo": repo["repo"],
                    "full_name": repo["full_name"],
                    "description": repo["description"],
                    "language": repo["language"],
                    "stars_today": repo["stars_today"],
                    "total_stars_raw": repo["total_stars"],
                    "forks": repo["forks"],
                    "url": repo["url"],
                },
            )

            if writer.upsert_model_metrics(metric):
                written += 1

        return written

    async def _write_repo_metrics(self, writer: Writer, repos: list[dict]) -> int:
        """将仓库写入 repository_metrics"""
        written = 0
        for repo in repos:
            repo_metric = RepositoryMetric(
                full_name=repo["full_name"],
                description=repo["description"],
                language=repo["language"],
                stars_today=repo["stars_today"],
                total_stars=repo["total_stars"],
                forks=repo["forks"],
                url=repo["url"],
            )
            if writer.upsert_repository_metrics(repo_metric):
                written += 1
        return written
