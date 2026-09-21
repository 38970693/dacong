# DaCong AI 动态改造：产品规划与路线图

> 状态：**进行中** ｜ 最后更新：2026-09-14
> 本文是 `AI_DYNAMICS_REPOSITION_PLAN.md`（定位决策）的**执行版**，把定位落成可验收的任务。
> 定位决策以那份文档为准，本文只回答「做什么、按什么顺序做、做到什么算完」。

---

## 1. 产品定位

**一句话**：DaCong 是 AI 领域的动态聚合与洞察平台 —— 持续呈现 AI 世界正在发生的**变化**，而不是一次性快照。

| 维度 | 说明 |
|------|------|
| 目标用户 | AI 从业者与关注者，需要 daily 掌握"今天 AI 圈发生了什么" |
| 核心价值 | 三个"动态"视角：资讯流（今天发生了什么）、飙升榜（什么正在火）、模型脉搏（谁在进步） |
| 差异化 | 所有数据带时间维度与变化信号：涨速 velocity、评测 eval_date 历史、资讯时间流 |
| **不做** | 咨询对话、专家市场、支付、RAG / 语义检索、任何 LLM API 调用 |

> 最后一条是硬约束。产品是**纯聚合展示**，不引入 LLM Key、pgvector、向量检索。

---

## 2. 产品范围：三个动态视图

前端信息架构从"散落的多 tab"收敛为**一个「动态」主页 + 三个子视图**。

### 2.1 资讯流 · Feed
- 数据源：`hot_news_raw`（HN / Reddit / **X**）+ `arxiv` + `ai_news_rss`
- 排序：时间倒序 / 热度（可切换）
- **X 优先**：X 来源整体排在最前（`/api/dynamics/news` 按 source 权重排序，
  各来源内部仍按时间/热度排列，Array.sort 稳定所以不会打乱内部顺序）
- 过滤：`is_ai_related` + 来源 + 时间窗
- 关键交互：卡片展示来源徽标、发布时间、热度分

### 2.2 飙升榜 · Rising
- 数据源：`rising_stars_rankings`
- 排序：`velocity`（stars/day 斜率）降序
- 关键交互：每个仓库配 mini 趋势图（近 30 天 star 曲线）
- 语义：回答"哪个仓库**正在**火"，而非"哪个仓库星最多"

### 2.3 模型脉搏 · Pulse
- 数据源：`model_evaluations` + `models` + `arena_rankings` + `artificial_analysis_rankings`
- 关键交互：按 `eval_date` 画历史曲线（谁在进步）+ 多 benchmark 雷达图
- 语义：回答"哪个模型**在变强**"，而非"哪个模型分最高"

---

## 3. 数据模型

| 域 | 主表 / 视图 | 关键字段 | 迁移状态 |
|----|------------|---------|---------|
| 资讯 | `hot_news_raw` | `source`, `title`, `url`, `score`, `is_ai_related`, `fetched_at` | ✅ 已有 |
| 涨星 | `repository_metrics` | `full_name`, `total_stars`, `fetched_at`（每日时间序列） | ✅ 已有 |
| 涨星 | `rising_stars_rankings` | `stars_1d/7d/30d`, `velocity`, `rank_score`, `snapshot_date` | ✅ 已有 |
| 涨星 | `v_repo_star_history`（视图） | 基于时序查历史，无需额外存储 | ✅ 已有 |
| 评测 | `model_evaluations` | `model`, `benchmark`, `score`, `eval_date`, `category` | ✅ 已有 |
| 评测 | `arena_rankings` | ELO / 投票数 / category / 置信区间 | ✅ 已有 |
| 评测 | `artificial_analysis_rankings` | 价格 / context window / function calling | ✅ 已有 |
| 能力 | `models` | 待扩：`max_output_tokens`, `latency`, `multimodal`, `tool_use`, `fine_tunable` | ⚠️ 待扩字段 |

