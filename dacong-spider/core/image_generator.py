"""
图卡生成器

功能：
- 使用 Pillow 生成周报分享图卡
- 支持中英文
- 美观的设计
"""
from datetime import datetime
from io import BytesIO
from pathlib import Path
from typing import Any, Dict, Optional

from loguru import logger
from PIL import Image, ImageDraw, ImageFont


class ImageGenerator:
    """图卡生成器"""

    def __init__(self, output_dir: Optional[Path] = None):
        """
        初始化生成器

        Args:
            output_dir: 输出目录，默认为 output/images
        """
        self.output_dir = output_dir or Path(__file__).parent.parent / "output" / "images"
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # 图片尺寸（适合社交媒体分享）
        self.width = 1200
        self.height = 630

        # 颜色方案（高端设计）
        self.colors = {
            "background": "#0F172A",  # 深色背景
            "primary": "#3B82F6",  # 蓝色主题
            "secondary": "#8B5CF6",  # 紫色辅助
            "text_primary": "#F1F5F9",  # 浅色文字
            "text_secondary": "#94A3B8",  # 次要文字
            "accent": "#10B981",  # 绿色强调
        }

        # 加载字体
        self._load_fonts()

    def _load_fonts(self) -> None:
        """加载字体"""
        try:
            # 尝试加载系统字体
            self.font_title = ImageFont.truetype("arial.ttf", 48)
            self.font_subtitle = ImageFont.truetype("arial.ttf", 32)
            self.font_body = ImageFont.truetype("arial.ttf", 24)
            self.font_small = ImageFont.truetype("arial.ttf", 18)
        except OSError:
            logger.warning("无法加载系统字体，使用默认字体")
            self.font_title = ImageFont.load_default()
            self.font_subtitle = ImageFont.load_default()
            self.font_body = ImageFont.load_default()
            self.font_small = ImageFont.load_default()

    def generate_weekly_card(
        self, weekly_content: Dict[str, Any], language: str = "zh"
    ) -> Path:
        """
        生成周报图卡

        Args:
            weekly_content: 周报内容
            language: 语言（zh/en）

        Returns:
            生成的图片路径
        """
        logger.info(f"生成周报图卡 - 语言: {language}")

        # 创建画布
        img = Image.new("RGB", (self.width, self.height), self.colors["background"])
        draw = ImageDraw.Draw(img)

        # 绘制渐变背景
        self._draw_gradient_background(draw)

        # 绘制标题
        title = weekly_content.get("title", "AI 工具周报")
        self._draw_title(draw, title, y=80)

        # 绘制日期
        week_start = weekly_content.get("week_start", "")
        week_end = weekly_content.get("week_end", "")
        date_text = f"{week_start} - {week_end}" if week_start and week_end else ""
        self._draw_subtitle(draw, date_text, y=150)

        # 绘制摘要
        summary = weekly_content.get("summary", "")
        self._draw_summary(draw, summary, y=220)

        # 绘制精选项目（最多3个）
        sections = weekly_content.get("sections", [])
        if sections:
            items = sections[0].get("items", [])[:3]
            self._draw_items(draw, items, y=320)

        # 绘制底部信息
        self._draw_footer(draw)

        # 保存图片
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"weekly_{language}_{timestamp}.png"
        output_path = self.output_dir / filename

        img.save(output_path, "PNG", quality=95)
        logger.info(f"图卡已保存: {output_path}")

        return output_path

    def _draw_gradient_background(self, draw: ImageDraw.Draw) -> None:
        """绘制渐变背景"""
        # 简单的线性渐变效果
        for y in range(self.height):
            # 从深蓝到深紫的渐变
            ratio = y / self.height
            r = int(15 + (59 - 15) * ratio)
            g = int(23 + (92 - 23) * ratio)
            b = int(42 + (246 - 42) * ratio * 0.3)
            color = f"#{r:02x}{g:02x}{b:02x}"
            draw.line([(0, y), (self.width, y)], fill=color)

    def _draw_title(self, draw: ImageDraw.Draw, text: str, y: int) -> None:
        """绘制标题"""
        # 居中绘制
        bbox = draw.textbbox((0, 0), text, font=self.font_title)
        text_width = bbox[2] - bbox[0]
        x = (self.width - text_width) // 2

        draw.text(
            (x, y), text, fill=self.colors["text_primary"], font=self.font_title
        )

    def _draw_subtitle(self, draw: ImageDraw.Draw, text: str, y: int) -> None:
        """绘制副标题"""
        bbox = draw.textbbox((0, 0), text, font=self.font_subtitle)
        text_width = bbox[2] - bbox[0]
        x = (self.width - text_width) // 2

        draw.text(
            (x, y), text, fill=self.colors["text_secondary"], font=self.font_subtitle
        )

    def _draw_summary(self, draw: ImageDraw.Draw, text: str, y: int) -> None:
        """绘制摘要"""
        # 文字换行
        max_width = self.width - 200
        lines = self._wrap_text(text, self.font_body, max_width)

        for i, line in enumerate(lines[:2]):  # 最多2行
            bbox = draw.textbbox((0, 0), line, font=self.font_body)
            text_width = bbox[2] - bbox[0]
            x = (self.width - text_width) // 2
            draw.text(
                (x, y + i * 35),
                line,
                fill=self.colors["text_secondary"],
                font=self.font_body,
            )

    def _draw_items(self, draw: ImageDraw.Draw, items: list, y: int) -> None:
        """绘制项目列表"""
        x_start = 100
        item_height = 80

        for i, item in enumerate(items):
            item_y = y + i * item_height

            # 绘制序号
            draw.text(
                (x_start, item_y),
                f"{i + 1}.",
                fill=self.colors["accent"],
                font=self.font_body,
            )

            # 绘制项目名
            name = item.get("name", "")
            draw.text(
                (x_start + 40, item_y),
                name,
                fill=self.colors["text_primary"],
                font=self.font_body,
            )

            # 绘制一句话描述
            one_liner = item.get("one_liner", "")
            if one_liner:
                # 截断过长的文本
                if len(one_liner) > 40:
                    one_liner = one_liner[:37] + "..."
                draw.text(
                    (x_start + 40, item_y + 30),
                    one_liner,
                    fill=self.colors["text_secondary"],
                    font=self.font_small,
                )

    def _draw_footer(self, draw: ImageDraw.Draw) -> None:
        """绘制底部信息"""
        footer_text = "DaCong - AI 工具决策助手"
        y = self.height - 60

        bbox = draw.textbbox((0, 0), footer_text, font=self.font_small)
        text_width = bbox[2] - bbox[0]
        x = (self.width - text_width) // 2

        draw.text(
            (x, y), footer_text, fill=self.colors["text_secondary"], font=self.font_small
        )

    def _format_number(self, num: int) -> str:
        """
        格式化数字

        Args:
            num: 数字

        Returns:
            格式化后的字符串
        """
        if num < 1000:
            return str(num)
        return f"{num / 1000:.1f}k"

    def _wrap_text(self, text: str, font: ImageFont.FreeTypeFont, max_width: int) -> list:
        """
        文字换行

        Args:
            text: 文本
            font: 字体
            max_width: 最大宽度

        Returns:
            换行后的文本列表
        """
        # 对于中文文本，按字符分割而不是按空格
        if any('\u4e00' <= char <= '\u9fff' for char in text):
            # 中文文本处理
            lines = []
            current_line = ""

            for char in text:
                test_line = current_line + char
                bbox = font.getbbox(test_line)
                text_width = bbox[2] - bbox[0]

                if text_width <= max_width:
                    current_line = test_line
                else:
                    if current_line:
                        lines.append(current_line)
                    current_line = char

            if current_line:
                lines.append(current_line)

            return lines
        else:
            # 英文文本处理（按单词分割）
            words = text.split()
            lines = []
            current_line = ""

            for word in words:
                test_line = f"{current_line} {word}".strip()
                bbox = font.getbbox(test_line)
                text_width = bbox[2] - bbox[0]

                if text_width <= max_width:
                    current_line = test_line
                else:
                    if current_line:
                        lines.append(current_line)
                    current_line = word

            if current_line:
                lines.append(current_line)

            return lines

    def generate_card_bytes(
        self, weekly_content: Dict[str, Any], language: str = "zh"
    ) -> BytesIO:
        """
        生成图卡字节流（用于 API 返回）

        Args:
            weekly_content: 周报内容
            language: 语言

        Returns:
            图片字节流
        """
        # 生成图片
        img_path = self.generate_weekly_card(weekly_content, language)

        # 读取为字节流
        with open(img_path, "rb") as f:
            img_bytes = BytesIO(f.read())

        return img_bytes
