"""
SWE-bench 排行榜爬虫

数据源: https://www.swebench.org/lite
"""
from typing import Optional

from spiders.rankings_base import BaseRankingsSpider


class SWEBenchSpider(BaseRankingsSpider):
    """SWE-bench 排行榜爬虫 - 评估模型解决真实代码问题的能力"""

    @property
    def name(self) -> str:
        return "SWE-bench Rankings"

    @property
    def source(self) -> str:
        return "swebench"

    @property
    def table_name(self) -> str:
        return "swebench_rankings"

    async def fetch(self) -> list[dict]:
        """从 SWE-bench 官网抓取排行数据"""
        import asyncio

        # SWE-bench 提供静态 JSON 数据
        url = "https://swebench-w32k7yyc2hdsgnf6uczhqga.ch-ewg3.dev/eval/swe_table/w32k7yyc2hdsgnf6uczhqga/swe_bench_lite.json"

        try:
            json_data = await self.http_client.get_json(url)
            if not json_data:
                return []

            items = []
            for entry in json_data:
                items.append({
                    "model_name": entry.get("model", ""),
                    "elo_score": entry.get("elo", 0),
                    "pass_rate": entry.get("pass_rate", 0),
                    "instance_count": entry.get("instance_count", 0),
                    "category": entry.get("category", "standard"),
                    "company": entry.get("company", ""),
                })

            return items

        except Exception as e:
            self.logger.error(f"抓取失败: {e}")
            return []

    async def save_to_table(self, items: list[dict]) -> int:
        """保存到 SWE-bench 表"""
        from supabase import create_client
        from config import SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY

        if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
            self.logger.error("缺少 Supabase 配置")
            return 0

        client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
        written = 0

        for item in items:
            try:
                response = client.table(self.table_name).upsert(
                    item,
                    on_conflict="model_name,category,fetched_at::date"
                ).execute()

                if response.data:
                    written += 1

            except Exception as e:
                self.logger.debug(f"写入失败: {e}")

        return written