采集侧：`spiders/registry.py` 已注册 **11 个爬虫** ——
`github` / `huggingface` / `hackernews` / `swebench` / `arena` / `artificial_analysis` / `aiping` / `arxiv` / `ai_news_rss` / `x` / `bluesky`。

### 3.1 数据源策略：**免费优先**（Bluesky 主力，X 付费可选）

> **决策（2026-09-15）**：当前阶段一律优先免费源。全站 11 个爬虫里只有 X 需要付费，
> 其余（GitHub / HuggingFace / HackerNews / arXiv / RSS / Bluesky …）零成本。

| 数据源 | 成本 | 当前状态 |
|--------|------|---------|
| Bluesky | 免费，无需 token | ✅ 主力社交源（9 个已验证账号 + 关键词） |
| HackerNews / arXiv / RSS | 免费 | ✅ 已有 |
| GitHub / HuggingFace | 免费（可选填 token 提额） | ✅ 已有 |
| X (Twitter) | Basic 约 $200/月 | ⏸ 默认跳过，配 `X_BEARER_TOKEN` 后自动启用 |

X 爬虫按配置自动切换通道，**不需要改代码**：

| 通道 | 触发条件 | 数据质量 | 成本 |
|------|---------|---------|------|
| 官方 API v2 | 配了 `X_BEARER_TOKEN` | 完整，含点赞/转推数 | Basic 约 $200/月 |
| Nitter 镜像 RSS | 显式配了 `X_MIRRORS` | 无互动数（score=0） | 免费，但 2026-08-24 起主流实例已被 X Corp 关停 |
| **跳过** | token 与镜像都为空 | — | 零成本，日志打一条 warning |

> 2026-09-15 复核 42 个公开 Nitter 实例：**仅 `nitter.tiekoetter.com` 还能开页面，
> 但它直接返回 `RSS feed is disabled`**；其余 8 个有 Cloudflare/Anubis 验证墙、5 个重定向、28 个已死。
> 结论：X 免费通道目前无解，`X_MIRRORS` 保持留空。

追踪范围 = **KOL 账号时间线 + 关键词兜底**。默认 KOL 列表首位是
`thsottiaux`（Tibo / Thibault Sottiaux，OpenAI Codex & ChatGPT 产品负责人，67.8w 粉），
另有 karpathy / sama / ylecun / AndrewYNg / drfeifei / jimfan 等，
可用 `X_KOL_ACCOUNTS`、`X_KEYWORDS` 覆盖。

配置项（`.env`）：`X_BEARER_TOKEN`、`X_KOL_ACCOUNTS`、`X_KEYWORDS`、`X_MIRRORS`（默认留空）。

> 注意：项目里原有的 `rss_spider.py` 也写过 Twitter 实现，但它是死代码——
> 引用了不存在的 `MetricSource.TWITTER` 枚举，且从未注册进 registry。X 功能以 `x_trends.py` 为准。

#### Bluesky（推荐主力，免费）

`public.api.bsky.app` 是**公开只读端点，不需要任何 token**，且返回完整的点赞/转推/回复数。
已实测可用（karpathy.bsky.social 有真实内容，单条 230 赞 / 21 回复）。

| 端点 | 用途 |
|------|------|
| `app.bsky.feed.getAuthorFeed?actor=` | 账号时间线 |
| `app.bsky.feed.searchPosts?q=&sort=latest` | 关键词搜索 |

⚠️ **handle 不能照搬 X 账号名**：X 上的同名账号在 Bluesky 常被抢注成空号。
2026-09-15 用 `app.bsky.actor.getProfiles` 批量实测，**这些是空的/假的，别加**：
`sama`(0 帖) `jimfan`(2 粉) `demishassabis`(0 帖) `swyx`(0 帖) `andrewng`(2 帖)
`huggingface`(0 帖) `anthropic.com`(0 帖) `ggerganov`(0 帖) `drjimfan`(0 帖)
`sottiaux`(0 帖，Tibo 的姓氏号但不是他本人，他的主场在 X)；
`ylecun` / `openai.com` / `bindureddy` 则根本不存在。

