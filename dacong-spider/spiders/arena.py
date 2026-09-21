"""
LMArena 排行榜爬虫

数据源: https://lmarena.ai
评估模型对话能力的社区投票排名
"""
import re
from datetime import date
from typing import Optional

from spiders.rankings_base import BaseRankingsSpider

# 模型名前缀 -> 厂商（用于把 arena 的 model_name 落到 models 表）
VENDOR_PREFIXES = [
    ("chatgpt", "OpenAI"),
    ("gpt-", "OpenAI"),
    ("o1", "OpenAI"),
    ("o3", "OpenAI"),
    ("o4", "OpenAI"),
    ("claude", "Anthropic"),
    ("gemini", "Google"),
    ("gemma", "Google"),
    ("llama", "Meta"),
    ("mixtral", "Mistral AI"),
    ("mistral", "Mistral AI"),
    ("qwen", "Alibaba"),
    ("qwq", "Alibaba"),
    ("deepseek", "DeepSeek"),
    ("grok", "xAI"),
    ("command", "Cohere"),
    ("yi-", "01.AI"),
    ("chatglm", "Zhipu AI"),
    ("glm", "Zhipu AI"),
    ("kimi", "Moonshot AI"),
    ("moonshot", "Moonshot AI"),
    ("phi-", "Microsoft"),
    ("nova-", "Amazon"),
    ("hunyuan", "Tencent"),
    ("ernie", "Baidu"),
    ("minimax", "MiniMax"),
]

_CANONICAL_VENDORS = {vendor.lower(): vendor for _, vendor in VENDOR_PREFIXES}


def infer_vendor(model_name: str) -> str:
    """
    从 arena 的 model_name 推断厂商

    优先取名称末尾括号里的组织名（如 "claude-opus-4 (anthropic)"），
    否则按前缀匹配；都不中返回 "Unknown"。
    """
    name = (model_name or "").strip().lower()
    if not name:
        return "Unknown"

    org_match = re.search(r"\(([^()]+)\)\s*$", name)
    if org_match:
        org = org_match.group(1).strip()
        return _CANONICAL_VENDORS.get(org, org)

    for prefix, vendor in VENDOR_PREFIXES:
        if name.startswith(prefix):
            return vendor

    return "Unknown"


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

    BENCHMARK = "Arena-ELO"
    EVAL_CHUNK = 500

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

    async def save_to_table(self, items: list[dict]) -> int:
        """写 arena_rankings（基类行为），再把 ELO 落到统一评测表"""
        written = await super().save_to_table(items)
        self._save_evaluations(items)
        return written

    def _resolve_model_id(self, client, model_name: str, cache: dict) -> Optional[str]:
        """把 arena 的 model_name 映射到 models.id，缺失则按推断厂商新建"""
        if model_name in cache:
            return cache[model_name]

        vendor = infer_vendor(model_name)
        model_id = None
        try:
            existing = client.table("models").select("id").match({
                "name": model_name,
                "vendor": vendor,
            }).limit(1).execute()

            if existing.data:
                model_id = existing.data[0]["id"]
            else:
                created = client.table("models").insert({
                    "name": model_name,
                    "vendor": vendor,
                    "category": "LLM",
                }).execute()
                model_id = created.data[0]["id"] if created.data else None

        except Exception as e:
            self.logger.debug(f"models 映射失败 [{vendor}/{model_name}]: {e}")

        cache[model_name] = model_id
        return model_id

    def _save_evaluations(self, items: list[dict]) -> None:
        """ELO 以 benchmark='Arena-ELO' 写入 model_evaluations"""
        from supabase import create_client
        from config import SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY

        if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
            self.logger.error("缺少 Supabase 配置")
            return

        client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
        eval_date = date.today().isoformat()
        cache: dict[str, Optional[str]] = {}
        rows = []

        for item in items:
            elo = item.get("elo_score")
            if not elo:
                continue

            model_id = self._resolve_model_id(client, item["model_name"], cache)
            if not model_id:
                continue

            raw_category = item.get("category") or "general"
            rows.append({
                "model_id": model_id,
                "benchmark": self.BENCHMARK,
                "score": elo,
                "category": self.CATEGORY_MAPPING.get(raw_category, raw_category),
                "source": self.source,
                "eval_date": eval_date,
                "raw_data": {
                    "vote_count": item.get("vote_count"),
                    "confidence_interval": item.get("confidence_interval"),
                    "arena_category": raw_category,
                },
            })

        saved = 0
        for start in range(0, len(rows), self.EVAL_CHUNK):
            chunk = rows[start:start + self.EVAL_CHUNK]
            try:
                client.table("model_evaluations").upsert(
                    chunk,
                    on_conflict="model_id,benchmark,category,source,eval_date",
                ).execute()
                saved += len(chunk)
            except Exception as e:
                self.logger.error(f"写入 model_evaluations 失败: {e}")

        self.logger.info(f"写入 {saved}/{len(rows)} 条 Arena-ELO 评测分数")

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
