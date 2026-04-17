"""
HuggingFace Spider
策略：解析 https://huggingface.co/models 热门模型列表
按 pipeline_tag 分页抓取，追踪下载量趋势
"""
import asyncio
import logging
import re
from datetime import datetime, timezone

from bs4 import BeautifulSoup

from config import SPIDERS
from core.base import SpiderBase
from core.fetcher import Fetcher
from core.writer import Writer
from models.metrics import (
    MetricSource, MetricType, RawMetric, SpiderResult,
)

logger = logging.getLogger(__name__)

# HuggingFace 支持的 Pipeline Tags
HF_PIPELINE_TAGS = [
    "text-generation",
    "text-to-image",
    "image-to-text",
    "automatic-speech-recognition",
    "text-to-speech",
    "feature-extraction",
    "fill-mask",
    "text-classification",
    "token-classification",
    "object-detection",
    "image-segmentation",
]

# HF 模型 category 映射
HF_CATEGORY_MAP: dict[str, str] = {
    "text-generation": "LLM",
    "text-to-image": "文生图",
    "image-to-text": "图生文",
    "automatic-speech-recognition": "语音识别",
    "text-to-speech": "语音合成",
    "feature-extraction": "Embedding",
    "fill-mask": "BERT类",
    "text-classification": "文本分类",
    "token-classification": "NER",
    "object-detection": "目标检测",
    "image-segmentation": "图像分割",
}


class HuggingFaceSpider(SpiderBase):
    """
    HuggingFace 模型列表 Spider
    按 pipeline tag 抓取热门模型，追踪下载量
    """

    @property
    def name(self) -> str:
        return "HuggingFace"

    @property
    def retry_delay(self) -> float:
        return 3.0

    def _parse_models_page(self, html: str) -> list[dict]:
        """
        解析 HuggingFace models 页面 HTML
        返回模型卡片列表
        """
        soup = BeautifulSoup(html, "lxml")

        # HF 模型卡片列表结构
        cards = soup.select("article.svelte-1knhnq8, article[id^='model-card']")

        # 备用选择器
        if not cards:
            cards = soup.select(
                "a[href^='/models/'][class*='card'], "
                "div.col-span-1, article"
            )

        results: list[dict] = []

        for card in cards[:50]:  # 最多取前50个
            # 模型路径
            link = card.select_one("a[href^='/models/']")
            if not link:
                continue
            path = link.get("href", "").lstrip("/models/")
            if not path:
                continue

            # 模型名称（标题）
            title_el = card.select_one("h4, [class*='title'], [class*='name']")
            name = title_el.get_text(strip=True) if title_el else path.split("/")[-1].replace("-", " ")

            # 下载量
            dl_el = card.select_one(
                "[class*='download'], [class*='metric'], span[class*='text-secondary']"
            )
            downloads = 0
            if dl_el:
                dl_text = dl_el.get_text(strip=True).replace(",", "").lower()
                if "k" in dl_text:
                    downloads = int(float(dl_text.replace("k", "")) * 1000)
                elif "m" in dl_text:
                    downloads = int(float(dl_text.replace("m", "")) * 1000000)
                else:
                    try:
                        downloads = int(re.sub(r"[^\d]", "", dl_text))
                    except ValueError:
                        downloads = 0

            #  Likes
            like_el = card.select_one("[class*='like'], [class*='heart']")
            likes = 0
            if like_el:
                try:
                    likes = int(re.sub(r"[^\d]", "", like_el.get_text(strip=True)))
                except ValueError:
                    likes = 0

            # 训练数据集（如果有）
            dataset_el = card.select_one("[class*='dataset'], [class*='trained']")
            dataset = dataset_el.get_text(strip=True) if dataset_el else ""

            results.append({
                "model_id": f"hf:{path}",
                "path": path,
                "name": name,
                "downloads": downloads,
                "likes": likes,
                "dataset": dataset,
                "url": f"https://huggingface.co/{path}",
            })

        return results

    async def do_fetch(self, fetcher: Fetcher, writer: Writer) -> SpiderResult:
        """
        执行 HuggingFace 模型爬取
        流程：按 pipeline tag 分别抓取 → 解析 → 写入
        """
        errors: list[str] = []
        total_fetched = 0
        total_written = 0

        # 从配置读取要爬取的 tags
        tags: list[str] = SPIDERS.get("huggingface", {}).get(
            "tags", HF_PIPELINE_TAGS
        )

        for tag in tags:
            url = (
                f"https://huggingface.co/models"
                f"?pipeline_tag={tag}&sort=downloads&direction=-1"
            )

            resp = await fetcher.get(url)
            if not resp:
                errors.append(f"获取 tag={tag} 失败")
                await asyncio.sleep(self.retry_delay)
                continue

            models = self._parse_models_page(resp.text)
            total_fetched += len(models)
            logger.info(f"[HuggingFace] tag={tag}: {len(models)} 模型")

            # 写入
            written = await self._write_metrics(writer, models, tag)
            total_written += written

            await asyncio.sleep(1.5)  # 礼貌爬取

        return SpiderResult(
            spider_name=self.name,
            success=len(errors) == 0,
            items_fetched=total_fetched,
            items_written=total_written,
            errors=errors,
        )

    async def _write_metrics(self, writer: Writer, models: list[dict],
                              tag: str) -> int:
        """将模型数据写入 model_raw_metrics"""
        written = 0

        metric_type_map: dict[str, MetricType] = {
            "text-generation": MetricType.HF_TEXT_GENERATION,
            "text-to-image": MetricType.HF_TEXT_TO_IMAGE,
            "image-to-text": MetricType.HF_IMAGE_TO_TEXT,
            "automatic-speech-recognition": MetricType.HF_AUTOMATIC_SPEECH_RECOGNITION,
            "text-to-speech": MetricType.HF_TEXT_TO_SPEECH,
            "feature-extraction": MetricType.HF_FEATURE_EXTRACTION,
            "fill-mask": MetricType.HF_FILL_MASK,
        }

        metric_type = metric_type_map.get(
            tag, MetricType.HF_TEXT_GENERATION
        )

        category = HF_CATEGORY_MAP.get(tag, tag)

        for m in models:
            # 确保模型记录存在
            model_id = writer.upsert_model(
                name=m["name"],
                vendor="HuggingFace",
                category=category,
                description="",
                website_url=m["url"],
                tags=[tag, "huggingface"],
            )
            if not model_id:
                continue

            # 更新 model_id 为数据库 ID（而非 hf:path）
            actual_model_id = model_id

            metric = RawMetric(
                model_id=actual_model_id,
                source=MetricSource.HUGGINGFACE,
                metric_type=metric_type,
                metric_value={
                    "hf_path": m["path"],
                    "name": m["name"],
                    "downloads": m["downloads"],
                    "likes": m["likes"],
                    "dataset": m["dataset"],
                    "url": m["url"],
                    "pipeline_tag": tag,
                },
            )

            if writer.upsert_model_metrics(metric):
                written += 1

        return written
