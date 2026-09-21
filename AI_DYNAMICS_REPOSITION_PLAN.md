# DaCong 改造计划：专注 AI 动态（AI Dynamics）

> 目标定位：把 DaCong 从「AI 模型信息聚合平台 / 曾规划的 AI 咨询平台」重新聚焦为
> **AI 动态聚合与洞察平台**——持续采集 AI 领域的关键"变化"，统一聚合、计算趋势、清晰展示。
> 本计划**不推翻重来**，而是在已有两份计划上做范围收窄与聚焦。

**状态**：✅ 方案已锁定（2026-08-07）。经确认采用**纯聚合展示**——不含任何 LLM 驱动能力，
**不引入 LLM API Key / pgvector / RAG / 流式对话**。即 Phase 2-4（咨询/专家/支付）+ RAG 整体砍掉。

---

## 0. 定位重述

| 维度 | 旧定位 | 新定位（专注 AI 动态） |
|------|--------|------------------------|
| 一句话 | AI 模型信息聚合平台（曾规划 AI 咨询平台） | AI 动态聚合与洞察平台 |
| 核心价值 | 把分散的数据采集回来 | 持续呈现 AI 领域的**变化**（涨星 / 评测漂移 / 资讯流） |
| 不做 | — | 不做咨询对话、不做专家交易、不做支付 |

**"动态"的具体含义**：数据必须带有时间维度与变化信号，而不是一次性快照。
- 仓库涨星 → 用 `velocity`（stars/day）、`stars_1d/7d/30d` 表达"正在火"
- 模型评测 → 按 `eval_date` 留历史，能看"谁在进步"
- 资讯 → 按时间流 + 热度，能看"今天发生了什么"

---

## 1. 与已有两份计划的关系（不重造轮子）

- **`DATA_FOUNDATION_PLAN.md`（数据底座）** = 本计划的**内容层**，直接采用并推进到完成。
  它的四大域（AI 资讯 / GitHub 涨星 / 大模型评测 / 大模型能力）就是"AI 动态"的数据底座。
- **`AI_CONSULTING_PIVOT_PLAN.md`（AI 咨询平台）** = 大部分**砍掉**：
  - Phase 2-4（咨询会话 / 专家市场 / 支付）整体移除；
  - Phase 1 的"知识库 + RAG"降级为**轻量标签/分类**（基于现有 `is_ai_related` + 来源分类），**不引入 pgvector / 语义检索 / 流式 SSE 对话**。

> 结论：复用率极高（约 80%）。真正要写的"新东西"很少，主要是**收尾 + 收窄 + 前端聚焦**。

---

## 2. 范围界定（Keep / Drop / 轻量保留）

### KEEP（保留并强化）
- 爬虫 4 域（registry 新架构 9 个爬虫：github / huggingface / hackernews / swebench / arena / artificial_analysis / aiping / arxiv / ai_news_rss）
- 数据底座 M1-M4（rising stars / 评测聚合 / 能力完善 / 资讯增强）
- API 暴露层（Supabase Edge Functions）
- Client（Flutter）/ Console（Next.js）展示层

### DROP（砍掉，释放工作量）
- RAG + 流式 SSE 对话引擎（AI_CONSULTING Phase 1 重头戏）
- `consultations` / `consultation_messages` / `experts` / `consultation_orders` 表与前端的咨询/专家/订单
- 支付集成（Stripe / 商户号）
- pgvector 向量库与语义检索

### 轻量保留（不做重）
- 搜索 / 标签 / 分类：基于现有 `is_ai_related` + 来源字段做过滤，不做语义检索
- 现有 Sentry / Grafana / Loki 可观测性照用

---

## 3. 聚焦"动态"的差异化前端设计（与静态快照平台的区别）

三大"动态"视图，统一在 Console/Client 的「动态」主页（dashboard）：

1. **AI 资讯流** — `hot_news_raw` + `arxiv` + `ai_news_rss`，按时间 / 热度排序，`is_ai_related` 过滤；
2. **飙升榜** — `rising_stars_rankings`，按 `velocity` 斜率排序，配趋势 mini 图（仓库正在火）；
3. **模型脉搏** — `model_evaluations` + `models` 能力字段，按 `eval_date` 画历史曲线 + 多 benchmark 雷达图（谁在进步）。

前端信息架构从"散落的多个 tab"收敛为一个清晰的「动态」主页 + 三个子视图，砍掉咨询/专家/支付入口。

---

## 4. 实施阶段

### Phase A — 收尾技术债（**前提**，约 1-2 天）
> 当前 spider 包处于"引用方已迁、老文件仍在、测试仍坏"的中间态，必须先收口才能安全重构。

