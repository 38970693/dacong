"""
图卡生成器测试
"""
from pathlib import Path
from unittest.mock import Mock, patch

import pytest
from PIL import Image

from core.image_generator import ImageGenerator


@pytest.fixture
def image_generator(tmp_path):
    """创建图卡生成器实例"""
    return ImageGenerator(output_dir=tmp_path)


@pytest.fixture
def sample_weekly_content():
    """示例周报内容"""
    return {
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
                    },
                    {
                        "name": "Claude Code",
                        "one_liner": "AI 编程助手",
                        "why_matters": "代码质量最高",
                        "github_url": "https://github.com/anthropics/claude-code",
                        "stars": 12000,
                        "star_growth": 3000,
                        "access": "需翻墙",
                    },
                ],
            }
        ],
        "confidence": 0.92,
    }


class TestImageGenerator:
    """图卡生成器测试"""

    def test_init(self, tmp_path):
        """测试：初始化"""
        generator = ImageGenerator(output_dir=tmp_path)

        assert generator.output_dir == tmp_path
        assert generator.width == 1200
        assert generator.height == 630
        assert "background" in generator.colors
        assert "primary" in generator.colors

    def test_init_creates_output_dir(self, tmp_path):
        """测试：自动创建输出目录"""
        output_dir = tmp_path / "images"
        generator = ImageGenerator(output_dir=output_dir)

        assert output_dir.exists()
        assert output_dir.is_dir()

    def test_generate_weekly_card(self, image_generator, sample_weekly_content):
        """测试：生成周报图卡"""
        output_path = image_generator.generate_weekly_card(
            sample_weekly_content, language="zh"
        )

        # 验证文件存在
        assert output_path.exists()
        assert output_path.suffix == ".png"

        # 验证图片尺寸
        img = Image.open(output_path)
        assert img.size == (1200, 630)
        assert img.mode == "RGB"

    def test_generate_weekly_card_english(
        self, image_generator, sample_weekly_content
    ):
        """测试：生成英文周报图卡"""
        output_path = image_generator.generate_weekly_card(
            sample_weekly_content, language="en"
        )

        assert output_path.exists()
        assert "weekly_en_" in output_path.name

    def test_format_number(self, image_generator):
        """测试：数字格式化"""
        # 小于 1000
        assert image_generator._format_number(500) == "500"

        # 大于等于 1000
        assert image_generator._format_number(1500) == "1.5k"
        assert image_generator._format_number(15000) == "15.0k"

    def test_wrap_text(self, image_generator):
        """测试：文字换行"""
        text = "这是一段很长的文本，需要进行换行处理，以适应图片的宽度限制"
        lines = image_generator._wrap_text(text, image_generator.font_body, 400)

        # 验证换行
        assert len(lines) > 1
        assert all(isinstance(line, str) for line in lines)

    def test_wrap_text_short(self, image_generator):
        """测试：短文本不换行"""
        text = "短文本"
        lines = image_generator._wrap_text(text, image_generator.font_body, 1000)

        assert len(lines) == 1
        assert lines[0] == text

    def test_generate_card_bytes(self, image_generator, sample_weekly_content):
        """测试：生成图卡字节流"""
        img_bytes = image_generator.generate_card_bytes(
            sample_weekly_content, language="zh"
        )

        # 验证字节流
        assert img_bytes is not None
        assert img_bytes.tell() == 0  # 指针在开头

        # 验证可以读取为图片
        img = Image.open(img_bytes)
        assert img.size == (1200, 630)

    def test_generate_card_with_empty_sections(self, image_generator):
        """测试：空板块生成图卡"""
        content = {
            "title": "测试周报",
            "summary": "测试摘要",
            "week_start": "2026-04-14",
            "week_end": "2026-04-20",
            "sections": [],
        }

        output_path = image_generator.generate_weekly_card(content, language="zh")

        # 验证文件存在
        assert output_path.exists()

    def test_generate_card_with_many_items(self, image_generator):
        """测试：多个项目生成图卡（只显示前3个）"""
        content = {
            "title": "测试周报",
            "summary": "测试摘要",
            "week_start": "2026-04-14",
            "week_end": "2026-04-20",
            "sections": [
                {
                    "section_title": "本周最火",
                    "items": [
                        {
                            "name": f"Project {i}",
                            "one_liner": f"Description {i}",
                            "why_matters": f"Why {i}",
                            "github_url": f"https://github.com/test/project{i}",
                            "stars": 1000 * i,
                            "star_growth": 100 * i,
                            "access": "国内可用",
                        }
                        for i in range(1, 6)
                    ],
                }
            ],
        }

        output_path = image_generator.generate_weekly_card(content, language="zh")

        # 验证文件存在
        assert output_path.exists()

    def test_color_scheme(self, image_generator):
        """测试：颜色方案"""
        colors = image_generator.colors

        # 验证所有必需的颜色都存在
        required_colors = [
            "background",
            "primary",
            "secondary",
            "text_primary",
            "text_secondary",
            "accent",
        ]
        for color in required_colors:
            assert color in colors
            assert colors[color].startswith("#")
            assert len(colors[color]) == 7  # #RRGGBB