已验证可用的默认列表（括号内为 粉丝数/发帖数）：

| handle | 身份 | 规模 |
|--------|------|------|
| `simonwillison.net` | Simon Willison（已认证） | 50.0k / 4909 |
| `emollick.bsky.social` | Ethan Mollick，Wharton（已认证） | 36.8k / 3154 |
| `karpathy.bsky.social` | Andrej Karpathy | 34.2k / 20 |
| `natolambert.bsky.social` | Nathan Lambert，Interconnects | 14.5k / 2145 |
| `thomwolf.bsky.social` | Thomas Wolf，HuggingFace 联创 | 12.7k / 122 |
| `rasbt.bsky.social` | Sebastian Raschka | 10.4k / 319 |
| `drfeifei.bsky.social` | 李飞飞 | 4.8k / 4 |
| `hardmaru.bsky.social` | David Ha，Sakana AI CEO | 4.7k / 234 |
| `sakanaai.bsky.social` | Sakana AI 官方 | 1.6k / 470 |

其余通过 `BSKY_KOL_ACCOUNTS` 配置，关键词搜索（`LLM` / `AI agent` / `open source AI`）作为兜底。

配置：`BSKY_KOL_ACCOUNTS`、`BSKY_KEYWORDS`、`BSKY_INTERVAL_MINUTES`。

#### 排序优先级

`/api/dynamics/news` 里 `X` 与 `Bluesky` 都属于优先源，整体排在 HN / Reddit / arXiv 之前，
各来源内部仍按时间或热度排列。

---

## 4. 现状盘点（2026-09-14 实测）

| 事项 | 状态 |
|------|------|
| 爬虫 registry 架构 | ✅ 9 个爬虫已注册并运行 |
| 涨星计算纯函数 `compute_velocity` / `compute_rank_score` | ✅ 已实现 + 单测通过（`tests/test_rising_stars.py`） |
| 评测解析 `parse_benchmarks` / `parse_capabilities` / `infer_vendor` | ✅ 已实现 + 单测（`tests/test_model_evaluations.py`） |
| arXiv 爬虫与测试 | ✅ 已实现（`tests/test_arxiv_spider.py`） |
| 数据库迁移（M1/M2） | ✅ `20260807_00001/00002` + `20260808_00003` 已建表 |
| 前端咨询/专家/支付残留 | ✅ **无残留**（已 grep 确认，Phase C 清理成本极低） |
| 老爬虫死代码 | ✅ 已删除（Phase A） |
| `tests/test_spiders.py` | ✅ 已迁移到 `SpiderBase` 新架构 |
| `tests/integration/test_github_integration.py` | ✅ 已迁移，真实网络测试默认 skip |
| Edge Functions | ✅ 已在 `dacong-api/supabase/functions/`（68 个），B 所需 6 个均已实现 |
| `models` 表能力字段 | ✅ 已扩（`20260807_00002` / `20260808_00003`） |
| 统一资讯出口 `get-ai-news` | ✅ 已实现 |
| **前端「动态」三视图** | ✅ 已建（`/web/dynamics`，Phase C） |
| 前端消费新 API | ✅ 已接 `api/dynamics/{news,rising,pulse}` |

> 结论：**后端几乎已经全部就绪**。表已建、纯函数已测、6 个 Edge Function 已实现且
> 幂等（如 `compute-rising-stars` 按 `repo_name,snapshot_date` upsert）。
> 缺口全在**前端**：三视图尚未建立，前端代码里没有任何一处调用这些 API。
> 因此 Phase B 实际已完成，工期可压缩到约 **1-2 周**。

> ⚠️ 注意：Edge Functions 在 `dacong-api/supabase/functions/`；
> 根目录下的 `dacong-api/functions/` 只有 3 个**空目录**（历史遗留），不要据此判断进度。

