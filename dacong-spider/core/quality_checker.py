"""
内容质量检测器

检测 AI 生成内容的质量，包括：
- 完整性检查
- 敏感词检查
- 逻辑连贯性检查
- 数据支撑检查
- 用户友好性检查
"""
import json
import re
from typing import Any, Dict, List

from loguru import logger


class QualityChecker:
    """内容质量检测器"""

    # 敏感词列表（简化版，实际应该更完整）
    SENSITIVE_WORDS = [
        "政治",
        "习近平",
        "共产党",
        "台独",
        "藏独",
        "法轮功",
        "六四",
        "天安门",
    ]

    def __init__(self):
        """初始化质量检测器"""
        pass

    def check_quality(self, content: Dict[str, Any]) -> Dict[str, Any]:
        """
        检测内容质量

        Args:
            content: 生成的内容

        Returns:
            质量检测结果
        """
        scores = {}

        # 1. 完整性检查（30分）
        scores["completeness"] = self._check_completeness(content)

        # 2. 敏感词检查（20分）
        scores["safety"] = self._check_sensitive_words(content)

        # 3. 逻辑连贯性（20分）
        scores["coherence"] = self._check_coherence(content)

        # 4. 数据支撑（15分）
        scores["data_backed"] = self._check_data_support(content)

        # 5. 用户友好（15分）
        scores["user_friendly"] = self._check_user_friendly(content)

        # 总分（0-1）
        total_score = sum(scores.values()) / 100

        return {"total_score": round(total_score, 2), "details": scores, "passed": total_score >= 0.8}

    def _check_completeness(self, content: Dict[str, Any]) -> int:
        """
        完整性检查

        Args:
            content: 内容

        Returns:
            得分（0-30）
        """
        score = 0

        # 必填字段
        required_fields = ["title", "summary", "recommendations"]
        for field in required_fields:
            if field in content and content[field]:
                score += 10

        # 推荐数量（至少3个）
        recommendations = content.get("recommendations", [])
        if len(recommendations) >= 3:
            score += 5

        # 每个推荐的完整性
        if recommendations:
            first_rec = recommendations[0]
            required_rec_fields = ["name", "pros", "cons", "price", "access", "rating"]
            if all(k in first_rec for k in required_rec_fields):
                score += 5

        return min(score, 30)

    def _check_sensitive_words(self, content: Dict[str, Any]) -> int:
        """
        敏感词检查

        Args:
            content: 内容

        Returns:
            得分（0-20）
        """
        text = json.dumps(content, ensure_ascii=False)

        for word in self.SENSITIVE_WORDS:
            if word in text:
                logger.warning(f"发现敏感词: {word}")
                return 0  # 发现敏感词，直接0分

        return 20  # 无敏感词，满分

    def _check_coherence(self, content: Dict[str, Any]) -> int:
        """
        逻辑连贯性检查

        Args:
            content: 内容

        Returns:
            得分（0-20）
        """
        score = 20
        recommendations = content.get("recommendations", [])

        if not recommendations:
            return 0

        # 检查排名是否合理（rating应该递减或相近）
        ratings = [r.get("rating", 0) for r in recommendations]
        if len(ratings) >= 2:
            # 允许小幅波动，但不应该大幅上升
            for i in range(len(ratings) - 1):
                if ratings[i + 1] > ratings[i] + 0.3:  # 后面的比前面高太多
                    score -= 5
                    logger.debug(f"排名逻辑问题: rating[{i+1}] > rating[{i}]")
                    break

        # 检查是否有平替和免费方案
        has_alternative = any(
            "平替" in r.get("one_liner", "") or "性价比" in r.get("one_liner", "") for r in recommendations
        )
        has_free = any("免费" in r.get("price", "") for r in recommendations)

        if not has_alternative:
            score -= 5
            logger.debug("缺少平替方案")

        if not has_free:
            score -= 5
            logger.debug("缺少免费方案")

        return max(score, 0)

    def _check_data_support(self, content: Dict[str, Any]) -> int:
        """
        数据支撑检查

        Args:
            content: 内容

        Returns:
            得分（0-15）
        """
        score = 15
        recommendations = content.get("recommendations", [])

        for rec in recommendations:
            # 检查是否有具体的价格信息
            price = rec.get("price", "")
            if not price or price == "未知":
                score -= 3
                break

            # 检查是否有评分
            rating = rec.get("rating", 0)
            if rating <= 0 or rating > 5:
                score -= 3
                break

        return max(score, 0)

    def _check_user_friendly(self, content: Dict[str, Any]) -> int:
        """
        用户友好性检查

        Args:
            content: 内容

        Returns:
            得分（0-15）
        """
        score = 15
        recommendations = content.get("recommendations", [])

        for rec in recommendations:
            # 检查是否标注访问方式
            access = rec.get("access", "")
            if not access:
                score -= 3
                logger.debug(f"工具 {rec.get('name')} 缺少访问方式")
                break

            # 检查是否说明适合人群
            best_for = rec.get("best_for", "")
            if not best_for:
                score -= 3
                logger.debug(f"工具 {rec.get('name')} 缺少适合人群")
                break

        # 检查是否考虑国内用户
        has_domestic = any("国内可用" in r.get("access", "") for r in recommendations)
        if not has_domestic:
            score -= 4
            logger.debug("未考虑国内用户")

        return max(score, 0)

    def validate_structure(self, content: Dict[str, Any]) -> bool:
        """
        验证内容结构

        Args:
            content: 内容

        Returns:
            是否有效
        """
        # 检查必需字段
        required_fields = ["title", "summary", "recommendations"]
        for field in required_fields:
            if field not in content:
                logger.error(f"缺少必需字段: {field}")
                return False

        # 检查推荐列表
        recommendations = content.get("recommendations", [])
        if not isinstance(recommendations, list) or len(recommendations) == 0:
            logger.error("推荐列表为空或格式错误")
            return False

        # 检查每个推荐的结构
        required_rec_fields = ["rank", "name", "one_liner", "pros", "cons", "best_for", "price", "access", "rating"]
        for rec in recommendations:
            for field in required_rec_fields:
                if field not in rec:
                    logger.error(f"推荐项缺少字段: {field}")
                    return False

        return True
