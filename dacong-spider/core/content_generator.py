"""
AI 内容生成器

使用 Claude API 生成高质量推荐内容，支持：
- Prompt Caching（降低成本）
- 多轮生成（初稿 → 批评 → 改进）
- 质量检测
"""
import json
import time
from pathlib import Path
from typing import Any, Dict, List, Optional

from anthropic import Anthropic
from loguru import logger

from config import config


class ContentGenerator:
    """AI 内容生成器"""

    def __init__(self, api_key: Optional[str] = None):
        """
        初始化生成器

        Args:
            api_key: Anthropic API Key，默认从配置读取
        """
        self.api_key = api_key or config.anthropic_api_key
        if not self.api_key:
            raise ValueError("ANTHROPIC_API_KEY 未配置")

        self.client = Anthropic(api_key=self.api_key)
        self.model = "claude-3-5-sonnet-20241022"

        # 加载 Prompt 模板
        self.prompts_dir = Path(__file__).parent.parent / "prompts"
        self.system_prompt = self._load_system_prompt()
        self.few_shot_examples = self._load_few_shot_examples()

        # 成本监控
        self.total_input_tokens = 0
        self.total_output_tokens = 0
        self.cached_tokens = 0

    def _load_system_prompt(self) -> str:
        """加载系统 Prompt"""
        prompt_file = self.prompts_dir / "system_prompt.txt"
        if not prompt_file.exists():
            raise FileNotFoundError(f"系统 Prompt 文件不存在: {prompt_file}")
        return prompt_file.read_text(encoding="utf-8")

    def _load_few_shot_examples(self) -> str:
        """加载 Few-shot 样本"""
        examples_file = self.prompts_dir / "few_shot_examples.json"
        if not examples_file.exists():
            raise FileNotFoundError(f"Few-shot 样本文件不存在: {examples_file}")

        examples = json.loads(examples_file.read_text(encoding="utf-8"))

        # 格式化为文本
        formatted = []
        for idx, example in enumerate(examples, 1):
            formatted.append(f"# 示例{idx}：{example['scenario']}场景\n")
            formatted.append(f"场景：{example['scenario']}\n")
            formatted.append(f"数据：\n{json.dumps(example['input_data'], ensure_ascii=False, indent=2)}\n")
            formatted.append(f"\n输出：\n{json.dumps(example['output'], ensure_ascii=False, indent=2)}\n")
            formatted.append("\n---\n\n")

        return "".join(formatted)

    def _build_user_prompt(self, scenario: str, data: Dict[str, Any]) -> str:
        """
        构建用户 Prompt

        Args:
            scenario: 场景名称
            data: 原始数据

        Returns:
            用户 Prompt
        """
        return f"""# 任务

基于以下数据，为"{scenario}"场景生成推荐。

# 数据

{json.dumps(data, ensure_ascii=False, indent=2)}

# 要求

1. 推荐3个工具（最佳、平替、免费）
2. 每个工具说明优缺点（各2-3个）
3. 标注价格和访问方式
4. 说明适合人群
5. 给出推荐指数（1-5星）
6. 自评置信度（0-1）

# 输出

严格按照JSON格式输出：
{{
  "title": "标题（吸引人，20字内）",
  "summary": "一句话总结（50字内）",
  "recommendations": [
    {{
      "rank": 1,
      "name": "工具名",
      "one_liner": "一句话描述（20字内）",
      "pros": ["优点1", "优点2"],
      "cons": ["缺点1"],
      "best_for": "最适合xxx",
      "price": "价格",
      "access": "国内可用/需翻墙",
      "rating": 4.5
    }}
  ],
  "confidence": 0.92
}}
"""

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

    def generate_draft(self, scenario: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """
        生成初稿

        Args:
            scenario: 场景名称
            data: 原始数据

        Returns:
            生成的内容
        """
        logger.info(f"生成初稿 - 场景: {scenario}")

        user_prompt = self._build_user_prompt(scenario, data)

        response = self.client.messages.create(
            model=self.model,
            max_tokens=2000,
            system=[
                {
                    "type": "text",
                    "text": self.system_prompt,
                    "cache_control": {"type": "ephemeral"},  # 缓存系统 Prompt
                },
                {
                    "type": "text",
                    "text": self.few_shot_examples,
                    "cache_control": {"type": "ephemeral"},  # 缓存 Few-shot 样本
                },
            ],
            messages=[{"role": "user", "content": user_prompt}],
        )

        # 记录 token 使用
        self._track_usage(response)

        content_text = response.content[0].text
        return self._parse_json_response(content_text)

    def critique_draft(self, draft: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        批评初稿

        Args:
            draft: 初稿内容

        Returns:
            批评意见列表
        """
        logger.info("批评初稿")

        critique_prompt = f"""你是严格的内容审核专家。审查以下推荐文章，找出问题：

{json.dumps(draft, ensure_ascii=False, indent=2)}

# 审查维度

1. **准确性**
   - 价格信息是否准确？
   - 功能描述是否夸大？
   - 优缺点是否客观？

2. **完整性**
   - 是否缺少关键信息？
   - 是否需要补充说明？

3. **逻辑性**
   - 推荐理由是否充分？
   - 排名是否合理？

4. **用户友好**
   - 是否考虑国内用户？
   - 是否提供平替方案？

# 输出

列出所有问题，每个问题说明：
1. 问题描述
2. 严重程度（高/中/低）
3. 改进建议

格式：JSON数组
[
  {{
    "issue": "问题描述",
    "severity": "高/中/低",
    "suggestion": "改进建议"
  }}
]
"""

        response = self.client.messages.create(
            model=self.model, max_tokens=1000, messages=[{"role": "user", "content": critique_prompt}]
        )

        self._track_usage(response)

        content_text = response.content[0].text
        return self._parse_json_response(content_text)

    def improve_draft(self, draft: Dict[str, Any], critique: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        改进初稿

        Args:
            draft: 初稿内容
            critique: 批评意见

        Returns:
            改进后的内容
        """
        logger.info("改进初稿")

        improve_prompt = f"""基于以下批评意见，改进推荐文章：

# 原文
{json.dumps(draft, ensure_ascii=False, indent=2)}

# 批评意见
{json.dumps(critique, ensure_ascii=False, indent=2)}

# 要求

1. 修复所有"高"严重程度的问题
2. 尽量修复"中"严重程度的问题
3. 保持原有结构和风格
4. 输出改进后的完整JSON

# 输出

改进后的JSON（与原文格式相同）
"""

        response = self.client.messages.create(
            model=self.model, max_tokens=2000, messages=[{"role": "user", "content": improve_prompt}]
        )

        self._track_usage(response)

        content_text = response.content[0].text
        return self._parse_json_response(content_text)

    def generate(self, scenario: str, data: Dict[str, Any], multi_round: bool = True) -> Dict[str, Any]:
        """
        生成内容（完整流程）

        Args:
            scenario: 场景名称
            data: 原始数据
            multi_round: 是否使用多轮生成

        Returns:
            生成结果，包含 content 和 metadata
        """
        # 第一轮：生成初稿
        draft = self.generate_draft(scenario, data)

        if not multi_round:
            return {"content": draft, "ai_confidence": draft.get("confidence", 0.5), "rounds": 1}

        # 第二轮：批评
        critique = self.critique_draft(draft)

        # 如果没有问题，直接返回初稿
        if not critique or len(critique) == 0:
            logger.info("初稿无问题，直接返回")
            return {"content": draft, "ai_confidence": draft.get("confidence", 0.5), "rounds": 1}

        # 第三轮：改进
        final = self.improve_draft(draft, critique)

        return {
            "content": final,
            "ai_confidence": final.get("confidence", 0.5),
            "rounds": 3,
            "critique": critique,
        }

    def _track_usage(self, response) -> None:
        """记录 token 使用"""
        usage = response.usage
        self.total_input_tokens += usage.input_tokens
        self.total_output_tokens += usage.output_tokens

        if hasattr(usage, "cache_read_input_tokens"):
            self.cached_tokens += usage.cache_read_input_tokens

        if hasattr(usage, "cache_creation_input_tokens"):
            logger.debug(f"缓存创建: {usage.cache_creation_input_tokens} tokens")

    def get_cost_summary(self) -> Dict[str, Any]:
        """
        获取成本统计

        Returns:
            成本统计信息
        """
        # Claude 3.5 Sonnet 定价（2024年10月）
        input_price_per_m = 3.0  # $3/M tokens
        output_price_per_m = 15.0  # $15/M tokens
        cache_read_price_per_m = 0.3  # $0.3/M tokens

        input_cost = (self.total_input_tokens - self.cached_tokens) * input_price_per_m / 1_000_000
        output_cost = self.total_output_tokens * output_price_per_m / 1_000_000
        cache_cost = self.cached_tokens * cache_read_price_per_m / 1_000_000

        total_cost = input_cost + output_cost + cache_cost
        cache_savings = self.cached_tokens * (input_price_per_m - cache_read_price_per_m) / 1_000_000

        return {
            "total_input_tokens": self.total_input_tokens,
            "total_output_tokens": self.total_output_tokens,
            "cached_tokens": self.cached_tokens,
            "input_cost": round(input_cost, 4),
            "output_cost": round(output_cost, 4),
            "cache_cost": round(cache_cost, 4),
            "total_cost": round(total_cost, 4),
            "cache_savings": round(cache_savings, 4),
        }
