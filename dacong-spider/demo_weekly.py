#!/usr/bin/env python3
"""
周报生成演示脚本

演示如何使用周报生成器和图卡生成器
"""
import json
import os
from datetime import datetime, timedelta
from pathlib import Path

# 添加项目根目录到 Python 路径
import sys
sys.path.insert(0, str(Path(__file__).parent))

from core.weekly_generator import WeeklyGenerator
from core.image_generator import ImageGenerator


def generate_sample_data():
    """生成示例数据"""
    now = datetime.now()

    return [
        {
            "name": "DeepSeek-V3",
            "github_url": "https://github.com/deepseek-ai/DeepSeek-V3",
            "description": "强大的开源大模型，性能超越 GPT-4",
            "stars": 15000,
            "created_at": (now - timedelta(days=2)).isoformat(),
        },
        {
            "name": "Claude Code",
            "github_url": "https://github.com/anthropics/claude-code",
            "description": "AI 编程助手，代码质量最高",
            "stars": 12000,
            "created_at": (now - timedelta(days=5)).isoformat(),
        },
        {
            "name": "Cursor",
            "github_url": "https://github.com/getcursor/cursor",
            "description": "AI 代码编辑器，开发效率提升 10 倍",
            "stars": 10000,
            "created_at": (now - timedelta(days=1)).isoformat(),
        },
        {
            "name": "Runway Gen-3",
            "github_url": "https://github.com/runwayml/gen-3",
            "description": "AI 视频生成工具，效果惊艳",
            "stars": 8000,
            "created_at": (now - timedelta(days=3)).isoformat(),
        },
        {
            "name": "Midjourney V6",
            "github_url": "https://github.com/midjourney/v6",
            "description": "AI 图片生成工具，细节丰富",
            "stars": 7000,
            "created_at": (now - timedelta(days=4)).isoformat(),
        },
    ]


def main():
    """主函数"""
    print("=" * 60)
    print("周报生成演示")
    print("=" * 60)

    # 检查 API Key
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        print("\n⚠️  警告：未设置 ANTHROPIC_API_KEY 环境变量")
        print("将使用模拟数据演示图卡生成功能\n")
        use_mock = True
    else:
        print(f"\n✓ 已检测到 API Key: {api_key[:10]}...\n")
        use_mock = False

    # 1. 生成示例数据
    print("1. 生成示例数据...")
    raw_data = generate_sample_data()
    print(f"   ✓ 已生成 {len(raw_data)} 条示例数据\n")

    # 2. 聚合数据
    print("2. 聚合周报数据...")
    if not use_mock:
        generator = WeeklyGenerator(api_key=api_key)
        aggregated = generator.aggregate_weekly_data(raw_data, days=7)
        print(f"   ✓ 聚合完成，共 {aggregated['total_projects']} 个项目")
        print(f"   ✓ 时间范围: {aggregated['week_start']} 至 {aggregated['week_end']}\n")
    else:
        aggregated = {
            "week_start": (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%d"),
            "week_end": datetime.now().strftime("%Y-%m-%d"),
            "total_projects": len(raw_data),
        }
        print(f"   ✓ 使用模拟数据\n")

    # 3. 生成周报内容
    print("3. 生成周报内容...")
    if not use_mock:
        print("   ⏳ 调用 Claude API 生成周报（可能需要几秒钟）...")
        result = generator.generate_weekly(raw_data)
        weekly_content = result["content"]
        print(f"   ✓ 周报生成成功")
        print(f"   ✓ AI 置信度: {result['ai_confidence']:.2f}")
        print(f"   ✓ 标题: {weekly_content['title']}\n")

        # 保存周报内容
        output_dir = Path(__file__).parent / "output"
        output_dir.mkdir(exist_ok=True)

        weekly_file = output_dir / "weekly_content.json"
        with open(weekly_file, "w", encoding="utf-8") as f:
            json.dump(weekly_content, f, ensure_ascii=False, indent=2)
        print(f"   ✓ 周报内容已保存: {weekly_file}\n")
    else:
        # 使用模拟数据
        weekly_content = {
            "title": "本周 AI 工具精选",
            "summary": "本周最值得关注的 AI 项目和工具",
            "week_start": aggregated["week_start"],
            "week_end": aggregated["week_end"],
            "sections": [
                {
                    "section_title": "本周最火",
                    "items": [
                        {
                            "name": "DeepSeek-V3",
                            "one_liner": "强大的开源大模型",
                            "why_matters": "性能超越 GPT-4，完全开源",
                            "github_url": "https://github.com/deepseek-ai/DeepSeek-V3",
                            "stars": 15000,
                            "star_growth": 5000,
                            "access": "国内可用",
                        },
                        {
                            "name": "Claude Code",
                            "one_liner": "AI 编程助手",
                            "why_matters": "代码质量最高，推理能力强",
                            "github_url": "https://github.com/anthropics/claude-code",
                            "stars": 12000,
                            "star_growth": 3000,
                            "access": "需翻墙",
                        },
                    ],
                },
                {
                    "section_title": "编辑推荐",
                    "items": [
                        {
                            "name": "Cursor",
                            "one_liner": "AI 代码编辑器",
                            "why_matters": "开发效率提升 10 倍",
                            "github_url": "https://github.com/getcursor/cursor",
                            "stars": 10000,
                            "star_growth": 2000,
                            "access": "国内可用",
                        },
                    ],
                },
            ],
            "confidence": 0.92,
        }
        print("   ✓ 使用模拟周报内容\n")

    # 4. 生成图卡
    print("4. 生成分享图卡...")
    image_gen = ImageGenerator()

    # 生成中文图卡
    print("   ⏳ 生成中文图卡...")
    zh_image = image_gen.generate_weekly_card(weekly_content, language="zh")
    print(f"   ✓ 中文图卡已生成: {zh_image}")

    # 生成英文图卡
    print("   ⏳ 生成英文图卡...")
    en_image = image_gen.generate_weekly_card(weekly_content, language="en")
    print(f"   ✓ 英文图卡已生成: {en_image}\n")

    # 5. 完成
    print("=" * 60)
    print("✓ 周报生成演示完成！")
    print("=" * 60)
    print("\n生成的文件：")
    if not use_mock:
        print(f"  - 周报内容: {weekly_file}")
    print(f"  - 中文图卡: {zh_image}")
    print(f"  - 英文图卡: {en_image}")
    print("\n提示：")
    print("  - 图卡尺寸: 1200x630 (适合社交媒体分享)")
    print("  - 可以使用图片查看器打开查看效果")
    if use_mock:
        print("  - 设置 ANTHROPIC_API_KEY 环境变量可使用真实 AI 生成")
    print()


if __name__ == "__main__":
    main()
