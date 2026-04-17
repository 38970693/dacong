"""
周报生成器

功能：
- 聚合本周数据
- 分析 Star 增长趋势
- 识别新发布的工具
- 调用 Claude API 生成周报
"""
import json
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional

from anthropic import Anthropic
from loguru import logger

from config import config


class WeeklyGenerator:
    """周报生成器"""

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
        self.weekly_prompt = self._load_weekly_prompt()

    def _load_weekly_prompt(self) -> str:
        """加载周报 Prompt"""
        prompt_file = self.prompts_dir / "weekly_prompt.txt"
        if not prompt_file.exists():
            # 如果文件不存在，使用默认 Prompt
            return self._get_default_weekly_prompt()
        return prompt_file.read_text(encoding="utf-8")

    def _get_default_weekly_prompt(self) -> str:
        """获取默认周报 Prompt"""
        return """你是 AI 工具周报编辑，负责撰写每周精选周报。

# 编辑原则

1. **精选优质**
   - 只选择最值得关注的项目（5-10个）
   - 优先选择 Star 增长快、功能创新的项目
   - 考虑实用性和影响力

2. **客观准确**
   - 基于数据说话（Star 数、增长趋势）
   - 不夸大宣传
   - 说明适用场景

3. **用户友好**
   - 一句话说清项目亮点
   - 说明为什么值得关注
   - 提供访问方式

4. **结构清晰**
   - 本周最火：Star 增长最快的项目
   - 编辑推荐：精选优质项目
   - 榜单变化：排名变化明显的项目

# 输出格式

严格按照 JSON 格式输出：
{
  "title": "标题（吸引人，20字内）",
  "summary": "一句话总结本周亮点（50字内）",
  "week_start": "2026-04-14",
  "week_end": "2026-04-20",
  "sections": [
    {
      "section_title": "本周最火",
      "items": [
        {
          "name": "项目名",
          "one_liner": "一句话亮点（20字内）",
          "why_matters": "为什么值得关注（50字内）",
          "github_url": "https://github.com/xxx/xxx",
          "stars": 15000,
          "star_growth": 5000,
          "access": "国内可用/需翻墙"
        }
      ]
    },
    {
      "section_title": "编辑推荐",
      "items": [...]
    },
    {
      "section_title": "榜单变化",
      "items": [...]
    }
  ],
  "confidence": 0.92
}
"""

    def aggregate_weekly_data(
        self, raw_data: List[Dict[str, Any]], days: int = 7
    ) -> Dict[str, Any]:
        """
        聚合本周数据

        Args:
            raw_data: 原始数据列表
            days: 统计天数，默认7天

        Returns:
            聚合后的数据
        """
        logger.info(f"聚合最近 {days} 天的数据")

        # 计算时间范围
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)

        # 按项目聚合数据
        projects: Dict[str, Dict[str, Any]] = {}

        for item in raw_data:
            project_name = item.get("name") or item.get("repo_name")
            if not project_name:
                continue

            # 解析时间
            created_at = item.get("created_at")
            if isinstance(created_at, str):
                created_at = datetime.fromisoformat(created_at.replace("Z", "+00:00"))

            # 只统计指定时间范围内的数据
            if created_at and (created_at < start_date or created_at > end_date):
                continue

            if project_name not in projects:
                projects[project_name] = {
                    "name": project_name,
                    "github_url": item.get("github_url") or item.get("url"),
                    "description": item.get("description"),
                    "stars": item.get("stars", 0),
                    "star_history": [],
                    "first_seen": created_at.isoformat() if created_at else None,
                    "last_seen": created_at.isoformat() if created_at else None,
                }

            # 记录 Star 历史
            projects[project_name]["star_history"].append(
                {"date": created_at.isoformat() if created_at else None, "stars": item.get("stars", 0)}
            )

            # 更新最新数据
            if created_at and projects[project_name]["last_seen"]:
                last_seen = datetime.fromisoformat(projects[project_name]["last_seen"])
                if created_at > last_seen:
                    projects[project_name]["last_seen"] = created_at.isoformat()
                    projects[project_name]["stars"] = item.get("stars", 0)

        # 计算 Star 增长
        for project in projects.values():
            star_history = sorted(
                [h for h in project["star_history"] if h["date"]],
                key=lambda x: x["date"]
            )
            if len(star_history) >= 2:
                project["star_growth"] = (
                    star_history[-1]["stars"] - star_history[0]["stars"]
                )
            else:
                project["star_growth"] = 0

        # 按 Star 增长排序
        sorted_projects = sorted(
            projects.values(), key=lambda x: x["star_growth"], reverse=True
        )

        return {
            "week_start": start_date.strftime("%Y-%m-%d"),
            "week_end": end_date.strftime("%Y-%m-%d"),
            "total_projects": len(sorted_projects),
            "projects": sorted_projects[:50],  # 只保留前50个
        }

    def _build_weekly_prompt(self, data: Dict[str, Any]) -> str:
        """
        构建周报 Prompt

        Args:
            data: 聚合后的数据

        Returns:
            用户 Prompt
        """
        return f"""# 任务

基于以下数据，生成本周 AI 工具精选周报。

# 数据

周期：{data['week_start']} 至 {data['week_end']}
项目总数：{data['total_projects']}

## 项目列表（按 Star 增长排序）

{json.dumps(data['projects'][:20], ensure_ascii=False, indent=2)}

# 要求

1. 选择 5-10 个最值得关注的项目
2. 分为 3 个板块：
   - 本周最火（Star 增长最快的 2-3 个）
   - 编辑推荐（精选优质项目 3-5 个）
   - 榜单变化（排名变化明显的 1-2 个）
3. 每个项目说明：
   - 一句话亮点
   - 为什么值得关注
   - GitHub 链接
   - Star 数和增长
   - 访问方式（国内可用/需翻墙）
4. 自评置信度（0-1）

# 输出

严格按照 JSON 格式输出（参考系统 Prompt 中的格式）
"""

    def generate_weekly(self, raw_data: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        生成周报

        Args:
            raw_data: 原始数据列表

        Returns:
            生成的周报内容
        """
        logger.info("开始生成周报")

        # 1. 聚合数据
        aggregated_data = self.aggregate_weekly_data(raw_data)

        # 2. 构建 Prompt
        user_prompt = self._build_weekly_prompt(aggregated_data)

        # 3. 调用 Claude API
        response = self.client.messages.create(
            model=self.model,
            max_tokens=3000,
            system=[
                {
                    "type": "text",
                    "text": self.weekly_prompt,
                    "cache_control": {"type": "ephemeral"},
                }
            ],
            messages=[{"role": "user", "content": user_prompt}],
        )

        # 4. 解析响应
        content_text = response.content[0].text
        weekly_content = self._parse_json_response(content_text)

        # 5. 添加元数据
        return {
            "content": weekly_content,
            "ai_confidence": weekly_content.get("confidence", 0.5),
            "generated_at": datetime.now().isoformat(),
            "data_source": {
                "week_start": aggregated_data["week_start"],
                "week_end": aggregated_data["week_end"],
                "total_projects": aggregated_data["total_projects"],
            },
        }

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
