"""
单元测试 - 大模型评测解析纯函数

覆盖 spiders/artificial_analysis.py 的 benchmark / 能力字段解析，
以及 spiders/arena.py 的厂商推断。样例数据取自
https://artificialanalysis.ai/api/data/website/host-models/performance
的真实响应结构。
"""
import pytest

from spiders.arena import infer_vendor
from spiders.artificial_analysis import (
    merge_host_performance,
    parse_benchmarks,
    parse_capabilities,
)


@pytest.fixture
def model_payload() -> dict:
    """hostModel.model 的精简样例（真实字段名与量纲）"""
    return {
        "slug": "gpt-oss-120b-low",
        "name": "gpt-oss-120b (low)",
        "model_creators": {"name": "OpenAI"},
        "context_window_tokens": 131072,
        "output_tokens": 131072,
        "input_modality_text": True,
        "input_modality_image": False,
        "input_modality_speech": False,
        "input_modality_video": False,
        # benchmark：0~1 比例
        "mmlu_pro": 0.774767287234043,
        "gpqa": 0.671717171717172,
        "humaneval": None,
        "livecodebench": 0.706878306878307,
        "aime25": 0.666666666666667,
        "math_500": None,
        "mmmu_pro": None,
        # 百分制指数，不做换算
        "intelligence_index": 14.9256339397626,
    }


# ══════════════════════════════════════════════════════════
# parse_benchmarks：benchmark 分数解析
# ══════════════════════════════════════════════════════════

class TestParseBenchmarks:

    def test_ratio_scores_are_converted_to_percent(self, model_payload):
        """0~1 比例统一换算成百分制并保留 4 位小数"""
        scores = {e["benchmark"]: e["score"] for e in parse_benchmarks(model_payload)}
        assert scores["MMLU-Pro"] == pytest.approx(77.4767)
        assert scores["GPQA"] == pytest.approx(67.1717)
        assert scores["AIME-2025"] == pytest.approx(66.6667)

    def test_index_score_is_not_rescaled(self, model_payload):
        """intelligence_index 本身就是百分制，不应再 ×100"""
        scores = {e["benchmark"]: e["score"] for e in parse_benchmarks(model_payload)}
        assert scores["Intelligence-Index"] == pytest.approx(14.9256)

    def test_null_benchmarks_are_skipped(self, model_payload):
        """API 把未跑的 benchmark 置为 null，不应产生记录"""
        names = {e["benchmark"] for e in parse_benchmarks(model_payload)}
        assert "HumanEval" not in names
        assert "MATH-500" not in names
        assert "MMMU-Pro" not in names

    def test_category_mapping(self, model_payload):
        """benchmark 带上统一分类，供前端分组对比"""
        categories = {e["benchmark"]: e["category"] for e in parse_benchmarks(model_payload)}
        assert categories["GPQA"] == "general"
        assert categories["LiveCodeBench"] == "coding"
        assert categories["AIME-2025"] == "math"

    def test_raw_value_kept_in_raw_data(self, model_payload):
        """原始值保留在 raw_data，便于回溯换算"""
        gpqa = next(e for e in parse_benchmarks(model_payload) if e["benchmark"] == "GPQA")
        assert gpqa["raw_data"] == {"field": "gpqa", "raw_value": 0.671717171717172}

    def test_zero_score_is_kept(self):
        """0 分是有效成绩，不能当成缺失丢掉"""
        results = parse_benchmarks({"gpqa": 0})
        assert len(results) == 1
        assert results[0]["score"] == 0.0

    def test_bool_and_string_are_ignored(self):
        """bool 是 int 子类、字符串不可比较，都必须挡掉"""
        assert parse_benchmarks({"gpqa": True, "mmlu_pro": "n/a"}) == []

    def test_empty_payload(self):
        assert parse_benchmarks({}) == []


# ══════════════════════════════════════════════════════════
# parse_capabilities / merge_host_performance：M3 能力字段
# ══════════════════════════════════════════════════════════

class TestParseCapabilities:

    def test_basic_fields(self, model_payload):
        caps = parse_capabilities(model_payload)
        assert caps["context_window"] == 131072
        assert caps["max_output_tokens"] == 131072
        assert caps["tool_use"] is False

    def test_multimodal_inputs_only_include_true_flags(self, model_payload):
        assert parse_capabilities(model_payload)["multimodal_inputs"] == ["text"]

    def test_multimodal_inputs_multiple(self, model_payload):
        model_payload["input_modality_image"] = True
        model_payload["input_modality_video"] = True
        assert parse_capabilities(model_payload)["multimodal_inputs"] == [
            "text", "image", "video",
        ]

    def test_missing_fields_are_none(self):
        caps = parse_capabilities({})
        assert caps["context_window"] is None
        assert caps["max_output_tokens"] is None
        assert caps["multimodal_inputs"] == []


class TestMergeHostPerformance:

    def test_seconds_converted_to_milliseconds(self):
        caps = {"tool_use": False}
        merge_host_performance(caps, {
            "timescaleData": {
                "median_output_speed": 183.649779655725,
                "median_time_to_first_chunk": 0.983476041,
            },
        })
        assert caps["throughput_tps"] == 184
        assert caps["latency_ms"] == 983

    def test_best_host_wins(self):
        """多宿主取最大吞吐 + 最小延迟"""
        caps = {"tool_use": False}
        merge_host_performance(caps, {
            "timescaleData": {"median_output_speed": 100, "median_time_to_first_chunk": 0.5},
        })
        merge_host_performance(caps, {
            "timescaleData": {"median_output_speed": 250, "median_time_to_first_chunk": 2.0},
        })
        assert caps["throughput_tps"] == 250
        assert caps["latency_ms"] == 500

    def test_tool_use_is_sticky(self):
        """任一宿主支持 function calling 即视为支持"""
        caps = {"tool_use": False}
        merge_host_performance(caps, {"function_calling": True})
        merge_host_performance(caps, {"function_calling": False})
        assert caps["tool_use"] is True

    def test_missing_timescale_data(self):
        caps = {"tool_use": False}
        merge_host_performance(caps, {})
        assert "throughput_tps" not in caps
        assert "latency_ms" not in caps


# ══════════════════════════════════════════════════════════
# infer_vendor：arena model_name -> models.vendor
# ══════════════════════════════════════════════════════════

class TestInferVendor:

    @pytest.mark.parametrize("model_name,expected", [
        ("gpt-4o-2024-11-20", "OpenAI"),
        ("claude-3-5-sonnet", "Anthropic"),
        ("gemini-2.0-flash", "Google"),
        ("llama-4-maverick", "Meta"),
        ("deepseek-v3", "DeepSeek"),
        ("qwen2.5-max", "Alibaba"),
        ("grok-3", "xAI"),
    ])
    def test_prefix_match(self, model_name, expected):
        assert infer_vendor(model_name) == expected

    def test_parenthesised_org_takes_priority(self):
        """LMArena 常把组织名放在末尾括号里"""
        assert infer_vendor("claude-opus-4-6-thinking (anthropic)") == "Anthropic"

    def test_unknown_org_passes_through(self):
        assert infer_vendor("some-model (acme-labs)") == "acme-labs"

    def test_mixtral_not_swallowed_by_mistral(self):
        """前缀表顺序需保证 mixtral 先于 mistral 命中同一厂商"""
        assert infer_vendor("mixtral-8x22b") == "Mistral AI"

    @pytest.mark.parametrize("model_name", ["", "   ", "totally-unknown-model"])
    def test_fallback(self, model_name):
        assert infer_vendor(model_name) == "Unknown"
