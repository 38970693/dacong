"""
AI 内容生成器测试

测试 ContentGenerator、QualityChecker、Translator 和 GenerationPipeline
"""
import json
from unittest.mock import MagicMock, Mock, patch

import pytest

from core.content_generator import ContentGenerator
from core.generation_pipeline import GenerationPipeline
from core.quality_checker import QualityChecker
from core.translator import Translator


# ── 测试数据 ──────────────────────────────────────


@pytest.fixture
def sample_content():
    """示例生成内容"""
    return {
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


@pytest.fixture
def sample_raw_data():
    """示例原始数据"""
    return {
        "tools": [
            {"name": "Claude Code", "stars": 15000, "price": "$20/月"},
            {"name": "Cursor", "stars": 12000, "price": "$20/月"},
            {"name": "GitHub Copilot", "stars": 8000, "price": "$10/月"},
        ]
    }


# ── QualityChecker 测试 ──────────────────────────────────────


class TestQualityChecker:
    """质量检测器测试"""

    def test_validate_structure_valid(self, sample_content):
        """测试结构验证 - 有效内容"""
        checker = QualityChecker()
        assert checker.validate_structure(sample_content) is True

    def test_validate_structure_missing_field(self, sample_content):
        """测试结构验证 - 缺少字段"""
        checker = QualityChecker()
        invalid_content = sample_content.copy()
        del invalid_content["title"]
        assert checker.validate_structure(invalid_content) is False

    def test_validate_structure_empty_recommendations(self, sample_content):
        """测试结构验证 - 空推荐列表"""
        checker = QualityChecker()
        invalid_content = sample_content.copy()
        invalid_content["recommendations"] = []
        assert checker.validate_structure(invalid_content) is False

    def test_check_completeness_full_score(self, sample_content):
        """测试完整性检查 - 满分"""
        checker = QualityChecker()
        score = checker._check_completeness(sample_content)
        assert score == 30

    def test_check_sensitive_words_clean(self, sample_content):
        """测试敏感词检查 - 无敏感词"""
        checker = QualityChecker()
        score = checker._check_sensitive_words(sample_content)
        assert score == 20

    def test_check_sensitive_words_found(self, sample_content):
        """测试敏感词检查 - 发现敏感词"""
        checker = QualityChecker()
        content_with_sensitive = sample_content.copy()
        content_with_sensitive["title"] = "政治相关内容"
        score = checker._check_sensitive_words(content_with_sensitive)
        assert score == 0

    def test_check_coherence_good(self, sample_content):
        """测试逻辑连贯性 - 良好"""
        checker = QualityChecker()
        score = checker._check_coherence(sample_content)
        assert score >= 10  # 应该有合理的分数

    def test_check_quality_passed(self, sample_content):
        """测试质量检测 - 通过"""
        checker = QualityChecker()
        result = checker.check_quality(sample_content)
        assert result["total_score"] >= 0.8
        assert result["passed"] is True

    def test_check_quality_details(self, sample_content):
        """测试质量检测 - 详细信息"""
        checker = QualityChecker()
        result = checker.check_quality(sample_content)
        assert "completeness" in result["details"]
        assert "safety" in result["details"]
        assert "coherence" in result["details"]


# ── ContentGenerator 测试 ──────────────────────────────────────


class TestContentGenerator:
    """内容生成器测试"""

    @patch("core.content_generator.Anthropic")
    def test_init_with_api_key(self, mock_anthropic):
        """测试初始化 - 提供 API Key"""
        generator = ContentGenerator(api_key="test-key")
        assert generator.api_key == "test-key"
        mock_anthropic.assert_called_once_with(api_key="test-key")

    @patch("core.content_generator.Anthropic")
    def test_init_without_api_key_raises(self, mock_anthropic):
        """测试初始化 - 未提供 API Key"""
        with patch("core.content_generator.config") as mock_config:
            mock_config.anthropic_api_key = ""
            with pytest.raises(ValueError, match="ANTHROPIC_API_KEY 未配置"):
                ContentGenerator()

    @patch("core.content_generator.Anthropic")
    def test_parse_json_response_clean(self, mock_anthropic):
        """测试 JSON 解析 - 干净的 JSON"""
        generator = ContentGenerator(api_key="test-key")
        json_str = '{"title": "test"}'
        result = generator._parse_json_response(json_str)
        assert result == {"title": "test"}

    @patch("core.content_generator.Anthropic")
    def test_parse_json_response_with_markdown(self, mock_anthropic):
        """测试 JSON 解析 - 带 Markdown 标记"""
        generator = ContentGenerator(api_key="test-key")
        json_str = '```json\n{"title": "test"}\n```'
        result = generator._parse_json_response(json_str)
        assert result == {"title": "test"}

    @patch("core.content_generator.Anthropic")
    def test_build_user_prompt(self, mock_anthropic, sample_raw_data):
        """测试构建用户 Prompt"""
        generator = ContentGenerator(api_key="test-key")
        prompt = generator._build_user_prompt("coding", sample_raw_data)
        assert "coding" in prompt
        assert "Claude Code" in prompt
        assert "JSON" in prompt

    @patch("core.content_generator.Anthropic")
    def test_generate_draft(self, mock_anthropic, sample_raw_data, sample_content):
        """测试生成初稿"""
        # Mock API 响应
        mock_response = Mock()
        mock_response.content = [Mock(text=json.dumps(sample_content))]
        mock_response.usage = Mock(
            input_tokens=100,
            output_tokens=200,
            cache_read_input_tokens=50,  # 修复：使用整数而不是 Mock
            cache_creation_input_tokens=0
        )

        mock_client = Mock()
        mock_client.messages.create.return_value = mock_response
        mock_anthropic.return_value = mock_client

        generator = ContentGenerator(api_key="test-key")
        result = generator.generate_draft("coding", sample_raw_data)

        assert result["title"] == sample_content["title"]
        assert len(result["recommendations"]) == 3

    @patch("core.content_generator.Anthropic")
    def test_get_cost_summary(self, mock_anthropic):
        """测试成本统计"""
        generator = ContentGenerator(api_key="test-key")
        generator.total_input_tokens = 1000
        generator.total_output_tokens = 500
        generator.cached_tokens = 200

        summary = generator.get_cost_summary()
        assert summary["total_input_tokens"] == 1000
        assert summary["total_output_tokens"] == 500
        assert summary["cached_tokens"] == 200
        assert summary["total_cost"] > 0

    @patch("core.content_generator.Anthropic")
    def test_critique_draft(self, mock_anthropic, sample_content):
        """测试批评初稿"""
        mock_response = Mock()
        mock_response.content = [Mock(text='[{"issue": "测试问题", "severity": "高", "suggestion": "改进建议"}]')]
        mock_response.usage = Mock(input_tokens=100, output_tokens=50, cache_read_input_tokens=0)

        mock_client = Mock()
        mock_client.messages.create.return_value = mock_response
        mock_anthropic.return_value = mock_client

        generator = ContentGenerator(api_key="test-key")
        critique = generator.critique_draft(sample_content)

        assert isinstance(critique, list)
        assert len(critique) > 0

    @patch("core.content_generator.Anthropic")
    def test_improve_draft(self, mock_anthropic, sample_content):
        """测试改进初稿"""
        critique = [{"issue": "测试问题", "severity": "高", "suggestion": "改进建议"}]

        mock_response = Mock()
        mock_response.content = [Mock(text=json.dumps(sample_content))]
        mock_response.usage = Mock(input_tokens=100, output_tokens=200, cache_read_input_tokens=0)

        mock_client = Mock()
        mock_client.messages.create.return_value = mock_response
        mock_anthropic.return_value = mock_client

        generator = ContentGenerator(api_key="test-key")
        improved = generator.improve_draft(sample_content, critique)

        assert improved["title"] == sample_content["title"]

    @patch("core.content_generator.Anthropic")
    def test_generate_multi_round(self, mock_anthropic, sample_raw_data, sample_content):
        """测试多轮生成"""
        mock_response = Mock()
        mock_response.content = [Mock(text=json.dumps(sample_content))]
        mock_response.usage = Mock(input_tokens=100, output_tokens=200, cache_read_input_tokens=0, cache_creation_input_tokens=0)

        mock_critique_response = Mock()
        mock_critique_response.content = [Mock(text='[{"issue": "测试", "severity": "中", "suggestion": "建议"}]')]
        mock_critique_response.usage = Mock(input_tokens=50, output_tokens=30, cache_read_input_tokens=0)

        mock_client = Mock()
        mock_client.messages.create.side_effect = [mock_response, mock_critique_response, mock_response]
        mock_anthropic.return_value = mock_client

        generator = ContentGenerator(api_key="test-key")
        result = generator.generate("coding", sample_raw_data, multi_round=True)

        assert result["content"]["title"] == sample_content["title"]
        assert result["rounds"] == 3

    @patch("core.content_generator.Anthropic")
    def test_generate_single_round(self, mock_anthropic, sample_raw_data, sample_content):
        """测试单轮生成"""
        mock_response = Mock()
        mock_response.content = [Mock(text=json.dumps(sample_content))]
        mock_response.usage = Mock(input_tokens=100, output_tokens=200, cache_read_input_tokens=0)

        mock_client = Mock()
        mock_client.messages.create.return_value = mock_response
        mock_anthropic.return_value = mock_client

        generator = ContentGenerator(api_key="test-key")
        result = generator.generate("coding", sample_raw_data, multi_round=False)

        assert result["content"]["title"] == sample_content["title"]
        assert result["rounds"] == 1


# ── Translator 测试 ──────────────────────────────────────


class TestTranslator:
    """翻译器测试"""

    @patch("core.translator.Anthropic")
    def test_validate_translation_valid(self, mock_anthropic, sample_content):
        """测试翻译验证 - 有效翻译"""
        translator = Translator(api_key="test-key")

        english_content = {
            "title": "Best AI Coding Assistants",
            "summary": "Top 3 coding assistants based on capability, price, and usability",
            "recommendations": [
                {
                    "rank": 1,
                    "name": "Claude Code",
                    "one_liner": "Most powerful AI coding assistant",
                    "pros": ["High code quality", "Strong reasoning"],
                    "cons": ["Expensive"],
                    "best_for": "Professional developers",
                    "price": "$20/month",
                    "access": "VPN required",
                    "rating": 4.8,
                },
                {
                    "rank": 2,
                    "name": "Cursor",
                    "one_liner": "Best value option",
                    "pros": ["Available in China", "Reasonable price"],
                    "cons": ["Slightly worse than Claude"],
                    "best_for": "Individual developers",
                    "price": "$20/month",
                    "access": "Available in China",
                    "rating": 4.5,
                },
                {
                    "rank": 3,
                    "name": "GitHub Copilot",
                    "one_liner": "Established tool",
                    "pros": ["Cheap", "Free for students"],
                    "cons": ["Average capability"],
                    "best_for": "Students",
                    "price": "$10/month",
                    "access": "VPN required",
                    "rating": 4.2,
                },
            ],
            "confidence": 0.92,
        }

        assert translator.validate_translation(sample_content, english_content) is True

    @patch("core.translator.Anthropic")
    def test_validate_translation_missing_field(self, mock_anthropic, sample_content):
        """测试翻译验证 - 缺少字段"""
        translator = Translator(api_key="test-key")
        invalid_english = {"title": "Test"}
        assert translator.validate_translation(sample_content, invalid_english) is False

    @patch("core.translator.Anthropic")
    def test_validate_translation_different_length(self, mock_anthropic, sample_content):
        """测试翻译验证 - 推荐数量不一致"""
        translator = Translator(api_key="test-key")
        invalid_english = sample_content.copy()
        invalid_english["recommendations"] = invalid_english["recommendations"][:2]
        assert translator.validate_translation(sample_content, invalid_english) is False

    @patch("core.translator.Anthropic")
    def test_translate(self, mock_anthropic, sample_content):
        """测试翻译"""
        english_content = sample_content.copy()
        english_content["title"] = "Best AI Coding Assistants"

        mock_response = Mock()
        mock_response.content = [Mock(text=json.dumps(english_content))]
        mock_response.usage = Mock(input_tokens=100, output_tokens=150)

        mock_client = Mock()
        mock_client.messages.create.return_value = mock_response
        mock_anthropic.return_value = mock_client

        translator = Translator(api_key="test-key")
        result = translator.translate(sample_content)

        assert result["title"] == "Best AI Coding Assistants"

    @patch("core.translator.Anthropic")
    def test_get_cost_summary_translator(self, mock_anthropic):
        """测试翻译器成本统计"""
        translator = Translator(api_key="test-key")
        translator.total_input_tokens = 500
        translator.total_output_tokens = 300

        summary = translator.get_cost_summary()
        assert summary["total_input_tokens"] == 500
        assert summary["total_output_tokens"] == 300
        assert summary["total_cost"] > 0


# ── GenerationPipeline 测试 ──────────────────────────────────────


class TestGenerationPipeline:
    """生成管道测试"""

    @patch("core.generation_pipeline.create_client")
    def test_init(self, mock_create_client):
        """测试初始化"""
        pipeline = GenerationPipeline()
        assert pipeline.generator is not None
        assert pipeline.quality_checker is not None
        assert pipeline.translator is not None

    @patch("core.generation_pipeline.create_client")
    def test_fetch_raw_data(self, mock_create_client):
        """测试读取原始数据"""
        mock_supabase = Mock()
        mock_response = Mock()
        mock_response.data = [{"id": 1, "source": "github"}]

        mock_supabase.table.return_value.select.return_value.order.return_value.limit.return_value.execute.return_value = (
            mock_response
        )

        pipeline = GenerationPipeline(supabase_client=mock_supabase)
        data = pipeline.fetch_raw_data(limit=10)

        assert len(data) == 1
        assert data[0]["source"] == "github"

    @patch("core.generation_pipeline.create_client")
    def test_generate_content_success(self, mock_create_client, sample_raw_data, sample_content):
        """测试生成内容 - 成功"""
        # Mock 生成器
        mock_generator = Mock()
        mock_generator.generate.return_value = {"content": sample_content, "ai_confidence": 0.92, "rounds": 3}

        # Mock 质量检测器
        mock_checker = Mock()
        mock_checker.validate_structure.return_value = True
        mock_checker.check_quality.return_value = {"total_score": 0.85, "passed": True, "details": {}}

        # Mock 翻译器
        mock_translator = Mock()
        mock_translator.translate.return_value = sample_content  # 简化，实际应该是英文

        pipeline = GenerationPipeline(
            generator=mock_generator, quality_checker=mock_checker, translator=mock_translator
        )

        result = pipeline.generate_content("coding", sample_raw_data)

        assert result is not None
        assert result["content_zh"] == sample_content
        assert result["quality_score"] == 0.85
        assert pipeline.stats["success"] == 1

    @patch("core.generation_pipeline.create_client")
    def test_generate_content_quality_failed(self, mock_create_client, sample_raw_data, sample_content):
        """测试生成内容 - 质量未通过"""
        mock_generator = Mock()
        mock_generator.generate.return_value = {"content": sample_content, "ai_confidence": 0.5, "rounds": 1}

        mock_checker = Mock()
        mock_checker.validate_structure.return_value = True
        mock_checker.check_quality.return_value = {"total_score": 0.6, "passed": False, "details": {}}

        mock_translator = Mock()
        mock_translator.translate.return_value = sample_content

        pipeline = GenerationPipeline(generator=mock_generator, quality_checker=mock_checker, translator=mock_translator)

        result = pipeline.generate_content("coding", sample_raw_data)

        # 质量未通过但仍然返回结果
        assert result is not None
        assert result["quality_score"] == 0.6

    @patch("core.generation_pipeline.create_client")
    def test_save_to_db(self, mock_create_client, sample_content):
        """测试保存到数据库"""
        mock_supabase = Mock()
        mock_response = Mock()
        mock_response.data = [{"id": 1}]
        mock_supabase.table.return_value.insert.return_value.execute.return_value = mock_response

        pipeline = GenerationPipeline(supabase_client=mock_supabase)

        result = {
            "content_zh": sample_content,
            "content_en": sample_content,
            "scenario": "coding",
            "ai_confidence": 0.92,
            "quality_score": 0.85,
        }

        success = pipeline.save_to_db(result)
        assert success is True

    @patch("core.generation_pipeline.create_client")
    def test_get_cost_summary_pipeline(self, mock_create_client):
        """测试管道成本统计"""
        mock_generator = Mock()
        mock_generator.get_cost_summary.return_value = {
            "total_cost": 0.05,
            "total_input_tokens": 1000,
            "total_output_tokens": 500,
        }

        mock_translator = Mock()
        mock_translator.get_cost_summary.return_value = {
            "total_cost": 0.02,
            "total_input_tokens": 300,
            "total_output_tokens": 200,
        }

        pipeline = GenerationPipeline(generator=mock_generator, translator=mock_translator)
        pipeline.stats = {"total": 10, "success": 8, "failed": 2}

        summary = pipeline.get_cost_summary()
        assert summary["total_cost"] == 0.07
        assert summary["stats"]["success"] == 8
