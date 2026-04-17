"""
内容生成管道

完整的 AI 内容生成流程：
1. 从 raw_data 读取数据
2. 调用 ContentGenerator 生成内容
3. 质量检测
4. 翻译成英文
5. 写入 generated_content 表
"""
import time
from datetime import datetime
from typing import Any, Dict, List, Optional

from loguru import logger
from supabase import Client, create_client

from config import config
from core.content_generator import ContentGenerator
from core.quality_checker import QualityChecker
from core.translator import Translator


class GenerationPipeline:
    """内容生成管道"""

    def __init__(
        self,
        supabase_client: Optional[Client] = None,
        generator: Optional[ContentGenerator] = None,
        quality_checker: Optional[QualityChecker] = None,
        translator: Optional[Translator] = None,
    ):
        """
        初始化管道

        Args:
            supabase_client: Supabase 客户端
            generator: 内容生成器
            quality_checker: 质量检测器
            translator: 翻译器
        """
        self.supabase = supabase_client or create_client(config.supabase_url, config.supabase_service_role_key)
        self.generator = generator or ContentGenerator()
        self.quality_checker = quality_checker or QualityChecker()
        self.translator = translator or Translator()

        # 统计信息
        self.stats = {
            "total": 0,
            "success": 0,
            "failed": 0,
            "quality_failed": 0,
            "translation_failed": 0,
        }

    def fetch_raw_data(self, source: Optional[str] = None, limit: int = 10) -> List[Dict[str, Any]]:
        """
        从 raw_data 表读取数据

        Args:
            source: 数据源（github/huggingface等）
            limit: 读取数量

        Returns:
            原始数据列表
        """
        logger.info(f"读取原始数据 - source: {source}, limit: {limit}")

        query = self.supabase.table("raw_data").select("*").order("created_at", desc=True).limit(limit)

        if source:
            query = query.eq("source", source)

        response = query.execute()
        data = response.data

        logger.info(f"读取到 {len(data)} 条原始数据")
        return data

    def generate_content(
        self, scenario: str, raw_data: Dict[str, Any], multi_round: bool = True, translate: bool = True
    ) -> Optional[Dict[str, Any]]:
        """
        生成单条内容

        Args:
            scenario: 场景名称
            raw_data: 原始数据
            multi_round: 是否使用多轮生成
            translate: 是否翻译成英文

        Returns:
            生成结果，失败返回 None
        """
        self.stats["total"] += 1

        try:
            # 1. 生成中文内容
            logger.info(f"生成内容 - 场景: {scenario}")
            result = self.generator.generate(scenario, raw_data, multi_round=multi_round)
            content_zh = result["content"]

            # 2. 验证结构
            if not self.quality_checker.validate_structure(content_zh):
                logger.error("内容结构验证失败")
                self.stats["failed"] += 1
                return None

            # 3. 质量检测
            quality_result = self.quality_checker.check_quality(content_zh)
            logger.info(f"质量分数: {quality_result['total_score']}")

            if not quality_result["passed"]:
                logger.warning(f"质量检测未通过: {quality_result['details']}")
                self.stats["quality_failed"] += 1
                # 不直接返回，继续处理但标记质量问题

            # 4. 翻译成英文
            content_en = None
            if translate:
                try:
                    content_en = self.translator.translate(content_zh)
                except Exception as e:
                    logger.error(f"翻译失败: {e}")
                    self.stats["translation_failed"] += 1
                    # 翻译失败不影响中文内容

            # 5. 构建返回结果
            self.stats["success"] += 1

            return {
                "content_zh": content_zh,
                "content_en": content_en,
                "scenario": scenario,
                "ai_confidence": result.get("ai_confidence", 0.5),
                "quality_score": quality_result["total_score"],
                "quality_details": quality_result["details"],
                "rounds": result.get("rounds", 1),
                "critique": result.get("critique"),
            }

        except Exception as e:
            logger.error(f"生成内容失败: {e}")
            self.stats["failed"] += 1
            return None

    def save_to_db(self, result: Dict[str, Any]) -> bool:
        """
        保存到数据库

        Args:
            result: 生成结果

        Returns:
            是否成功
        """
        try:
            content_zh = result["content_zh"]
            content_en = result.get("content_en")

            # 准备数据
            data = {
                "content_type": "recommendation",
                "scenario": result["scenario"],
                "title_zh": content_zh.get("title"),
                "title_en": content_en.get("title") if content_en else None,
                "content_zh": content_zh,
                "content_en": content_en,
                "ai_confidence": result["ai_confidence"],
                "quality_score": result["quality_score"],
                "review_status": "pending",
                "created_at": datetime.now().isoformat(),  # 修复：使用 datetime.now() 而不是 utcnow()
            }

            # 写入数据库
            response = self.supabase.table("generated_content").insert(data).execute()

            logger.info(f"保存成功 - ID: {response.data[0]['id']}")
            return True

        except Exception as e:
            logger.error(f"保存到数据库失败: {e}")
            return False

    def process_batch(
        self, scenario: str, limit: int = 10, source: Optional[str] = None, multi_round: bool = True, translate: bool = True
    ) -> Dict[str, Any]:
        """
        批量处理

        Args:
            scenario: 场景名称
            limit: 处理数量
            source: 数据源
            multi_round: 是否使用多轮生成
            translate: 是否翻译

        Returns:
            处理统计
        """
        logger.info(f"开始批量处理 - 场景: {scenario}, 数量: {limit}")

        # 重置统计
        self.stats = {
            "total": 0,
            "success": 0,
            "failed": 0,
            "quality_failed": 0,
            "translation_failed": 0,
        }

        # 读取原始数据
        raw_data_list = self.fetch_raw_data(source=source, limit=limit)

        if not raw_data_list:
            logger.warning("没有可处理的数据")
            return self.stats

        # 批量生成
        for idx, raw_data in enumerate(raw_data_list, 1):
            logger.info(f"处理进度: {idx}/{len(raw_data_list)}")

            # 生成内容
            result = self.generate_content(scenario, raw_data, multi_round=multi_round, translate=translate)

            if result:
                # 保存到数据库
                self.save_to_db(result)

            # 避免限流
            if idx < len(raw_data_list):
                time.sleep(1)

        # 输出统计
        logger.info(f"批量处理完成 - 统计: {self.stats}")

        return self.stats

    def get_cost_summary(self) -> Dict[str, Any]:
        """
        获取成本统计

        Returns:
            成本统计信息
        """
        generator_cost = self.generator.get_cost_summary()
        translator_cost = self.translator.get_cost_summary()

        total_cost = generator_cost["total_cost"] + translator_cost["total_cost"]

        return {
            "generator": generator_cost,
            "translator": translator_cost,
            "total_cost": round(total_cost, 4),
            "stats": self.stats,
        }
