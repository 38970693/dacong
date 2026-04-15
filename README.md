# DaCong - AI 模型排行与社区平台

AI 模型排行榜 + 社区交流 + 赋能学习的聚合平台。

## 项目结构

```
dacong/
├── dacong-client/          # 前端 (Flutter Web/Android/iOS)
├── dacong-api/          # 后端 (Supabase Edge Functions)
├── dacong-spider/       # 爬虫层 (Python/VPS)
├── dacong-docs/         # 项目文档
└── README.md
```

## 快速开始

### 前端

```bash
cd dacong-client
flutter pub get
flutter run -d chrome
```

### 后端

Supabase Cloud 免费版即可运行，配置环境变量后直接部署 Edge Functions。

### 爬虫

```bash
cd dacong-spider
pip install -r requirements.txt
python -m schedulers.jobs
```

## 技术栈

| 层级 | 技术 |
|------|------|
| 客户端 | Flutter 3.16+ |
| 后端 | Supabase (Auth + PostgreSQL + Realtime + Edge Functions) |
| 爬虫 | Python 3.11 + httpx + BeautifulSoup4 |
| 外部 Worker | OpenAI Moderation API |
| 推送 | FCM |

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