- [ ] #34 迁移 `tests/test_spiders.py` 到新爬虫（`spiders/github_trending.py`、`spiders/huggingface.py`）
- [ ] #35 迁移 `tests/integration/test_github_integration.py` 到新爬虫
- [ ] #36 删除 4 个老爬虫死代码：`github_spider.py` / `huggingface_spider.py` / `hackernews_spider.py` / `artificial_analysis_spider.py`
- [ ] #37 编译校验 + 导入冒烟 + `pytest` 收集（`py_compile` + `import dacong_spider` + `pytest --collect-only`）

### Phase B — 完成数据底座（沿用 DATA_FOUNDATION M1-M4，约 10 天）
> 注：`test_rising_stars.py` / `test_model_evaluations.py` / `test_arxiv_spider.py` 已存在，说明部分代码已写，先核对再补缺口。

- [ ] M1 rising stars：`rising_stars_rankings` 表 + `v_repo_star_history` 视图 + `compute-rising-stars` edge function + `get-rising-stars` API（**前置：补 `arena_rankings` 等表的 migration**）
- [ ] M2 模型评测聚合：`model_evaluations` 表 + `artificial_analysis.py`/`arena.py`/`swebench.py` benchmark 解析 + `aggregate-evaluations` + `get-model-evaluations` API
- [ ] M3 模型能力完善：`models` 表扩字段（max_output_tokens / latency / multimodal / tool_use / fine_tunable）+ 解析增强 + `get-model-comparison`
- [ ] M4 资讯增强：确认 `arxiv_spider.py` / `ai_news_rss.py` 已接入 registry + `get-ai-news` 统一出口

### Phase C — 前端「AI 动态」聚焦（约 7 天）
- [ ] Console/Client 统一「动态」主页 + 三视图（资讯流 / 飙升榜 / 模型脉搏）
- [ ] 定位并清理咨询/专家/支付相关前端入口与路由

### Phase D — 上线与收敛（约 2 天）
- [ ] 调度：rising stars 每日 02:00 计算、资讯每日拉取（纳入 `schedulers/jobs.py`）
- [ ] 文档收敛：更新 `README.md` / `ARCHITECTURE.md`，归档 `AI_CONSULTING_PIVOT_PLAN.md` 为"已弃用"，本计划升为 active

---

## 5. 依赖与前置

| 依赖 | 用途 | 状态 |
|------|------|------|
| Supabase 项目 | 数据库 + Edge Functions | ✅ 已有 |
| GitHub Token | 精确 star 涨速（M1 可选增强） | ⚠️ 需配 `GITHUB_TOKEN` |
| Anthropic / OpenAI Key | 本计划**不需要**（已砍 RAG/对话） | — |
| 支付商户号 | 本计划**不需要**（已砍支付） | — |
| pgvector | 本计划**不需要**（已砍语义检索） | — |

---

## 6. 风险与注意事项

1. **删老文件前必须先迁测试**：`test_spiders.py` / `test_github_integration.py` 仍 `import spiders.github_spider`，删文件会致 `pytest` 收集失败（ImportError）。Phase A 顺序不可颠倒。
2. **表迁移缺失**：`arena_rankings` / `artificial_analysis_rankings` 爬虫里直接 upsert 但迁移文件未建表——Phase B 前必须补 migration，否则新环境失败。
3. **前端咨询残留**：Client/Console 可能存在咨询/专家/支付相关路由与页面，Phase C 需 grep 定位后清理（不删不影响运行，但属于死代码）。
4. **技术债文档过时**：`docs/VISUAL_ARCHITECTURE.md` / `ARCHITECTURE.md` / `CLASS_DIAGRAM.md` / `SUMMARY.md` / `GITHUB_SPIDER_SUMMARY.md` 仍描述老 `ApiSpider` 架构，Phase D 收敛时一并更新或注明"已废弃"。

---

## 7. 与旧计划的工作量对比

| 模块 | AI 咨询平台（旧） | 专注 AI 动态（新） |
|------|-------------------|---------------------|
| 数据底座 | ✅ 复用 | ✅ 复用（同） |
| RAG + 对话 | ~3 周 | ❌ 砍掉 |
| 咨询/专家/支付 | ~3 周 | ❌ 砍掉 |
| 前端聚焦 | 咨询 UI | 动态三视图 ~2 周 |
| **总估** | **9-12 周** | **约 3-4 周** |

> 砍掉最重的两块（对话引擎 + 交易系统），总工期从 9-12 周降到约 3-4 周，且不需要 LLM Key / 支付 / pgvector。
