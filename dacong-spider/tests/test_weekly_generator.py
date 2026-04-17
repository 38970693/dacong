"""
周报生成器测试
"""
import json
from datetime import datetime, timedelta
from unittest.mock import Mock, patch

import pytest

from core.weekly_generator import WeeklyGenerator


@pytest.fixture
def mock_anthropic_client():
    """Mock Anthropic 客户端"""
    with patch("core.weekly_generator.Anthropic") as mock:
        yield mock


@pytest.fixture
def weekly_generator(mock_anthropic_client):
    """创建周报生成器实例"""
    return WeeklyGenerator(api_key="test-key")


@pytest.fixture
def sample_raw_data():
    """示例原始数据"""
    now = datetime.now()
    return [
        {
            "name": "DeepSeek-V3",
            "github_url": "https://github.com/deepseek-ai/DeepSeek-V3",
            "description": "强大的开源大模型",
            "stars": 15000,
            "created_at": (now - timedelta(days=2)).isoformat(),
        },
        {
            "name": "Claude Code",
            "github_url": "https://github.com/anthropics/claude-code",
            "description": "AI 编程助手",
            "stars": 12000,
            "created_at": (now - timedelta(days=5)).isoformat(),
        },
        {
            "name": "Cursor",
            "github_url": "https://github.com/getcursor/cursor",
            "description": "AI 代码编辑器",
            "stars": 10000,
            "created_at": (now - timedelta(days=1)).isoformat(),
        },
    ]


class TestWeeklyGenerator:
    """周报生成器测试"""

    def test_init_without_api_key(self):
        """测试：没有 API Key 时抛出异常"""
        with patch("core.weekly_generator.config") as mock_config:
            mock_config.anthropic_api_key = None
            with pytest.raises(ValueError, match="ANTHROPIC_API_KEY 未配置"):
                WeeklyGenerator()

    def test_init_with_api_key(self, mock_anthropic_client):
        """测试：使用 API Key 初始化"""
        generator = WeeklyGenerator(api_key="test-key")
        assert generator.api_key == "test-key"
        assert generator.model == "claude-3-5-sonnet-20241022"

    def test_aggregate_weekly_data(self, weekly_generator, sample_raw_data):
        """测试：聚合周报数据"""
        result = weekly_generator.aggregate_weekly_data(sample_raw_data, days=7)

        assert "week_start" in result
        assert "week_end" in result
        assert "total_projects" in result
        assert "projects" in result

        # 验证项目数量
        assert result["total_projects"] == 3
        assert len(result["projects"]) == 3

        # 验证项目按 Star 增长排序
        projects = result["projects"]
        assert projects[0]["name"] in ["DeepSeek-V3", "Claude Code", "Cursor"]

    def test_aggregate_weekly_data_with_star_growth(
        self, weekly_generator, sample_raw_data
    ):
        """测试：计算 Star 增长"""
        # 添加历史数据
        now = datetime.now()
        sample_raw_data.extend(
            [
                {
                    "name": "DeepSeek-V3",
                    "github_url": "https://github.com/deepseek-ai/DeepSeek-V3",
                    "stars": 10000,
                    "created_at": (now - timedelta(days=6)).isoformat(),
                },
            ]
        )

        result = weekly_generator.aggregate_weekly_data(sample_raw_data, days=7)

        # 找到 DeepSeek-V3 项目
        deepseek = next(
            (p for p in result["projects"] if p["name"] == "DeepSeek-V3"), None
        )
        assert deepseek is not None
        assert deepseek["star_growth"] == 5000  # 15000 - 10000

    def test_build_weekly_prompt(self, weekly_generator):
        """测试：构建周报 Prompt"""
        data = {
            "week_start": "2026-04-14",
            "week_end": "2026-04-20",
            "total_projects": 3,
            "projects": [
                {
                    "name": "Test Project",
                    "stars": 1000,
                    "star_growth": 500,
                }
            ],
        }

        prompt = weekly_generator._build_weekly_prompt(data)

        assert "2026-04-14" in prompt
        assert "2026-04-20" in prompt
        assert "Test Project" in prompt
        assert "本周 AI 工具精选周报" in prompt

    def test_parse_json_response(self, weekly_generator):
        """测试：解析 JSON 响应"""
        # 测试普通 JSON
        json_text = '{"title": "Test"}'
        result = weekly_generator._parse_json_response(json_text)
        assert result["title"] == "Test"

        # 测试带 markdown 代码块的 JSON
        json_text = '```json\n{"title": "Test"}\n```'
        result = weekly_generator._parse_json_response(json_text)
        assert result["title"] == "Test"

        # 测试带 ``` 的 JSON
        json_text = '```\n{"title": "Test"}\n```'
        result = weekly_generator._parse_json_response(json_text)
        assert result["title"] == "Test"

    def test_generate_weekly(
        self, weekly_generator, sample_raw_data, mock_anthropic_client
    ):
        """测试：生成周报"""
        # Mock API 响应
        mock_response = Mock()
        mock_response.content = [
            Mock(
                text=json.dumps(
                    {
                        "title": "本周 AI 工具精选",
                        "summary": "本周最值得关注的 AI 项目",
                        "week_start": "2026-04-14",
                        "week_end": "2026-04-20",
                        "sections": [
                            {
                                "section_title": "本周最火",
                                "items": [
                                    {
                                        "name": "DeepSeek-V3",
                                        "one_liner": "强大的开源大模型",
                                        "why_matters": "性能超越 GPT-4",
                                        "github_url": "https://github.com/deepseek-ai/DeepSeek-V3",
                                        "stars": 15000,
                                        "star_growth": 5000,
                                        "access": "国内可用",
                                    }
                                ],
                            }
                        ],
                        "confidence": 0.92,
                    }
                )
            )
        ]

        mock_client_instance = mock_anthropic_client.return_value
        mock_client_instance.messages.create.return_value = mock_response

        # 生成周报
        result = weekly_generator.generate_weekly(sample_raw_data)

        # 验证结果
        assert "content" in result
        assert "ai_confidence" in result
        assert "generated_at" in result
        assert "data_source" in result

        content = result["content"]
        assert content["title"] == "本周 AI 工具精选"
        assert content["confidence"] == 0.92
        assert len(content["sections"]) == 1

        # 验证 API 调用
        mock_client_instance.messages.create.assert_called_once()
        call_args = mock_client_instance.messages.create.call_args
        assert call_args.kwargs["model"] == "claude-3-5-sonnet-20241022"
        assert call_args.kwargs["max_tokens"] == 3000

    def test_generate_weekly_with_empty_data(self, weekly_generator):
        """测试：空数据生成周报"""
        result = weekly_generator.aggregate_weekly_data([], days=7)

        assert result["total_projects"] == 0
        assert len(result["projects"]) == 0

    def test_load_default_weekly_prompt(self, weekly_generator):
        """测试：加载默认周报 Prompt"""
        prompt = weekly_generator._get_default_weekly_prompt()

        assert "AI 工具周报编辑" in prompt
        assert "本周最火" in prompt
        assert "编辑推荐" in prompt
        assert "榜单变化" in prompt
        assert "JSON 格式" in prompt
