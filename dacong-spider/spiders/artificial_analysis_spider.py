"""Artificial Analysis 爬虫 - 获取 AI 模型性能数据"""
import httpx
import asyncio
from datetime import datetime
from typing import List, Dict, Any
from supabase import create_client, Client
import os
import json

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")


async def fetch_aa_data() -> Dict[str, Any]:
    """从 Artificial Analysis API 获取模型数据"""
    url = "https://artificialanalysis.ai/api/data/website/host-models/performance"

    async with httpx.AsyncClient(timeout=120, follow_redirects=True) as client:
        resp = await client.get(url, headers={"User-Agent": "Mozilla/5.0"})

        if resp.status_code != 200:
            raise Exception(f"API request failed: {resp.status_code}")

        return resp.json()


def extract_models(data: Dict[str, Any]) -> List[Dict[str, Any]]:
    """从 API 响应中提取模型信息"""
    models = []
    host_models = data.get("hostModels", [])

    for model in host_models:
        # 跳过已删除的模型
        if model.get("deleted"):
            continue

        # 提取基准数据
        benchmarks = model.get("benchmarks", {}) or {}

        # 构建模型记录
        model_record = {
            "slug": model.get("slug"),
            "name": model.get("name"),
            "short_name": model.get("short_name"),
            "model_label": model.get("model_label"),
            "host_id": model.get("host_id"),
            "host_label": model.get("host_label"),
            "host_model_string": model.get("host_model_string"),
            # 价格信息
            "price_1m_input_tokens": model.get("price_1m_input_tokens"),
            "price_1m_output_tokens": model.get("price_1m_output_tokens"),
            "context_window_tokens": model.get("context_window_tokens"),
            "context_window_formatted": model.get("context_window_formatted"),
            # 混合价格
            "price_1m_blended_0_3_1": model.get("price_1m_blended_0_3_1"),
            "price_1m_blended_7_2_1": model.get("price_1m_blended_7_2_1"),
            "price_1m_blended_0_1_1": model.get("price_1m_blended_0_1_1"),
            "price_1m_blended_100_1_1": model.get("price_1m_blended_100_1_1"),
            # 原始 API 响应
            "raw_data": model,
            "fetched_at": datetime.utcnow().isoformat(),
        }

        models.append(model_record)

    return models


def transform_for_db(model: Dict[str, Any], source: str) -> Dict[str, Any]:
    """将模型数据转换为数据库格式"""
    return {
        "name": model.get("name") or model.get("model_label"),
        "provider": model.get("host_label"),
        "slug": model.get("slug"),
        "source": source,
        "metrics": {
            # 性能指标
            "context_window": model.get("context_window_tokens"),
            "context_window_formatted": model.get("context_window_formatted"),
            # 价格
            "price_input": model.get("price_1m_input_tokens"),
            "price_output": model.get("price_1m_output_tokens"),
            "price_blended_0_3_1": model.get("price_1m_blended_0_3_1"),
            "price_blended_7_2_1": model.get("price_1m_blended_7_2_1"),
            "price_blended_0_1_1": model.get("price_1m_blended_0_1_1"),
        },
        "benchmarks": model.get("benchmarks", {}),
        "raw_data": model.get("raw_data"),
        "fetched_at": model.get("fetched_at"),
    }


async def run():
    """主函数"""
    print("Starting Artificial Analysis spider...")

    # 获取数据
    data = await fetch_aa_data()
    print(f"Fetched data with {len(data.get('hostModels', []))} host models")

    # 提取模型
    models = extract_models(data)
    print(f"Extracted {len(models)} active models")

    # 连接数据库
    if SUPABASE_URL and SUPABASE_KEY:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

        # 转换并存储
        records = []
        for model in models:
            record = transform_for_db(model, "artificial_analysis")
            records.append(record)

        if records:
            # Upsert 到数据库
            result = supabase.table("ai_rankings").upsert(
                records,
                on_conflict="slug,source",
            ).execute()

            print(f"Upserted {len(result.data)} records")
            return result.data
    else:
        # 没有数据库连接，只返回数据
        print("No Supabase credentials, returning raw data")
        return models


if __name__ == "__main__":
    result = asyncio.run(run())
    print(json.dumps(result[:3], indent=2, default=str))
