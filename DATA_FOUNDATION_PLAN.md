# DaCong 数据底座实施计划（AI 资讯 / 涨星项目 / 大模型评测 / 大模型能力）

> 目标定位：在现有 DaCong 项目上，先把「数据底座」搭起来——四大领域的数据采集、存储、计算与对外暴露。
> 本计划是 **数据层 + 计算层 + API/前端暴露**，暂不含 AI 咨询对话（后续阶段）。
> 核心原则：**最大化复用现有代码，只补缺口，不推翻重来。**

---

## 0. 现状盘点（已有什么，能直接复用）

| 领域 | 已有能力 | 位置 | 复用度 |
|------|----------|------|--------|
| **AI 资讯** | `hot_news_raw` 表 + HackerNews / Reddit 爬虫 + AI 关键词过滤（`is_ai_related`） + `hot-news` edge function 去重入库 | `dacong-spider/spiders/hackernews*.py`、`reddit_spider.py` | 80% |
| **GitHub 涨星** | `github_trending.py` 抓 trending（含 stars_today）；`repository_metrics` 表按 `fetched_at` 做**每日时间序列**（24h 去重→每天一条）；`weekly_generator.py` 已算 `star_growth` | `dacong-spider/spiders/github_trending.py`、`core/weekly_generator.py` | 60%（时间序列在，缺实时增速榜） |
| **大模型评测** | `arena.py` → `arena_rankings`（ELO / 投票数 / category / 置信区间）；`artificial_analysis.py` → 价格/上下文窗口/function calling | `dacong-spider/spiders/arena.py`、`artificial_analysis.py` | 50%（缺 benchmark 分数） |
| **大模型能力** | `artificial_analysis.py` 已抓 context_window / function_calling / supports_images / json_mode / 价格 | 同上 | 70% |

**基础设施已就绪**：Supabase（PostgreSQL + RLS）、爬虫框架（SpiderBase / ApiSpider / 注册表）、调度器、Sentry、Docker、CI/CD。

---

## 1. 缺口分析（还差什么）

1. **GitHub 涨星**：数据时间序列每天都在累积，但**没人把它算成「增速排行榜」对外暴露**。GitHub trending 页面只给「今日星」，且只覆盖 trending 仓库；要抓任意仓库的精确涨速，需用 **GitHub API stargazers 时间戳**。缺 `rising_stars` 计算 + 存储 + API + 前端视图。
2. **大模型评测**：`artificial_analysis.py` 目前只解析价格/能力，**没抓 benchmark 分数**（MMLU / GPQA / HumanEval / MATH 等）；LMArena 只有 ELO。缺统一的 `model_evaluations` 评测表与聚合。
3. **大模型能力**：基本覆盖，可 enriched（max_output_tokens、latency、throughput、multimodal 类型、fine-tuning）。
4. **AI 资讯**：只有 HN/Reddit 两个源，可加 arXiv、AI 媒体 RSS 提升覆盖面。

> ⚠️ **技术债提醒**：爬虫存在两套并行架构（`SpiderBase`+`Writer` vs `ApiSpider`+`BaseRankingsSpider`），且 `github_spider.py` 与 `github_trending.py` 重复。本计划优先复用，不强制统一，但 M1 增强时顺手清理 `github_spider.py` 死代码。

---

## 2. 里程碑计划（4 个 M，按优先级排序）

### M1 — GitHub 快速涨星（rising stars）⭐ 最高优先级

**为什么先做**：数据已经在每天累积（`repository_metrics` 时间序列），只需加「计算 + 暴露」两层，ROI 最高。

**数据库变更**
```sql
-- 飙升榜快照表（每日计算后写入）
CREATE TABLE IF NOT EXISTS public.rising_stars_rankings (
  id            BIGSERIAL PRIMARY KEY,
  repo_name     TEXT NOT NULL,
  repo_url      TEXT NOT NULL,
  owner         TEXT,
  language      TEXT,
  description   TEXT,
  total_stars   INTEGER DEFAULT 0,
  stars_1d      INTEGER DEFAULT 0,   -- 近 1 日新增
  stars_7d      INTEGER DEFAULT 0,   -- 近 7 日新增
  stars_30d     INTEGER DEFAULT 0,  -- 近 30 日新增
  velocity      NUMERIC(10,4),       -- 增速斜率（stars/day）
  rank_score    NUMERIC(10,4),       -- 综合排序分
  snapshot_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(repo_name, snapshot_date)
);

-- 基于 repository_metrics 时间序列的视图（无需额外存储即可查历史）
CREATE OR REPLACE VIEW public.v_repo_star_history AS
SELECT
  repo_name,
  repo_url,
  language,
  description,
  stars AS total_stars,
  fetched_at,
  stars - LAG(stars) OVER (
    PARTITION BY repo_name ORDER BY fetched_at
  ) AS daily_delta
FROM public.repository_metrics
ORDER BY repo_name, fetched_at;
```

**计算层（新增 edge function `compute-rising-stars`）**
- 输入：读取 `repository_metrics` 最近 30 天数据
- 计算：每个 repo 的 `stars_1d/7d/30d` 增量 + 线性拟合 `velocity`
- 综合 `rank_score = 0.5*stars_7d + 0.3*velocity + 0.2*stars_1d`
- 写入 `rising_stars_rankings`（ON CONFLICT 按 `repo_name+snapshot_date` upsert）

