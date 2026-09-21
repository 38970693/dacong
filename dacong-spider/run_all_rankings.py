"""
AI 排行榜数据聚合脚本

从两个主要评测平台抓取数据：
1. LMArena (HuggingFace) - 社区投票 ELO
2. Artificial Analysis - 性能/价格

用法:
    python run_all_rankings.py           # 运行所有
    python run_all_rankings.py --lmarena  # 只运行 LMArena
    python run_all_rankings.py --save-db  # 写入 Supabase
"""
import asyncio
import json
import sys
import argparse
import hashlib
from pathlib import Path
from datetime import datetime

# 导入爬虫
from spiders.huggingface_leaderboard import HuggingFaceLeaderboardSpider
from spiders.artificial_analysis import ArtificialAnalysisSpider
from spiders.aiping import AIPingSpider

# 导入存储
from core.storage import SupabaseStorage
from core.interfaces import RawData, MetricSource, DataType


async def save_to_supabase(
    items: list[dict],
    source: MetricSource,
    data_type: DataType,
    incremental: bool = True
) -> tuple[int, int]:
    """
    保存数据到 Supabase

    Args:
        items: 数据列表
        source: 数据源
        data_type: 数据类型
        incremental: 是否增量更新（跳过已存在且 hash 相同的数据）

    Returns:
        (saved_count, skipped_count)
    """
    storage = SupabaseStorage()
    saved = 0
    skipped = 0

    for item in items:
        try:
            # 生成 content_hash
            content_str = json.dumps(item, sort_keys=True, ensure_ascii=False)
            content_hash = hashlib.md5(content_str.encode()).hexdigest()

            # 构建 source_id
            source_id = f"{item.get('model_name', item.get('name', ''))}_{item.get('elo_rating', item.get('price_1m_input_tokens', 0))}"

            # 增量检查：跳过已存在且 hash 相同的数据
            if incremental:
                existing_hash = await storage.get_content_hash(source, source_id)
                if existing_hash and existing_hash == content_hash:
                    skipped += 1
                    continue

            raw_data = RawData(
                source=source,
                data_type=data_type,
                source_id=source_id,
                title=item.get('model_name', item.get('name', '')),
                description=item.get('description', ''),
                url=item.get('url', ''),
                metadata=item,
                raw_content=content_str,
                content_hash=content_hash,
                fetched_at=datetime.now(),
            )

            if await storage.save(raw_data):
                saved += 1

        except Exception as e:
            print(f"   写入失败: {e}")
            continue

    return saved, skipped


async def run_lmarena(save_db: bool = False) -> dict:
    """从 HuggingFace 获取 LMArena 排行榜数据"""
    print("\n" + "=" * 60)
    print("🚀 [1/2] 正在抓取 LMArena 排行榜 (HuggingFace)...")
    print("=" * 60)

    spider = HuggingFaceLeaderboardSpider()

    try:
        items = await spider.fetch()
        print(f"   ✓ 获取到 {len(items)} 条记录")

        # 转换为 dict 格式
        data = [{
            "model_name": item.title,
            "category": item.metadata.get("category"),
            "organization": item.metadata.get("organization"),
            "elo_rating": item.metadata.get("rating"),
            "rank": item.metadata.get("rank"),
            "vote_count": item.metadata.get("vote_count"),
            "url": item.url,
        } for item in items]

        # 保存到 JSON
        output_dir = Path(__file__).parent / "data"
        output_dir.mkdir(exist_ok=True)
        output_file = output_dir / "lmarena_rankings.json"
        with open(output_file, "w", encoding="utf-8") as f:
            json.dump([{**d, "fetched_at": datetime.now().isoformat()} for d in data],
                     f, indent=2, ensure_ascii=False)

        print(f"   💾 JSON 已保存: {output_file}")

        # 保存到 Supabase
        db_saved = 0
        db_skipped = 0
        if save_db:
            print("   📦 正在写入 Supabase...")
            db_saved, db_skipped = await save_to_supabase(data, MetricSource.LM_ARENA, DataType.MODEL)
            print(f"   ✓ 已写入 {db_saved} 条（跳过 {db_skipped} 条未变化数据）")

        return {
            "source": "LMArena",
            "status": "success",
            "total": len(items),
            "json_saved": len(data),
            "db_saved": db_saved,
            "db_skipped": db_skipped,
        }

    except Exception as e:
        print(f"   ✗ 抓取失败: {e}")
        return {"source": "LMArena", "status": "error", "error": str(e)}
    finally:
        await spider.close()


