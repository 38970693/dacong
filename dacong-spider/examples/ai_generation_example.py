#!/usr/bin/env python3
"""
AI 内容生成示例

演示如何使用内容生成管道
"""
import json
import sys
from pathlib import Path

# 添加项目根目录到 Python 路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from core.content_generator import ContentGenerator
from core.quality_checker import QualityChecker
from core.translator import Translator


def example_1_basic_generation():
    """示例 1：基础内容生成"""
    print("=" * 60)
    print("示例 1：基础内容生成")
    print("=" * 60)

    # 准备数据
    scenario = "coding"
    data = {
        "tools": [
            {"name": "Claude Code", "stars": 15000, "price": "$20/月"},
            {"name": "Cursor", "stars": 12000, "price": "$20/月"},
            {"name": "GitHub Copilot", "stars": 8000, "price": "$10/月"},
        ]
    }

    # 创建生成器
    generator = ContentGenerator(api_key="test-key")  # 实际使用时从环境变量读取

    print(f"场景: {scenario}")
    print(f"数据: {json.dumps(data, ensure_ascii=False, indent=2)}")
    print("\n注意：这是示例代码，需要配置真实的 ANTHROPIC_API_KEY 才能运行")


def example_2_quality_check():
    """示例 2：质量检测"""
    print("\n" + "=" * 60)
    print("示例 2：质量检测")
    print("=" * 60)

    # 模拟生成的内容
    content = {
        "title": "写代码最佳AI助手推荐",
        "summary": "根据代码能力、价格和易用性，为你推荐3个最适合的编程助手",
        "recommendations": [
            {
                "rank": 1,
                "name": "Claude Code",
                "one_liner": "代码能力最强的AI助手",
                "pros": ["代码质量高", "推理能力强"],
                "cons": ["价格较贵"],
                "best_for": "专业开发者",
                "price": "$20/月",
                "access": "需翻墙",
                "rating": 4.8,
            },
            {
                "rank": 2,
                "name": "Cursor",
                "one_liner": "性价比之选",
                "pros": ["国内可用", "价格适中"],
                "cons": ["略逊于Claude"],
                "best_for": "个人开发者",
                "price": "$20/月",
                "access": "国内可用",
                "rating": 4.5,
            },
            {
                "rank": 3,
                "name": "GitHub Copilot",
                "one_liner": "老牌工具",
                "pros": ["价格便宜", "学生免费"],
                "cons": ["代码能力一般"],
                "best_for": "学生",
                "price": "$10/月",
                "access": "需翻墙",
                "rating": 4.2,
            },
        ],
        "confidence": 0.92,
    }

    # 质量检测
    checker = QualityChecker()
    result = checker.check_quality(content)

    print(f"质量分数: {result['total_score']}")
    print(f"是否通过: {'通过' if result['passed'] else '未通过'}")
    print("\n详细分数:")
    for key, value in result["details"].items():
        print(f"  {key}: {value}")


def example_3_translation():
    """示例 3：内容翻译"""
    print("\n" + "=" * 60)
    print("示例 3：内容翻译")
    print("=" * 60)

    chinese_content = {
        "title": "写代码最佳AI助手推荐",
        "summary": "根据代码能力、价格和易用性推荐",
        "recommendations": [
            {
                "rank": 1,
                "name": "Claude Code",
                "one_liner": "代码能力最强",
                "pros": ["质量高"],
                "cons": ["价格贵"],
                "best_for": "专业开发者",
                "price": "$20/月",
                "access": "需翻墙",
                "rating": 4.8,
            }
        ],
        "confidence": 0.92,
    }

    print("中文内容:")
    print(json.dumps(chinese_content, ensure_ascii=False, indent=2))
    print("\n注意：翻译功能需要配置真实的 ANTHROPIC_API_KEY")


def example_4_cost_monitoring():
    """示例 4：成本监控"""
    print("\n" + "=" * 60)
    print("示例 4：成本监控")
    print("=" * 60)

    # 模拟 token 使用
    total_input_tokens = 5000
    total_output_tokens = 2000
    cached_tokens = 4000

    # 计算成本
    input_price_per_m = 3.0
    output_price_per_m = 15.0
    cache_read_price_per_m = 0.3

    input_cost = (total_input_tokens - cached_tokens) * input_price_per_m / 1_000_000
    output_cost = total_output_tokens * output_price_per_m / 1_000_000
    cache_cost = cached_tokens * cache_read_price_per_m / 1_000_000
    total_cost = input_cost + output_cost + cache_cost
    cache_savings = cached_tokens * (input_price_per_m - cache_read_price_per_m) / 1_000_000

    print(f"输入 tokens: {total_input_tokens}")
    print(f"输出 tokens: {total_output_tokens}")
    print(f"缓存 tokens: {cached_tokens}")
    print(f"\n输入成本: ${input_cost:.4f}")
    print(f"输出成本: ${output_cost:.4f}")
    print(f"缓存成本: ${cache_cost:.4f}")
    print(f"总成本: ${total_cost:.4f}")
    print(f"缓存节省: ${cache_savings:.4f}")


def main():
    """运行所有示例"""
    print("\nAI 内容生成管道示例\n")

    example_1_basic_generation()
    example_2_quality_check()
    example_3_translation()
    example_4_cost_monitoring()

    print("\n" + "=" * 60)
    print("所有示例运行完成")
    print("=" * 60)
    print("\n提示：")
    print("1. 配置 .env 文件中的 ANTHROPIC_API_KEY")
    print("2. 运行: python scripts/generate_content.py --scenario coding --limit 1")
    print("3. 查看生成的内容和成本统计")


if __name__ == "__main__":
    main()