**爬虫增强（`github_trending.py`）**
- 对重点 repo 调用 GitHub API `GET /repos/{owner}/{repo}` 拿精确 `stargazers_count`
- 可选：`GET /repos/{owner}/{repo}/stargazers?per_page=1` + 时间戳推算月度涨速（更准，需鉴权 token）

**API（`get-rising-stars`）**：返回 Top N 飙升仓库（支持 1d/7d/30d 维度筛选）

**前端（`dacong-client/lib/presentation/pages/ranking/`）**：新增「飙升榜」Tab，展示涨速与趋势 mini 图

**调度**：纳入 `dacong-spider/schedulers/jobs.py`，每日 02:00 跑 `compute-rising-stars`

---

### M2 — 大模型评测聚合

**数据库变更**
```sql
CREATE TABLE IF NOT EXISTS public.model_evaluations (
  id          BIGSERIAL PRIMARY KEY,
  model_id    UUID REFERENCES public.models(id) ON DELETE CASCADE,
  benchmark   TEXT NOT NULL,        -- 'MMLU' | 'GPQA' | 'HumanEval' | 'MATH' | 'Arena-ELO'
  score       NUMERIC(10,4),
  category    TEXT,                 -- 'general' | 'coding' | 'math' | 'vision' | 'chinese'
  source      TEXT NOT NULL,         -- 'artificial_analysis' | 'lmarena'
  eval_date   DATE NOT NULL DEFAULT CURRENT_DATE,
  raw_data    JSONB DEFAULT '{}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(model_id, benchmark, category, source, eval_date)
);
```

**爬虫增强**
- `artificial_analysis.py`：`_parse_api_response` 增加 `mmlu`、`gpqa`、`human_eval`、`math` 等字段解析（API 返回里一般带 `leaderboard` 子对象）
- `arena.py`：补全 `category` 维度（general/coding/math/vision/chinese），ELO 作为 `benchmark='Arena-ELO'` 写入 `model_evaluations`
- 新增 `swebench.py` 已存在 → 接入 `model_evaluations`（`benchmark='SWE-bench'`）

**计算层（`aggregate-evaluations`）**：按 model 聚合多 benchmark，生成对比数据

**API（`get-model-evaluations`）**：按 model_id / benchmark / category 查询

**前端**：模型详情页增加「评测成绩」表格 + 雷达图（多 benchmark 对比）

---

### M3 — 大模型能力完善

**数据库变更**
```sql
-- 在 models 表扩展能力字段（或独立 model_capabilities 表）
ALTER TABLE public.models ADD COLUMN IF NOT EXISTS
  max_output_tokens   INTEGER,
  latency_ms          INTEGER,
  throughput_tps      INTEGER,
  multimodal_inputs   TEXT[],     -- ['text','image','audio']
  tool_use            BOOLEAN DEFAULT FALSE,
  fine_tunable        BOOLEAN DEFAULT FALSE,
  context_window      INTEGER;
```

**爬虫增强（`artificial_analysis.py`）**：补全 `max_output_tokens`、延迟、吞吐、多模态输入类型等字段解析

**API + 前端**：`get-model-comparison` 提供能力对比表，前端做「模型横评」页

---

### M4 — AI 资讯增强与统一出口

**数据采集（可选扩展）**
- 新增 `arxiv_spider.py`：抓 `arxiv.org/list/cs.AI`、`cs.CL` 最新论文（RSS/API）
- 新增 `ai_news_rss.py`：抓主流 AI 媒体 RSS（可选）

**统一 API（`get-ai-news`）**：聚合 `hot_news_raw` + 新源，按时间/热度/`is_ai_related` 过滤

**前端**：`dacong-client` 的 news/community 页优化展示；`dacong-console` 的 reviews 页可作为编辑后台

---

## 3. 依赖与前置条件

| 依赖 | 用途 | 状态 |
|------|------|------|
| Supabase 项目 | 数据库 + Edge Functions | ✅ 已有 |
| GitHub Token | 精确 star 涨速（M1 可选增强） | ⚠️ 需配置环境变量 `GITHUB_TOKEN` |
| Anthropic / OpenAI API Key | 后续 AI 咨询阶段用，本计划暂不需要 | ⏳ 后续 |
| 调度器（cron） | 每日计算 rising stars / 拉取评测 | ✅ 已有 `schedulers/` |

---

## 4. 实施顺序建议

```
M1 (涨星) ──► M2 (评测) ──► M3 (能力) ──► M4 (资讯)
 ↑ ROI 最高      ↑ 数据最缺      ↑ 基本覆盖    ↑ 可延后
```

- **M1 可立即开工**：数据已就绪，只补计算+API+前端，约 3-5 天
- **M2 次之**：需改爬虫解析 + 建表，约 3-4 天
- **M3 轻量**：字段扩展 + 解析增强，约 2 天
- **M4 可选**：视资讯质量需求，约 2-3 天

---

## 5. 风险与注意事项

1. **GitHub API 限流**：精确 stargazers 时间戳需 token，注意 rate limit（无 token 60次/小时）
2. **artificial_analysis / lmarena API 稳定性**：这两个站点是反爬重点，需加 UA + 退避；失败降级到已有 trending 数据
3. **时间序列噪声**：`repository_metrics` 偶尔爬取失败会断点，计算增速时需插值或容忍缺失
4. **表未纳入迁移**：`arena_rankings` / `artificial_analysis_rankings` 在爬虫里直接 upsert 但迁移文件里没建表——M2 前需补 migration，否则新环境会失败
5. **死代码清理**：`github_spider.py`（ApiSpider 版）未被 registry 注册，M1 时一并删除或合并
