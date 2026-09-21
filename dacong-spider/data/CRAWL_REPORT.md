# DaCong 数据底座 · 真实抓取数据报告

> 抓取时间：2026-08-08 ｜ 干跑模式（真实公开 API，未写库，仅采集）

## 一、AI 资讯（arXiv cs.AI / cs.CL）— 100 篇

| 标题 | 作者 | 发布 |
|------|------|------|
| Learning When to Trust via Selective Context Preference Opti |  |  |
| Tracing the Heart: An Evidence-Linked Pipeline for Heart-Fai |  |  |
| Investigating Artificial Intelligence Digital Sovereignty in |  |  |
| An Optimal Agnostic PAC Algorithm |  |  |
| AV-AIVAT: 74x Cheaper Agent Evaluation with Certified Anytim |  |  |
| The Low Frequency Trap: Video Language Models Fail at Simple |  |  |

## 二、GitHub 快速涨星 — 121 个仓库

| 仓库 | 语言 | Stars | Forks |
|------|------|-------|-------|
| donnemartin/system-design-primer | Python | 362273 | 0 |
| obra/superpowers | Shell | 268757 | 0 |
| affaan-m/ECC | JavaScript | 238585 | 0 |
| mattpocock/skills | Shell | 208853 | 0 |
| Significant-Gravitas/AutoGPT | Python | 186332 | 0 |
| Significant-Gravitas/AutoGPT | Python | 186332 | 0 |
| firecrawl/firecrawl | TypeScript | 162918 | 0 |
| anthropics/claude-code | Python | 140611 | 0 |

## 三、大模型能力 / 评测（Artificial Analysis）

- 排行榜条目 `artificial_analysis_rankings`：849 条
- 模型主记录 `models`：346 条（含 context_window / max_output_tokens / multimodal_inputs / tool_use / throughput_tps / latency_ms）
- 评测分数 `model_evaluations`：3215 条

**评测分数按 benchmark 分布：**

- Intelligence-Index: 342
- HLE: 341
- SciCode: 341
- GPQA: 340
- IFBench: 289
- Tau2-Bench: 287
- Terminal-Bench-Hard: 282
- MMMU-Pro: 189
- LiveCodeBench: 185
- MMLU-Pro: 184
- AIME-2025: 163
- MATH-500: 96
- AIME: 95
- HumanEval: 81

**样例：部分模型能力字段**

| 模型 | 上下文 | 最大输出 | 多模态输入 | 工具调用 | 吞吐(tps) | 延迟(ms) |
|------|--------|----------|------------|----------|-----------|-----------|
|  | 131072 | 131072 | text | ✓ | 936 | 470 |
|  | 131072 | 131071 | text | ✓ | 1882 | 278 |
|  | 131072 | 131072 | text | ✓ | 1824 | 280 |
|  | 200000 | 100000 | text, image | ✓ | 127 | 8688 |
|  | 131072 | 131072 | text | ✓ | 938 | 700 |
|  | 1000000 | 128000 | text, image | ✓ | 258 | 78628 |
|  | 1000000 | 128000 | text, image | ✓ | 58 | 5679 |
|  | 1000000 | 128000 | text, image | ✓ | 153 | 123203 |

## 四、Arena（LM Arena ELO 评测）

- **本次未获取**：沙箱网络出口无法连通 `lmarena.ai`（连接超时 HTTP=000），属环境限制，非代码缺陷。部署到具备公网访问的环境后即可正常抓取。

## 汇总

| 领域 | 目标表 | 条数 | 状态 |
|------|--------|------|------|
| AI 资讯 | hot_news_raw | 100 | ✅ |
| GitHub 涨星 | repository_metrics | 121 | ✅ |
| 大模型能力 | models / artificial_analysis_rankings | 346 / 849 | ✅ |
| 大模型评测 | model_evaluations | 3215 | ✅（已修复超时导致的不稳定）|
| Arena ELO | arena_rankings | 0 | ⚠️ 沙箱网络限制 |

---
原始完整抓取数据见 `dacong-spider/data/dryrun_captured.json`（约 2.4MB）。