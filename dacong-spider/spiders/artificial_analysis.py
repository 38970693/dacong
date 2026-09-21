"""
Artificial Analysis 排行榜爬虫

数据源: https://artificialanalysis.ai
评估模型性能、速度和成本效益

API: https://artificialanalysis.ai/api/data/website/host-models/performance
"""
import json
from datetime import date
from typing import Optional

from spiders.rankings_base import BaseRankingsSpider

# benchmark 字段映射：API 字段 -> (统一 benchmark 名, 分类, 是否 0~1 比例)
# 字段位于 hostModel.model 下；比例型统一 ×100 存成百分制，原始值留在 raw_data
BENCHMARK_MAP = {
    "mmlu_pro": ("MMLU-Pro", "general", True),
    "gpqa": ("GPQA", "general", True),
    "hle": ("HLE", "general", True),
    "ifbench": ("IFBench", "general", True),
    "humaneval": ("HumanEval", "coding", True),
    "livecodebench": ("LiveCodeBench", "coding", True),
    "scicode": ("SciCode", "coding", True),
    "terminalbench_hard": ("Terminal-Bench-Hard", "coding", True),
    "math_500": ("MATH-500", "math", True),
    "aime": ("AIME", "math", True),
    "aime25": ("AIME-2025", "math", True),
    "mmmu_pro": ("MMMU-Pro", "vision", True),
    "tau2": ("Tau2-Bench", "agentic", True),
    "intelligence_index": ("Intelligence-Index", "general", False),
}

# 输入模态标志 -> multimodal_inputs 元素
MODALITY_FIELDS = {
    "input_modality_text": "text",
    "input_modality_image": "image",
    "input_modality_speech": "speech",
    "input_modality_video": "video",
}


def _as_number(value) -> Optional[float]:
    """只接受真实数值；bool 是 int 的子类，需显式排除"""
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return None
    return float(value)


def parse_benchmarks(model: dict) -> list[dict]:
    """
    从 hostModel.model 解析 benchmark 分数

    缺失/非数值字段一律跳过（API 常把未跑的 benchmark 置为 null）
    """
    results = []
    for field, (benchmark, category, is_ratio) in BENCHMARK_MAP.items():
        raw = _as_number(model.get(field))
        if raw is None:
            continue
        results.append({
            "benchmark": benchmark,
            "score": round(raw * 100 if is_ratio else raw, 4),
            "category": category,
            "raw_data": {"field": field, "raw_value": raw},
        })
    return results


def parse_capabilities(model: dict) -> dict:
    """从 hostModel.model 解析与宿主无关的能力字段（对应 models 表新列）"""
    inputs = [
        name for field, name in MODALITY_FIELDS.items() if model.get(field) is True
    ]
    return {
        "context_window": model.get("context_window_tokens"),
        "max_output_tokens": model.get("output_tokens"),
        "multimodal_inputs": inputs,
        "tool_use": False,
    }


def merge_host_performance(capabilities: dict, host_model: dict) -> dict:
    """
    合并宿主维度的性能/能力指标

    同一模型有多个宿主（不同服务商），取「最优宿主」：吞吐取最大、延迟取最小；
    function_calling 只要任一宿主支持即视为支持。
    """
    if host_model.get("function_calling"):
        capabilities["tool_use"] = True

    timescale = host_model.get("timescaleData") or {}

    speed = _as_number(timescale.get("median_output_speed"))
    if speed is not None:
        current = capabilities.get("throughput_tps")
        tps = round(speed)
        if current is None or tps > current:
            capabilities["throughput_tps"] = tps

    ttfc = _as_number(timescale.get("median_time_to_first_chunk"))
    if ttfc is not None:
        current = capabilities.get("latency_ms")
        latency = round(ttfc * 1000)
        if current is None or latency < current:
            capabilities["latency_ms"] = latency

    return capabilities


class ArtificialAnalysisSpider(BaseRankingsSpider):
    """Artificial Analysis 排行榜爬虫 - 综合评估模型"""

    API_URL = "https://artificialanalysis.ai/api/data/website/host-models/performance"

    EVAL_CHUNK = 500

    def __init__(self, *args, **kwargs):
        # 该 API 响应约 21MB、需 ~90s，默认 30s 超时会被截断，
        # 导致 model.model 内 benchmark 字段大量为 null、评测分数丢失。
        # 单独把本爬虫的 HTTP 超时调高（每日批抓取，耗时不是问题）。
        from core.implementations import HttpClient

        super().__init__(http_client=HttpClient(timeout=240), *args, **kwargs)
        # model slug -> {name, vendor, capabilities, evaluations}
        self._model_records: dict[str, dict] = {}

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
        self._model_records = {}

        for model in host_models:
            # 跳过已删除的模型
            if model.get("deleted"):
                continue

            self._collect_model_record(model)

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

        self.logger.info(
            f"解析到 {len(items)} 条活跃模型记录，"
            f"归并出 {len(self._model_records)} 个模型"
        )
        return items

    def _collect_model_record(self, host_model: dict) -> None:
        """
        按底层模型（而非「模型 x 宿主」）归并评测与能力

        benchmark 分数挂在 hostModel.model 上，多个宿主共享同一份；
        性能指标则是宿主维度的，用 merge_host_performance 逐个合并。
        """
        model = host_model.get("model") or {}
        slug = model.get("slug")
        if not slug:
            return

        record = self._model_records.get(slug)
        if record is None:
            creator = model.get("model_creators") or {}
            record = {
                "name": model.get("name") or model.get("short_name") or slug,
                "vendor": creator.get("name") or "Unknown",
                "capabilities": parse_capabilities(model),
                "evaluations": parse_benchmarks(model),
            }
            self._model_records[slug] = record

        merge_host_performance(record["capabilities"], host_model)

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

        self._save_evaluations(client)

        return written

    def _upsert_model(self, client, record: dict) -> Optional[str]:
        """确保 models 表存在该模型并刷新能力字段，返回 model_id"""
        name, vendor = record["name"], record["vendor"]
        try:
            existing = client.table("models").select("id").match({
                "name": name,
                "vendor": vendor,
            }).limit(1).execute()

            if existing.data:
                model_id = existing.data[0]["id"]
                # 只更新能力列，不覆盖人工维护的 category / description
                client.table("models").update(
                    record["capabilities"]
                ).eq("id", model_id).execute()
                return model_id

            created = client.table("models").insert({
                "name": name,
                "vendor": vendor,
                "category": "LLM",
                **record["capabilities"],
            }).execute()
            return created.data[0]["id"] if created.data else None

        except Exception as e:
            self.logger.debug(f"models upsert 失败 [{vendor}/{name}]: {e}")
            return None

    def _save_evaluations(self, client) -> None:
        """把能力字段写入 models、benchmark 分数写入 model_evaluations"""
        if not self._model_records:
            return

        eval_date = date.today().isoformat()
        rows = []

        for record in self._model_records.values():
            model_id = self._upsert_model(client, record)
            if not model_id:
                continue

            for evaluation in record["evaluations"]:
                rows.append({
                    "model_id": model_id,
                    "benchmark": evaluation["benchmark"],
                    "score": evaluation["score"],
                    "category": evaluation["category"],
                    "source": self.source,
                    "eval_date": eval_date,
                    "raw_data": evaluation["raw_data"],
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

        self.logger.info(f"写入 {saved}/{len(rows)} 条 benchmark 评测分数")

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
