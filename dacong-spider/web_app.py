"""
DaCong Spider Web - Gradio Web Interface

提供网页界面来管理和监控爬虫系统
"""
import asyncio
import logging
import os
import sys
from datetime import datetime
from typing import Optional

import gradio as gr

# 设置路径
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from spiders.registry import list_spiders, get_spider
from spiders.rankings_base import BaseRankingsSpider
from core.fetcher import Fetcher
from core.writer import Writer
from core.interfaces import SpiderResult


async def _run_spider_dispatch(spider):
    """按蜘蛛类型分派执行（与新架构 main.py 一致）

    - BaseRankingsSpider：自带存储，run() 无参
    - SpiderBase：需要注入 Fetcher / Writer
    """
    if isinstance(spider, BaseRankingsSpider):
        return await spider.run()
    return await spider.run(Fetcher(), Writer())

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class SpiderWebService:
    """爬虫 Web 服务"""

    def __init__(self):
        self.latest_results: dict[str, SpiderResult] = {}
        self._lock = asyncio.Lock()

    async def run_spider_async(self, spider_name: str) -> str:
        """异步运行单个爬虫"""
        async with self._lock:
            try:
                if spider_name not in list_spiders():
                    return f"[ERROR] 爬虫 '{spider_name}' 不存在"

                spider = get_spider(spider_name)
                logger.info(f"开始运行爬虫: {spider_name}")

                # 按架构分派执行
                result = await _run_spider_dispatch(spider)
                self.latest_results[spider_name] = result

                return (
                    f"[OK] {spider_name} 运行完成\n"
                    f"获取: {result.items_fetched} 条\n"
                    f"写入: {result.items_written} 条"
                )

            except Exception as e:
                logger.exception(f"运行爬虫 {spider_name} 时出错: {e}")
                return f"[ERROR] {spider_name}: {str(e)}"

    def run_spider(self, spider_name: str) -> str:
        """同步包装器"""
        try:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            result = loop.run_until_complete(self.run_spider_async(spider_name))
            loop.close()
            return result
        except Exception as e:
            return f"[ERROR] {str(e)}"

    async def run_all_spiders_async(self) -> str:
        """异步运行所有爬虫"""
        async with self._lock:
            try:
                names = list_spiders()
                logger.info(f"开始运行所有爬虫: {names}")

                spiders = [get_spider(name) for name in names]
                # 并发运行（按架构分派）
                tasks = [_run_spider_dispatch(spider) for spider in spiders]
                await asyncio.gather(*tasks, return_exceptions=True)

                return f"[OK] 已运行 {len(names)} 个爬虫"

            except Exception as e:
                logger.exception(f"运行所有爬虫时出错: {e}")
                return f"[ERROR] {str(e)}"

    def run_all_spiders(self) -> str:
        """同步包装器"""
        try:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            result = loop.run_until_complete(self.run_all_spiders_async())
            loop.close()
            return result
        except Exception as e:
            return f"[ERROR] {str(e)}"

    def get_spider_list(self) -> str:
        """获取爬虫列表"""
        try:
            spiders = list_spiders()
            lines = ["### 可用爬虫\n"]
            lines.append("| 名称 | 状态 |")
            lines.append("|------|------|")

            for name in spiders:
                last_result = self.latest_results.get(name)
                if last_result:
                    status = "✅ 成功" if last_result.success else "❌ 失败"
                    info = f"{last_result.items_fetched} 条 / {last_result.duration_seconds:.1f}s"
                else:
                    status = "⏳ 未运行"
                    info = "-"
                lines.append(f"| {name} | {status} ({info}) |")

            return "\n".join(lines)

        except Exception as e:
            return f"[ERROR] {str(e)}"

    def get_system_status(self) -> str:
        """获取系统状态"""
        try:
            spider_count = len(list_spiders())
            result_count = len(self.latest_results)
            success_count = sum(1 for r in self.latest_results.values() if r.success)

            status = f"""
### 系统状态

- **爬虫总数**: {spider_count}
- **运行记录**: {result_count} 次
- **成功次数**: {success_count}
- **配置时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""
            return status

        except Exception as e:
            return f"[ERROR] {str(e)}"


# 全局服务实例
service = SpiderWebService()


def run_single_spider(spider_name: str) -> str:
    """运行单个爬虫"""
    return service.run_spider(spider_name)


def run_all_spiders() -> str:
    """运行所有爬虫"""
    return service.run_all_spiders()


def show_status() -> str:
    """显示状态"""
    return service.get_system_status() + "\n\n" + service.get_spider_list()


def create_ui():
    """创建 Gradio UI"""

    with gr.Blocks(title="DaCong Spider") as demo:
        gr.Markdown("# DaCong Spider Console")
        gr.Markdown("AI Model Data Crawler System Web Interface")

        # 状态显示
        status_box = gr.Textbox(label="System Status", interactive=False, lines=10)

        # Action Buttons
        with gr.Row():
            refresh_btn = gr.Button("Refresh Status", variant="secondary")
            run_all_btn = gr.Button("Run All Spiders", variant="primary")

        # Single Spider Selection
        spider_select = gr.Dropdown(
            choices=["github", "huggingface", "openrouter", "reddit",
                    "hackernews", "youtube", "twitter", "googlenews"],
            label="Select Spider",
            value="github"
        )
        run_single_btn = gr.Button("Run Selected Spider", variant="primary")

        # Output Area
        output_box = gr.Textbox(label="Run Result", interactive=False, lines=8)

        # 事件绑定
        refresh_btn.click(fn=show_status, outputs=status_box)
        run_all_btn.click(fn=run_all_spiders, outputs=output_box)
        run_single_btn.click(fn=run_single_spider, inputs=[spider_select], outputs=output_box)

        # 初始加载
        demo.load(fn=show_status, outputs=status_box)

    return demo


def main():
    """主函数"""
    import argparse

    parser = argparse.ArgumentParser(description="DaCong Spider Web")
    parser.add_argument("--port", type=int, default=7860, help="端口号")
    parser.add_argument("--share", action="store_true", help="创建公开分享链接")
    parser.add_argument("--host", type=str, default="0.0.0.0", help="主机地址")

    args = parser.parse_args()

    demo = create_ui()

    print(f"\nDaCong Spider Web starting...")
    print(f"   Local: http://localhost:{args.port}")
    if args.share:
        print(f"   Share: Generating link via Gradio...")
        print(f"   Note: Public link provided by Gradio Cloud")

    demo.launch(
        server_name=args.host,
        server_port=args.port,
        share=args.share,
        theme=gr.themes.Soft()
    )


if __name__ == "__main__":
    main()