---

## 5. 路线图

### Phase A — 收尾技术债 ✅ 已完成（2026-09-14）

必须先做，否则删老文件会让 `pytest` 收集失败（ImportError）。

> 完成结果：4 个老爬虫已删除，2 个测试迁移到 `SpiderBase` 新架构（新增 `tests/mocks.py`
> 提供 `MockFetcher` / `MockWriter` 替身），`pytest tests/` 134 passed / 3 failed
> （失败项在 `test_content_generation.py`，因缺少 ANTHROPIC_API_KEY，与本阶段无关）。
> 顺带修复 `huggingface.py` 的 `lstrip("/models/")` 按字符集剥离 bug 与
> `ai_news_rss.py` 标题未做空白归一化的问题。

| # | 任务 | 验收标准 |
|---|------|---------|
| A1 | 迁移 `tests/test_spiders.py` 到新架构（`SpiderBase` + `do_fetch`） | 不再 import `github_spider` / `huggingface_spider` |
| A2 | 迁移 `tests/integration/test_github_integration.py` | 同上；集成测试走 `github_trending` |
| A3 | 删除 4 个老爬虫：`github_spider.py` / `huggingface_spider.py` / `hackernews_spider.py` / `artificial_analysis_spider.py` | 文件移除，无残留引用 |
| A4 | 编译 + 导入冒烟 + 测试收集 | `py_compile` 通过、`import dacong_spider` 成功、`pytest --collect-only` 无 ImportError |

**顺序不可颠倒**：A1/A2 未完成前不得执行 A3。

### Phase B — 数据底座收口 ✅ 已完成（2026-09-15 核实：代码已存在）

下列 7 项在 `dacong-api/supabase/functions/` 中均已实现，无需新建：
`compute-rising-stars`(183行) / `get-rising-stars`(129行) / `aggregate-evaluations`(237行) /
`get-model-evaluations`(107行) / `get-model-comparison`(236行) / `get-ai-news`(82行)，
`models` 表字段也已由 `20260807_00002`、`20260808_00003` 补齐。
仅需**部署到线上**（见 deploy-functions-manual.md）并验证。

| # | 任务 | 依赖 | 验收标准 |
|---|------|------|---------|
| B1 | `compute-rising-stars` Edge Function | A4 | 读 `v_repo_star_history`，写入 `rising_stars_rankings`，幂等（同 `snapshot_date` 覆盖） |
| B2 | `get-rising-stars` API | B1 | 支持 `?limit=&language=&days=`，按 `velocity` 降序 |
| B3 | `aggregate-evaluations` Edge Function | A4 | 汇总 arena / AA / swebench 到 `model_evaluations`，按 `eval_date` 留历史 |
| B4 | `get-model-evaluations` API | B3 | 支持 `?model=&benchmark=`，返回时间序列 |
| B5 | `models` 表扩字段 migration | — | 新增 `max_output_tokens` / `latency` / `multimodal` / `tool_use` / `fine_tunable` |
| B6 | `get-model-comparison` API | B5 | 支持多模型横向对比 |
| B7 | `get-ai-news` 统一出口 | — | 聚合 `hot_news_raw` + `arxiv` + `ai_news_rss`，统一分页与 `is_ai_related` 过滤 |

### Phase C — 前端「动态」三视图 ✅ C1-C4 已完成（2026-09-15）

落地位置：
- 页面：`dacong-console/src/app/web/dynamics/page.tsx`（三视图切换）
- 组件：`src/components/dynamics/` —— `NewsFeed` / `RisingList` / `ModelPulse` / `Sparkline`
- 数据接口：`src/app/api/dynamics/{news,rising,pulse}/route.ts`

取数走 **Next.js API Route 直连 Supabase**（与项目现有 30+ 个 API 一致），
而非调用 Edge Function，因此不依赖 Edge Function 的部署状态。

