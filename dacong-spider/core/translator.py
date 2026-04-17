"""
内容翻译器

使用 Claude API 将中文内容翻译成英文，保持：
- JSON 结构不变
- 专业术语准确
- 符合英文习惯
"""
import json
import re
from typing import Any, Dict, Optional

from anthropic import Anthropic
from loguru import logger

from config import config


class Translator:
    """内容翻译器"""

    TRANSLATION_PROMPT = """你是专业的AI工具评测翻译专家。
将以下中文推荐翻译成英文。

# 翻译原则

1. **保持专业术语**
   - "Prompt" 不翻译
   - "API" 不翻译
   - "Token" 不翻译
   - "AI" 不翻译

2. **符合英文习惯**
   - 不要直译
   - 使用地道表达
   - 保持专业性

3. **保持结构**
   - JSON结构不变
   - 字段名不变
   - 数组长度不变

# 原文（中文）

{chinese_content}

# 输出

翻译后的JSON（结构与原文相同，只翻译值不翻译键）
"""

    def __init__(self, api_key: Optional[str] = None):
        """
        初始化翻译器

        Args:
            api_key: Anthropic API Key，默认从配置读取
        """
        self.api_key = api_key or config.anthropic_api_key
        if not self.api_key:
            raise ValueError("ANTHROPIC_API_KEY 未配置")

        self.client = Anthropic(api_key=self.api_key)
        self.model = "claude-3-5-sonnet-20241022"

        # 成本监控
        self.total_input_tokens = 0
        self.total_output_tokens = 0

    def translate(self, chinese_content: Dict[str, Any]) -> Dict[str, Any]:
        """
        翻译内容

        Args:
            chinese_content: 中文内容

        Returns:
            英文内容
        """
        logger.info("开始翻译内容")

        prompt = self.TRANSLATION_PROMPT.format(
            chinese_content=json.dumps(chinese_content, ensure_ascii=False, indent=2)
        )

        response = self.client.messages.create(
            model=self.model, max_tokens=2000, messages=[{"role": "user", "content": prompt}]
        )

        # 记录 token 使用
        self._track_usage(response)

        content_text = response.content[0].text
        english_content = self._parse_json_response(content_text)

        # 验证翻译质量
        if not self.validate_translation(chinese_content, english_content):
            logger.warning("翻译质量验证失败")

        return english_content

    def _parse_json_response(self, text: str) -> Dict[str, Any]:
        """
        解析 JSON 响应

        Args:
            text: 响应文本

        Returns:
            解析后的 JSON
        """
        # 移除可能的 markdown 代码块标记
        text = text.strip()
        if text.startswith("```json"):
            text = text[7:]
        if text.startswith("```"):
            text = text[3:]
        if text.endswith("```"):
            text = text[:-3]

        return json.loads(text.strip())

    def validate_translation(self, chinese: Dict[str, Any], english: Dict[str, Any]) -> bool:
        """
        验证翻译质量

        Args:
            chinese: 中文内容
            english: 英文内容

        Returns:
            是否通过验证
        """
        # 检查结构是否一致
        if len(chinese.get("recommendations", [])) != len(english.get("recommendations", [])):
            logger.error("推荐数量不一致")
            return False

        # 检查关键字段是否存在
        for key in ["title", "summary", "recommendations"]:
            if key not in english:
                logger.error(f"缺少关键字段: {key}")
                return False

        # 检查是否有未翻译的中文（允许少量中文，如品牌名）
        text = json.dumps(english, ensure_ascii=False)
        chinese_chars = re.findall(r"[\u4e00-\u9fff]+", text)

        if len(chinese_chars) > 5:  # 允许少量中文
            logger.warning(f"发现较多未翻译的中文: {chinese_chars[:5]}")
            return False

        # 检查每个推荐的结构
        for i, (cn_rec, en_rec) in enumerate(zip(chinese["recommendations"], english["recommendations"])):
            # 检查字段是否一致
            if set(cn_rec.keys()) != set(en_rec.keys()):
                logger.error(f"推荐 {i+1} 的字段不一致")
                return False

            # 检查数组长度是否一致
            if len(cn_rec.get("pros", [])) != len(en_rec.get("pros", [])):
                logger.error(f"推荐 {i+1} 的优点数量不一致")
                return False

            if len(cn_rec.get("cons", [])) != len(en_rec.get("cons", [])):
                logger.error(f"推荐 {i+1} 的缺点数量不一致")
                return False

        logger.info("翻译质量验证通过")
        return True

    def _track_usage(self, response) -> None:
        """记录 token 使用"""
        usage = response.usage
        self.total_input_tokens += usage.input_tokens
        self.total_output_tokens += usage.output_tokens

    def get_cost_summary(self) -> Dict[str, Any]:
        """
        获取成本统计

        Returns:
            成本统计信息
        """
        # Claude 3.5 Sonnet 定价
        input_price_per_m = 3.0  # $3/M tokens
        output_price_per_m = 15.0  # $15/M tokens

        input_cost = self.total_input_tokens * input_price_per_m / 1_000_000
        output_cost = self.total_output_tokens * output_price_per_m / 1_000_000
        total_cost = input_cost + output_cost

        return {
            "total_input_tokens": self.total_input_tokens,
            "total_output_tokens": self.total_output_tokens,
            "input_cost": round(input_cost, 4),
            "output_cost": round(output_cost, 4),
            "total_cost": round(total_cost, 4),
        }
