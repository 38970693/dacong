#!/usr/bin/env python3
"""
内容生成脚本

独立运行 AI 内容生成管道，支持：
- 批量生成
- 进度显示
- 成本监控
- 错误处理

使用示例：
    python scripts/generate_content.py --scenario coding --limit 10
    python scripts/generate_content.py --scenario video --limit 5 --no-translate
"""
import argparse
import sys
from pathlib import Path

# 添加项目根目录到 Python 路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from loguru import logger

from core.generation_pipeline import GenerationPipeline


def setup_logging(debug: bool = False):
    """配置日志"""
    logger.remove()
    log_level = "DEBUG" if debug else "INFO"
    logger.add(sys.stderr, level=log_level, format="<green>{time:HH:mm:ss}</green> | <level>{level: <8}</level> | <level>{message}</level>")


def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="AI 内容生成脚本")
    parser.add_argument("--scenario", type=str, required=True, help="场景名称（coding/video/image/chat/writing）")
    parser.add_argument("--limit", type=int, default=10, help="生成数量（默认: 10）")
    parser.add_argument("--source", type=str, help="数据源（github/huggingface等）")
    parser.add_argument("--no-multi-round", action="store_true", help="禁用多轮生成")
    parser.add_argument("--no-translate", action="store_true", help="禁用翻译")
    parser.add_argument("--debug", action="store_true", help="调试模式")

    args = parser.parse_args()

    # 配置日志
    setup_logging(args.debug)

    logger.info("=" * 60)
    logger.info("AI 内容生成管道")
    logger.info("=" * 60)
    logger.info(f"场景: {args.scenario}")
    logger.info(f"数量: {args.limit}")
    logger.info(f"数据源: {args.source or '全部'}")
    logger.info(f"多轮生成: {'否' if args.no_multi_round else '是'}")
    logger.info(f"翻译: {'否' if args.no_translate else '是'}")
    logger.info("=" * 60)

    try:
        # 创建管道
        pipeline = GenerationPipeline()

        # 批量处理
        stats = pipeline.process_batch(
            scenario=args.scenario,
            limit=args.limit,
            source=args.source,
            multi_round=not args.no_multi_round,
            translate=not args.no_translate,
        )

        # 输出统计
        logger.info("=" * 60)
        logger.info("处理统计")
        logger.info("=" * 60)
        logger.info(f"总数: {stats['total']}")
        logger.info(f"成功: {stats['success']}")
        logger.info(f"失败: {stats['failed']}")
        logger.info(f"质量未通过: {stats['quality_failed']}")
        logger.info(f"翻译失败: {stats['translation_failed']}")

        # 成本统计
        cost_summary = pipeline.get_cost_summary()
        logger.info("=" * 60)
        logger.info("成本统计")
        logger.info("=" * 60)
        logger.info(f"生成成本: ${cost_summary['generator']['total_cost']:.4f}")
        logger.info(f"  - 输入: {cost_summary['generator']['total_input_tokens']} tokens (${cost_summary['generator']['input_cost']:.4f})")
        logger.info(f"  - 输出: {cost_summary['generator']['total_output_tokens']} tokens (${cost_summary['generator']['output_cost']:.4f})")
        logger.info(f"  - 缓存: {cost_summary['generator'].get('cached_tokens', 0)} tokens (节省 ${cost_summary['generator'].get('cache_savings', 0):.4f})")

        if not args.no_translate:
            logger.info(f"翻译成本: ${cost_summary['translator']['total_cost']:.4f}")
            logger.info(f"  - 输入: {cost_summary['translator']['total_input_tokens']} tokens (${cost_summary['translator']['input_cost']:.4f})")
            logger.info(f"  - 输出: {cost_summary['translator']['total_output_tokens']} tokens (${cost_summary['translator']['output_cost']:.4f})")

        logger.info(f"总成本: ${cost_summary['total_cost']:.4f}")

        if stats['success'] > 0:
            logger.info(f"平均成本: ${cost_summary['total_cost'] / stats['success']:.4f}/条")

        logger.info("=" * 60)
        logger.success("处理完成！")

    except KeyboardInterrupt:
        logger.warning("用户中断")
        sys.exit(1)
    except Exception as e:
        logger.error(f"处理失败: {e}")
        if args.debug:
            logger.exception(e)
        sys.exit(1)


if __name__ == "__main__":
    main()