async def run_artificial_analysis(save_db: bool = False) -> dict:
    """
    从 Artificial Analysis 获取性能数据（新架构爬虫）

    注意：新的 ArtificialAnalysisSpider 内部自行抓取并写入 Supabase，
    因此不再生成独立的 artificial_analysis_rankings.json。
    """
    print("\n" + "=" * 60)
    print("🚀 [2/3] 正在抓取 Artificial Analysis 数据...")
    print("=" * 60)

    try:
        spider = ArtificialAnalysisSpider()
        result = await spider.run()

        print(f"   ✓ 抓取 {result.items_fetched} 条，写入 {result.items_written} 条")

        return {
            "source": "Artificial Analysis",
            "status": "success" if result.success else "error",
            "total": result.items_fetched,
            "json_saved": 0,
            "db_saved": result.items_written,
            "db_skipped": 0,
        }

    except Exception as e:
        print(f"   ✗ 抓取失败: {e}")
        return {"source": "Artificial Analysis", "status": "error", "error": str(e)}


async def run_aiping(save_db: bool = False) -> dict:
    """从 AI Ping 获取多维度评估数据"""
    print("\n" + "=" * 60)
    print("🚀 [3/3] 正在抓取 AI Ping 排行榜...")
    print("=" * 60)

    spider = AIPingSpider()

    try:
        items = await spider.fetch()
        print(f"   ✓ 获取到 {len(items)} 条记录")

        if items:
            # 保存到 JSON
            output_dir = Path(__file__).parent / "data"
            output_dir.mkdir(exist_ok=True)
            output_file = output_dir / "aiping_rankings.json"
            with open(output_file, "w", encoding="utf-8") as f:
                json.dump([{**d, "fetched_at": datetime.now().isoformat()} for d in items],
                         f, indent=2, ensure_ascii=False)

            print(f"   💾 JSON 已保存: {output_file}")

            # 保存到 Supabase
            db_saved = 0
            db_skipped = 0
            if save_db:
                print("   📦 正在写入 Supabase...")
                db_saved, db_skipped = await save_to_supabase(items, MetricSource.AI_PING, DataType.MODEL)
                print(f"   ✓ 已写入 {db_saved} 条（跳过 {db_skipped} 条未变化数据）")

            return {
                "source": "AI Ping",
                "status": "success",
                "total": len(items),
                "json_saved": len(items),
                "db_saved": db_saved,
                "db_skipped": db_skipped,
            }
        else:
            return {
                "source": "AI Ping",
                "status": "warning",
                "total": 0,
                "message": "未获取到数据（网站可能无公开 API）",
            }

    except Exception as e:
        print(f"   ✗ 抓取失败: {e}")
        return {"source": "AI Ping", "status": "error", "error": str(e)}
    finally:
        await spider.close()


async def main():
    parser = argparse.ArgumentParser(description="AI 排行榜数据聚合")
    parser.add_argument("--lmarena", action="store_true", help="只运行 LMArena")
    parser.add_argument("--aa", action="store_true", help="只运行 Artificial Analysis")
    parser.add_argument("--aiping", action="store_true", help="只运行 AI Ping")
    parser.add_argument("--save-db", action="store_true", help="写入 Supabase 数据库")
    parser.add_argument("--all", action="store_true", help="运行所有 (默认)")

    args = parser.parse_args()

    # 默认运行所有
    if not any([args.lmarena, args.aa, args.aiping, args.all]):
        args.all = True

    print("\n" + "╔" + "═" * 58 + "╗")
    print("║" + " " * 10 + "AI 排行榜数据聚合器" + " " * 21 + "║")
    print("║" + " " * 6 + "抓取 LMArena | Artificial Analysis | AI Ping" + " " * 7 + "║")
    print("╚" + "═" * 58 + "╝")

    results = []

    if args.all or args.lmarena:
        result = await run_lmarena(save_db=args.save_db)
        results.append(result)

    if args.all or args.aa:
        result = await run_artificial_analysis(save_db=args.save_db)
        results.append(result)

    if args.all or args.aiping:
        result = await run_aiping(save_db=args.save_db)
        results.append(result)

    # 输出汇总
    print("\n" + "=" * 60)
    print("📊 执行结果汇总")
    print("=" * 60)

    for r in results:
        status_icon = "✓" if r["status"] == "success" else "✗"
        print(f"\n{status_icon} {r['source']}")
        print(f"   状态: {r['status']}")
        print(f"   抓取: {r.get('total', 'N/A')} 条")
        print(f"   JSON: {r.get('json_saved', 'N/A')} 条")
        if args.save_db:
            print(f"   数据库: {r.get('db_saved', 0)} 条写入, {r.get('db_skipped', 0)} 条跳过")

    # 保存汇总报告
    output_dir = Path(__file__).parent / "data"
    summary_file = output_dir / "fetch_summary.json"
    summary = {
        "timestamp": datetime.now().isoformat(),
        "db_writes_enabled": args.save_db,
        "results": results,
    }
    with open(summary_file, "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2, ensure_ascii=False)

    print(f"\n📁 汇总报告: {summary_file}")
    print("\n" + "=" * 60)
    print("✅ 完成!")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())