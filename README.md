# DaCong - AI 模型排行与社区平台

AI 模型排行榜 + 社区交流 + 赋能学习的聚合平台。

## 🚀 快速启动

### 一键启动所有服务

**Windows:**
```bash
start-all.bat
```

**Linux/Mac:**
```bash
./start-all.sh
```

启动后访问：
- **前台客户端**: http://localhost:8081
- **后台管理**: http://localhost:8080
- **爬虫服务**: 后台运行（查看 `logs/spider.log`）

### 快速测试

**Windows:**
```bash
test-services.bat
```

**Linux/Mac:**
```bash
./test-services.sh
```

📖 详细启动说明见 [README_STARTUP.md](README_STARTUP.md)

## 项目结构

```
dacong/
├── dacong-client/          # 前台客户端 (Flutter Web/Android/iOS)
├── dacong-admin/           # 后台管理 (Flutter Web)
├── dacong-api/             # 后端 API (Supabase Edge Functions)
├── dacong-spider/          # 爬虫服务 (Python)
├── dacong-console/         # 控制台 (Next.js) - 可选
└── README.md
```

## 手动启动

### 1. 前台客户端

```bash
cd dacong-client
flutter pub get
flutter run -d chrome --web-port=8081 \
  --dart-define=DEV_MODE=true \
  --dart-define=SUPABASE_URL=https://twrxnqrisplmetbceyqm.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=你的anon_key
```

### 2. 后台管理

```bash
cd dacong-admin
flutter pub get
flutter run -d chrome --web-port=8080 \
  --dart-define=DEV_MODE=true \
  --dart-define=SUPABASE_URL=https://twrxnqrisplmetbceyqm.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=你的anon_key
```

或使用快捷脚本：
```bash
cd dacong-admin
./start-dev-with-config.bat  # Windows
```

### 3. 爬虫服务

```bash
cd dacong-spider
pip install -r requirements.txt
python main.py
```

### 4. 部署 Edge Functions

```bash
cd dacong-api
supabase link --project-ref twrxnqrisplmetbceyqm
supabase functions deploy auth-login
supabase functions deploy auth-register
supabase functions deploy admin-get-users
supabase functions deploy admin-handle-report
supabase functions deploy admin-get-reports
supabase functions deploy csrf-token

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
