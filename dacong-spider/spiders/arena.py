"""
LMArena 排行榜爬虫

数据源: https://lmarena.ai
评估模型对话能力的社区投票排名
"""
import re
from typing import Optional

from spiders.rankings_base import BaseRankingsSpider


class ArenaSpider(BaseRankingsSpider):
    """LMArena 排行榜爬虫 - 社区投票盲测排名"""

    # 分类映射
    CATEGORY_MAPPING = {
        "general": "general",
        "coding": "coding",
        "math": "math",
        "vision": "vision",
        "en": "english",
        "zh": "chinese",
    }

    @property
    def name(self) -> str:
        return "LMArena Rankings"

    @property
    def source(self) -> str:
        return "lmarena"

    @property
    def table_name(self) -> str:
        return "arena_rankings"

    async def fetch(self) -> list[dict]:
        """从 LMArena 抓取排行数据"""
        # LMArena 的 API 端点（新版）
        url = "https://lmarena.ai/api/leaderboard"

        # 添加必需的请求头
        headers = {
            "Accept": "application/json",
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        }

        try:
            json_data = await self.http_client.get_json(url, headers=headers)
            if not json_data:
                return []

            items = []
            # 处理可能的响应格式
            data = json_data if isinstance(json_data, list) else json_data.get("data", json_data.get("rankings", []))

            for entry in data:
                model_name = entry.get("model", entry.get("name", ""))
                if not model_name:
                    continue

                # 提取公司名称
                company = self._extract_company(model_name)

                # 解析置信区间
                ci = entry.get("ci_95", entry.get("confidence_interval", entry.get("ci", "")))
                if isinstance(ci, (int, float)):
                    ci = f"±{ci}"

                # 解析投票数
                votes = entry.get("votes", entry.get("vote_count", 0))
                if isinstance(votes, str):
                    votes = self._parse_votes(votes)

                items.append({
                    "model_name": model_name,
                    "elo_score": entry.get("elo", entry.get("score", 0)),
                    "confidence_interval": ci,
                    "vote_count": votes,
                    "category": entry.get("category", "general"),
                    "company": company,
                })

            return items

        except Exception as e:
            self.logger.error(f"抓取失败: {e}")
            return []

    def _extract_company(self, model_name: str) -> str:
        """从模型名称中提取公司名"""
        # 常见模型前缀
        prefixes = [
            "gpt-4", "gpt-3.5", "claude-3", "claude-2", "claude",
            "gemini-", "gemini-2", "gemini-pro",
            "llama-", "llama3", "llama4",
            "mistral-", "mixtral-",
            "qwen-", "qwen2", "qwen2.5",
            "deepseek-", "deepseek-v3",
            "yi-", "yi-1.5",
            "command-r", "cohere-",
            "starling-", "lm-studio",
            "anthropic/", "openai/", "meta/", "google/",
        ]

        model_lower = model_name.lower()
        for prefix in prefixes:
            if model_lower.startswith(prefix):
                return prefix.rstrip("/-").replace("-", " ").title()

        return ""

    def _parse_votes(self, votes_str: str) -> int:
        """解析投票数字符串"""
        if isinstance(votes_str, int):
            return votes_str

        # 处理 K/M 后缀
        votes_str = str(votes_str).upper().strip()
        if votes_str.endswith("K"):
            return int(float(votes_str[:-1]) * 1000)
        if votes_str.endswith("M"):
            return int(float(votes_str[:-1]) * 1000000)

        return int(votes_str.replace(",", ""))