图表用**手写 SVG**（`Sparkline` / `TrendLine`），不引入 recharts 等新依赖。
雷达图降级为「最新分数横向条形 + 历史折线」，信息等价且更易读。

> ⚠️ console 是静态导出模式（`output: export`）：新增 API route 必须加
> `export const dynamic = 'force-static';`，否则请求直接 500。这是本项目最容易踩的坑。


| # | 任务 | 验收标准 |
|---|------|---------|
| C1 | 「动态」主页 `/web/dynamics` 骨架 | 三视图切换，移动端可用 |
| C2 | 资讯流视图 | 接 `get-ai-news`，时间/热度双排序，来源筛选 |
| C3 | 飙升榜视图 | 接 `get-rising-stars`，velocity 排序 + 30 天 mini 趋势图 |
| C4 | 模型脉搏视图 | 接 `get-model-evaluations`，历史曲线 + benchmark 雷达图 |
| C5 | 旧入口收敛 | ⚠️ 部分完成：首页已加「AI 动态」入口卡片；死路由暂保留（删除有风险且不影响运行，建议单独评估后再动） |

### Phase D — 调度与上线 ✅ 已完成（2026-09-15）

| # | 任务 | 状态 |
|---|------|------|
| D1 | 调度：飙升榜每日 02:00 UTC 计算 | ✅ 已提供 `dacong-api/supabase/deploy-cron-compute-rising-stars.sql`（pg_cron + pg_net，占位符需替换后手动执行）。资讯抓取由 `schedulers/jobs.py` 已有的爬虫调度 + 每日 03:00 全量汇总覆盖 |
| D2 | 文档收敛 | ✅ `README.md` 新增「AI 动态」章节；`AI_CONSULTING_PIVOT_PLAN.md` 已标注废弃；本文为 active 路线图 |

---

## 6. 排期估算

| 阶段 | 内容 | 估算 |
|------|------|------|
| Phase A | 技术债收尾 | 1 天 |
| Phase B | 5 个 Edge Function + 2 个 migration + 1 个 API | 5-7 天 |
| Phase C | 前端三视图 | 5-7 天 |
| Phase D | 调度 + 文档 | 1 天 |
| **合计** | | **约 2-3 周** |

### 依赖

| 依赖 | 用途 | 状态 |
|------|------|------|
| Supabase 项目 | 数据库 + Edge Functions | ✅ 已有 |
| `GITHUB_TOKEN` | 精确 star 涨速（B1 可选增强） | ⚠️ 建议配置 |
| LLM API Key | **不需要**（已砍 RAG） | — |
| 支付商户号 | **不需要** | — |
| pgvector | **不需要** | — |

---

## 7. 风险

1. **删老文件前必须迁测试** —— 否则 `pytest` 收集即挂。Phase A 顺序强制。
2. **`CREATE TABLE IF NOT EXISTS` 不补列** —— `schema_reconcile` 迁移已注明此坑；B5 扩字段必须用 `ALTER TABLE ADD COLUMN IF NOT EXISTS`。
3. **Edge Function 幂等性** —— B1/B3 每日重复执行，需按业务键（如 `snapshot_date`）upsert，否则数据翻倍。
4. **arXiv / AA 源解析脆弱** —— 第三方页面改版会静默返回空数据；需监控 `items_fetched == 0` 告警。
5. **测试依赖真实网络** —— 迁移后的集成测试应默认 skip（无网络时），避免 CI 偶发红。

---

## 8. 完成度度量

| 指标 | 目标 |
|------|------|
| 爬虫覆盖率 | 9 个注册爬虫全部成功入库 |
| 数据新鲜度 | 资讯 ≤ 6h，涨星 ≤ 24h，评测 ≤ 7d |
| API 可用性 | 5 个新 Edge Function P95 < 800ms |
| 前端 | 三视图在移动端 375px 宽度无横向滚动 |
| 测试 | `pytest` 全绿，无 ImportError |
