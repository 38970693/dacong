"""
AI Ping 排行榜爬虫

数据源: https://aiping.dev
评估模型多维度能力（准确性、速度、成本等）
"""
import json
import re
from typing import Optional

from spiders.rankings_base import BaseRankingsSpider


class AIPingSpider(BaseRankingsSpider):
    """AI Ping 排行榜爬虫 - 多维度模型评估"""

    @property
    def name(self) -> str:
        return "AI Ping Rankings"

    @property
    def source(self) -> str:
        return "aiping"

    @property
    def table_name(self) -> str:
        return "aiping_rankings"

    async def fetch(self) -> list[dict]:
        """从 AI Ping 抓取排行数据"""
        # 尝试 API 端点
        urls_to_try = [
            ("https://aiping.dev/api/rankings", None),
            ("https://aiping.dev/api/models", None),
            ("https://aiping.dev/api/v1/rankings", {"Accept": "application/json"}),
            ("https://aiping.dev", {"Accept": "text/html"}),
        ]

        for url, extra_headers in urls_to_try:
            try:
                headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}
                if extra_headers:
                    headers.update(extra_headers)

                response = await self.http_client.get(url, headers=headers)

                if response is None:
                    continue

                # 根据内容类型处理
                if isinstance(response, dict):
                    data = response
                elif isinstance(response, str):
                    # 尝试解析 HTML
                    items = self._parse_html(response)
                    if items:
                        return items
                    continue
                else:
                    continue

                if isinstance(data, list):
                    return self._parse_json_list(data)
                elif isinstance(data, dict):
                    return self._parse_json_dict(data)

            except Exception as e:
                self.logger.debug(f"URL {url} 失败: {e}")
                continue

        return []

    def _parse_json_list(self, data: list) -> list[dict]:
        """解析 JSON 列表"""
        items = []

        for entry in data:
            model_name = entry.get("name", entry.get("model", ""))
            if not model_name:
                continue

            # 提取维度分数
            dimension_scores = {}
            for key in ["accuracy", "speed", "cost", "safety", "reasoning", "creativity"]:
                if key in entry:
                    dimension_scores[key] = entry[key]

            items.append({
                "model_name": model_name,
                "company": entry.get("vendor", entry.get("company", "")),
                "overall_score": entry.get("score", entry.get("overall", 0)),
                "dimension_scores": json.dumps(dimension_scores),
            })

        return items

    def _parse_json_dict(self, data: dict) -> list[dict]:
        """解析 JSON 对象（嵌套结构）"""
        items = []

        # 尝试从 data.models 或 data.rankings 获取
        models = data.get("models", data.get("rankings", data.get("data", [])))

        if isinstance(models, dict):
            models = list(models.values())

        return self._parse_json_list(models if isinstance(models, list) else [])

    def _parse_html(self, html: str) -> list[dict]:
        """解析 HTML 获取排行数据"""
        items = []

        # 尝试提取 JSON 数据（通常内嵌在 script 标签中）
        script_pattern = r'window\.__INITIAL_STATE__\s*=\s*({.*?});'
        match = re.search(script_pattern, html, re.DOTALL)

        if match:
            try:
                data = json.loads(match.group(1))
                if "rankings" in data:
                    return self._parse_json_list(data["rankings"])
            except json.JSONDecodeError:
                pass

        # 尝试提取表格数据
        table_pattern = r'<tr[^>]*>(.*?)</tr>'
        row_pattern = r'<td[^>]*>(.*?)</td>'

        rows = re.findall(table_pattern, html, re.DOTALL)

        for row in rows[1:]:  # 跳过表头
            cells = re.findall(row_pattern, row, re.DOTALL)
            if len(cells) >= 3:
                model_name = self._clean_html(cells[0])
                if not model_name or model_name == "Model":
                    continue

                try:
                    overall_score = float(self._clean_html(cells[1]).replace("%", ""))

                    # 尝试提取维度分数
                    dimension_scores = {}
                    if len(cells) > 2:
                        scores_text = self._clean_html(cells[2])
                        # 解析格式: "accuracy: 85%, speed: 92%"
                        for part in scores_text.split(","):
                            if ":" in part:
                                key, value = part.split(":", 1)
                                try:
                                    dimension_scores[key.strip()] = float(
                                        value.strip().replace("%", "")
                                    )
                                except ValueError:
                                    pass

                    items.append({
                        "model_name": model_name,
                        "overall_score": overall_score,
                        "dimension_scores": json.dumps(dimension_scores),
                        "company": self._extract_company(model_name),
                    })
                except (ValueError, IndexError):
                    continue

        return items

    def _clean_html(self, text: str) -> str:
        """清理 HTML 标签"""
        text = re.sub(r'<[^>]+>', '', text)
        return text.strip()

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
