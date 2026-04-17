# DaCong - AI 模型排行与社区平台

AI 模型排行榜 + 社区交流 + 赋能学习的聚合平台。

## 项目结构

```
dacong/
├── dacong-client/          # 前端 (Flutter Web/Android/iOS)
├── dacong-api/             # 后端 (Supabase Edge Functions + PostgreSQL)
├── dacong-spider/          # 爬虫层 (Python / VPS 自动调度)
├── dacong-docs/            # 项目文档
└── README.md
```

## 快速开始

### 前端

```bash
cd dacong-client
flutter pub get
flutter run -d chrome       # Web 开发
flutter run -d android      # Android
flutter run -d ios           # iOS（仅 macOS）
```

### 后端

Supabase Cloud 免费版即可运行，配置环境变量后直接部署 Edge Functions。

```bash
cd dacong-api
supabase link --project-ref <ref>
supabase db push
supabase functions deploy model-rank-calc
supabase functions deploy content-moderation
supabase functions deploy push-trigger
```

### 爬虫

```bash
cd dacong-spider
pip install -r requirements.txt

# 配置环境变量
export SUPABASE_URL="https://xxx.supabase.co"
export SUPABASE_SERVICE_ROLE_KEY="your-key"

# 方式1：持续运行（定时调度，自动更新数据库）
python -m schedulers.jobs

# 方式2：GitLab CI scheduled pipeline 自动运行（见 .gitlab-ci.yml）
```

## 技术栈

| 层级 | 技术 |
|------|------|
| 客户端 | Flutter 3.16+ (Web / Android / iOS) |
| 后端 | Supabase (Auth + PostgreSQL + Realtime + Edge Functions) |
| 爬虫 | Python 3.11 + httpx + APScheduler |
| 外部 Worker | OpenAI Moderation API |
| 推送 | FCM |

## 自动运行

爬虫通过 APScheduler 自动调度，支持以下两种方式：

| 方式 | 说明 |
|------|------|
| APScheduler（推荐） | 直接在服务器运行 `python -m schedulers.jobs`，无额外依赖 |
| GitLab CI Scheduled Pipeline | GitLab CI 每小时触发爬虫 job，写入 Supabase |
| pg_cron（Supabase） | Supabase 内置 cron，调度 model-rank-calc Edge Function |

### GitLab CI 定时触发爬虫

`.gitlab-ci.yml` 中已配置每小时定时 pipeline：

```yaml
spider-run:
  stage: run
  image: python:3.11-slim
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      variables:
        SCHEDULE: "0 * * * *"
  script:
    - pip install -r dacong-spider/requirements.txt
    - python -m schedulers.jobs
  only:
    refs:
      - schedules
```

在 GitLab CI/CD → Schedules 中创建定时任务：
- **Interval pattern**: `0 * * * *`（每小时）
- **Target pipeline**: `dacong`

## 文档

| 文档 | 说明 |
|------|------|
| 01-产品需求文档PRD.md | 产品定位、功能清单、用户故事 |
| 02-技术方案设计.md | 架构设计、技术选型 |
| 03-数据库设计.md | 表结构、ER图、索引 |
| 04-API接口文档.md | REST API、Realtime 订阅 |
| 05-爬虫设计文档.md | 数据源、爬取策略 |
| 06-前端设计文档.md | 页面结构、组件设计 |
| 07-部署运维文档.md | 部署、监控、备份 |

## 开发阶段

- [x] Phase 0: 项目骨架搭建
- [ ] Phase 1: 核心功能
- [ ] Phase 2: 社交功能
- [ ] Phase 3: 运营能力

---

**GitLab:** https://gitlab.com/nb1935338/dacong
