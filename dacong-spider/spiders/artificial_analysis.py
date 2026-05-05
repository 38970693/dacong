"""
Artificial Analysis 排行榜爬虫

数据源: https://artificialanalysis.ai
评估模型性能、速度和成本效益

API: https://artificialanalysis.ai/api/data/website/host-models/performance
"""
import json
from typing import Optional

from spiders.rankings_base import BaseRankingsSpider


class ArtificialAnalysisSpider(BaseRankingsSpider):
    """Artificial Analysis 排行榜爬虫 - 综合评估模型"""

    API_URL = "https://artificialanalysis.ai/api/data/website/host-models/performance"

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
        """从 Artificial Analysis API 抓取排行数据"""
        headers = {
            "Accept": "application/json",
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        }

        try:
            response = await self.http_client.get(self.API_URL, headers=headers)
            if not response:
                self.logger.error("API 请求无响应")
                return []

            data = json.loads(response) if isinstance(response, str) else response
            return self._parse_api_response(data)

        except Exception as e:
            self.logger.error(f"抓取失败: {e}")
            return []

    def _parse_api_response(self, data: dict) -> list[dict]:
        """解析 API 响应"""
        items = []
        host_models = data.get("hostModels", [])

        for model in host_models:
            # 跳过已删除的模型
            if model.get("deleted"):
                continue

            item = {
                "model_name": model.get("name") or model.get("model_label") or "",
                "slug": model.get("slug") or "",
                "provider": model.get("host_label") or "",
                "provider_id": model.get("host_id") or "",
                "provider_string": model.get("host_model_string") or "",
                # 价格信息
                "price_1m_input_tokens": model.get("price_1m_input_tokens"),
                "price_1m_output_tokens": model.get("price_1m_output_tokens"),
                # 混合价格 (不同输入:输出 token 比例)
                "price_1m_blended_0_3_1": model.get("price_1m_blended_0_3_1"),
                "price_1m_blended_7_2_1": model.get("price_1m_blended_7_2_1"),
                "price_1m_blended_0_1_1": model.get("price_1m_blended_0_1_1"),
                "price_1m_blended_100_1_1": model.get("price_1m_blended_100_1_1"),
                # 上下文窗口
                "context_window_tokens": model.get("context_window_tokens") or 0,
                "context_window_formatted": model.get("context_window_formatted") or "",
                # 其他元数据
                "short_name": model.get("short_name") or "",
                "model_label": model.get("model_label") or "",
                "logo_url": model.get("logo_url") or "",
                "logo_small_url": model.get("logo_small_url") or "",
                "host_color": model.get("host_color") or "",
                # 功能标志
                "json_mode": model.get("json_mode") or False,
                "function_calling": model.get("function_calling") or False,
                "supports_images": model.get("override_supports_images_input") or False,
                # 价格相关
                "cache_hit_price": model.get("cache_hit_price"),
                "cache_write_price": model.get("cache_write_price"),
                "image_input_pricing_notes": model.get("image_input_pricing_notes") or "",
            }

            items.append(item)

        self.logger.info(f"解析到 {len(items)} 条活跃模型记录")
        return items

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
                    on_conflict="slug"
                ).execute()

                if response.data:
                    written += 1

            except Exception as e:
                self.logger.debug(f"写入失败: {e}")

        return written

    async def save_to_json(self, items: list[dict], filepath: str) -> bool:
        """保存数据到 JSON 文件"""
        try:
            with open(filepath, "w", encoding="utf-8") as f:
                json.dump({
                    "source": "artificial_analysis",
                    "fetched_at": items[0].get("fetched_at") if items else None,
                    "total_count": len(items),
                    "models": items
                }, f, ensure_ascii=False, indent=2)
            self.logger.info(f"已保存 {len(items)} 条数据到 {filepath}")
            return True
        except Exception as e:
            self.logger.error(f"保存 JSON 失败: {e}")
            return False


async def run_and_save():
    """运行爬虫并保存到 JSON 文件"""
    spider = ArtificialAnalysisSpider()

    # 抓取数据
    items = await spider.fetch()
    print(f"抓取到 {len(items)} 条模型数据")

    if items:
        # 添加抓取时间
        from datetime import datetime, timezone
        for item in items:
            item["fetched_at"] = datetime.now(timezone.utc).isoformat()

        # 保存到 JSON
        output_path = "e:\\gitlab\\dacong\\dacong-spider\\data\\artificial_analysis_rankings.json"
        success = await spider.save_to_json(items, output_path)
        if success:
            print(f"✅ 成功保存到: {output_path}")
        else:
            print("❌ JSON 保存失败")

    return items


if __name__ == "__main__":
    import asyncio
    results = asyncio.run(run_and_save())
    print(f"\n总计: {len(results)} 条记录")