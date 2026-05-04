"""
Artificial Analysis 排行榜爬虫

数据源: https://artificialanalysis.ai
评估模型性能、速度和成本效益
"""
import re
from typing import Optional

from spiders.rankings_base import BaseRankingsSpider


class ArtificialAnalysisSpider(BaseRankingsSpider):
    """Artificial Analysis 排行榜爬虫 - 综合评估模型"""

    @property
    def name(self) -> str:
        return "Artificial Analysis Rankings"

    @property
    def source(self) -> str:
        return "artificial_analysis"

    @property
    def table_name(self) -> str:
        return "artificial_analysis_rankings"

    async def fetch(self) -> list[dict]:
        """从 Artificial Analysis 抓取排行数据"""
        url = "https://artificialanalysis.ai/models"

        headers = {
            "Accept": "text/html,application/xhtml+xml",
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        }

        try:
            html = await self.http_client.get(url, headers=headers)
            if not html:
                return []

            # 解析 HTML 获取表格数据
            items = self._parse_html(html)
            return items

        except Exception as e:
            self.logger.error(f"抓取失败: {e}")
            return []

    def _parse_html(self, html: str) -> list[dict]:
        """解析 HTML 表格"""
        items = []

        # 使用正则提取表格行
        # 实际应该用 BeautifulSoup，但这里用正则避免额外依赖
        table_pattern = r'<tr[^>]*>(.*?)</tr>'
        row_pattern = r'<td[^>]*>(.*?)</td>'

        rows = re.findall(table_pattern, html, re.DOTALL)

        for row in rows[1:]:  # 跳过表头
            cells = re.findall(row_pattern, row, re.DOTALL)
            if len(cells) >= 6:
                # 解析各列数据
                model_name = self._clean_html(cells[1] if len(cells) > 1 else "")
                if not model_name or model_name == "Model":
                    continue

                # 尝试解析数值
                try:
                    overall_rank = int(self._clean_html(cells[0]))
                    speed_score = int(self._clean_html(cells[2])) if len(cells) > 2 else 0
                    cost_score = int(self._clean_html(cells[3])) if len(cells) > 3 else 0
                    price = self._parse_price(cells[4] if len(cells) > 4 else "")
                    context = int(cells[5].replace(",", "").strip()) if len(cells) > 5 else 0

                    items.append({
                        "model_name": model_name,
                        "overall_rank": overall_rank,
                        "speed_score": speed_score,
                        "cost_score": cost_score,
                        "price_per_million_tokens": price,
                        "context_window": context,
                        "company": self._extract_company(model_name),
                    })
                except (ValueError, IndexError):
                    continue

        return items

    def _clean_html(self, text: str) -> str:
        """清理 HTML 标签"""
        import re
        text = re.sub(r'<[^>]+>', '', text)
        return text.strip()

    def _parse_price(self, price_str: str) -> float:
        """解析价格字符串"""
        price_str = self._clean_html(price_str)
        price_str = price_str.replace("$", "").replace(",", "").strip()

        # 处理范围值
        if "-" in price_str:
            price_str = price_str.split("-")[0].strip()

        try:
            return float(price_str)
        except ValueError:
            return 0.0

    def _extract_company(self, model_name: str) -> str:
        """从模型名称中提取公司名"""
        prefixes = [
            "gpt-4", "gpt-3.5", "claude-3", "claude-2", "claude",
            "gemini-", "gemini-2", "gemini-pro",
            "llama-", "llama3", "llama4",
            "mistral-", "mixtral-",
            "qwen-", "qwen2", "qwen2.5",
            "deepseek-", "deepseek-v3",
            "yi-", "yi-1.5",
        ]

        model_lower = model_name.lower()
        for prefix in prefixes:
            if model_lower.startswith(prefix):
                return prefix.rstrip("/-").replace("-", " ").title()

        return ""

    async def save_to_table(self, items: list[dict]) -> int:
        """保存到 Artificial Analysis 表"""
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
                    on_conflict="model_name,fetched_at::date"
                ).execute()

                if response.data:
                    written += 1

            except Exception as e:
                self.logger.debug(f"写入失败: {e}")

        return written