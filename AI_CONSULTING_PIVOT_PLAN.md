# DaCong 项目分析 & AI 咨询平台改造方案

> ⚠️ **已废弃（2026-09-15）**：咨询会话 / 专家市场 / 支付方向已放弃，
> 产品改为「AI 动态聚合与洞察平台」（纯聚合，不引入 LLM Key / pgvector）。
> 现行路线图见 [`docs/AI_DYNAMICS_ROADMAP.md`](docs/AI_DYNAMICS_ROADMAP.md)，
> 定位决策见 [`AI_DYNAMICS_REPOSITION_PLAN.md`](AI_DYNAMICS_REPOSITION_PLAN.md)。
> 本文仅作历史归档保留。

## 一、当前项目分析

### 项目定位

**DaCong（大聪）** 是一个 **AI 模型信息聚合平台**，核心功能是爬取各平台的 AI 资讯和模型数据，聚合展示给用户浏览互动。

### 技术架构（五大子系统）

| 子系统 | 技术栈 | 职责 |
|--------|--------|------|
| `dacong-spider` | Python + asyncio | 爬取 GitHub Trending / HuggingFace / HackerNews / OpenRouter / Reddit 的 AI 数据 |
| `dacong-api` | Deno + Supabase Edge Functions | 55+ 个 API 函数：认证 / 内容 / 排行 / 推荐 / 评论 / 收藏 / 管理 |
| `dacong-client` | Flutter (Clean Architecture) | 移动端 App：首页 / 资讯 / 排行 / 推荐 / 社区 / 搜索 |
| `dacong-console` | Next.js + React | Web 前台 + 管理后台 |
| `dacong-admin` | Flutter | 管理后台 App |

### 数据层

- **Supabase PostgreSQL**：主数据库（hot_news_raw, model_raw_metrics, repository_metrics, user_roles, audit_logs 等）
- **Redis**：缓存层
- **Sentry + Grafana + Loki**：监控体系已就绪

### 当前完成度

- 整体进度约 31.4%（35 个任务完成 11 个）
- 监控 / 部署文档 / Docker / CI-CD 已完成
- 安全加固（CSRF / 输入验证）未完成
- 测试覆盖率不足（客户端 45-50%，目标 80%）

---

## 二、改造为 AI 咨询平台的方案

### 核心思路

**不推翻重来，而是「叠加」**——现有信息聚合能力作为 AI 咨询的知识库底座，在其上新增咨询交互层。

### 改造分为三类

#### 1. 保留并复用（绿色）

| 现有模块 | 改造后角色 |
|----------|-----------|
| `dacong-spider` 爬虫系统 | 改为「知识库采集器」，爬取的数据不再是展示内容，而是 AI 咨询的知识来源 |
| `dacong-api` Supabase API | 扩展咨询相关接口，现有认证 / 用户 / 评论系统直接复用 |
| `dacong-client` Flutter App | 在现有页面基础上新增「咨询」入口和对话界面 |
| `dacong-console` Next.js Web | 新增咨询工作台 / 专家管理后台 |
| Supabase + Redis 基础设施 | 直接复用，仅需加表 |

#### 2. 新增模块（紫色）

**a) AI 对话引擎**
- 接入 LLM API（OpenAI / Anthropic / 国产大模型）
- 基于 RAG（检索增强生成）从爬虫知识库中检索相关内容
- 支持流式输出（SSE / WebSocket）
- 实现位置：新增 `dacong-api/supabase/functions/ai-chat/` Edge Function

**b) 咨询会话管理**
- 多轮对话上下文管理
- 咨询历史记录持久化
- 会话分类 / 标签 / 搜索
- 实现位置：新增 `consultations` + `consultation_messages` 数据表

**c) 专家 / Agent 市场**
- 人工专家入驻：资质审核 / 服务目录 / 预约系统
- AI Agent 接入：多个垂直领域 Agent（如 AI 选型、AI 落地方案、AI 成本估算）
- 混合咨询模式：AI 先答 → 不满意转人工专家

#### 3. 改造升级（橙色）

**a) 知识库体系**
- 爬虫数据 → 文本切片 → Embedding 向量化 → pgvector 存储
- 现有 `hot_news_raw` / `model_raw_metrics` 数据自动入库
- 支持人工补充知识文档

**b) 推荐系统升级**
- 从「内容推荐」升级为「方案推荐」
- 根据用户咨询历史，推荐相关 AI 工具 / 模型 / 落地方案
- 复用现有 `get-recommendations` 接口扩展

**c) 支付 / 订单系统**
- 咨询付费模式：按次 / 按时 / 包月
- 专家分成结算
- 复用现有 `user_roles` 表扩展专家角色

---

## 三、分阶段实施计划

### Phase 1：知识库 + AI 对话（2-3 周）

**目标**：用户可以向 AI 提问，AI 基于爬虫积累的数据回答

**数据库变更**：
```sql
-- 启用 pgvector 扩展
CREATE EXTENSION IF NOT EXISTS vector;

-- 知识库表
CREATE TABLE knowledge_chunks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_type TEXT NOT NULL,        -- 'news' | 'model' | 'manual'
  source_id UUID,
  content TEXT NOT NULL,
  embedding VECTOR(1536),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 向量索引
CREATE INDEX ON knowledge_chunks USING ivfflat (embedding vector_cosine_ops);
```

**新增 Edge Functions**：
- `ai-chat` — 接收用户问题，检索知识库，调用 LLM，流式返回
- `knowledge-search` — 向量相似度检索
- `knowledge-ingest` — 爬虫数据自动向量化入库

**关键代码路径**：
```
dacong-api/supabase/functions/
├── ai-chat/
│   └── index.ts          ← 新增：AI 对话主入口
├── knowledge-search/
│   └── index.ts          ← 新增：知识库检索
└── knowledge-ingest/
    └── index.ts          ← 新增：数据向量化
```

**验证标准**：
- [ ] 用户输入问题，AI 能基于爬虫数据回答
- [ ] 回答中引用信息来源
- [ ] 流式输出正常工作

### Phase 2：咨询会话 + 前端界面（2-3 周）

**目标**：完整的咨询交互体验，支持多轮对话和历史记录

**数据库变更**：
```sql
-- 咨询会话表
CREATE TABLE consultations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  title TEXT,
  category TEXT,                    -- 'ai_selection' | 'implementation' | 'cost' | 'other'
  status TEXT DEFAULT 'active',     -- 'active' | 'closed' | 'transferred'
  consultant_type TEXT DEFAULT 'ai',-- 'ai' | 'human' | 'hybrid'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 咨询消息表
CREATE TABLE consultation_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  consultation_id UUID REFERENCES consultations(id),
  role TEXT NOT NULL,               -- 'user' | 'assistant' | 'system'
  content TEXT NOT NULL,
  sources JSONB,                    -- 引用的知识库来源
  tokens_used INT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**前端改造**：

Flutter App（`dacong-client`）：
```
lib/presentation/pages/
├── consult/                        ← 新增
│   ├── consult_entry_page.dart     ← 咨询入口
│   ├── chat_page.dart              ← 对话界面
│   └── history_page.dart           ← 历史记录
```

Next.js Web（`dacong-console`）：
```
src/app/
├── consult/                        ← 新增
│   ├── page.tsx                    ← 咨询工作台
│   └── [id]/page.tsx               ← 会话详情
```

**验证标准**：
- [ ] 多轮对话上下文正确保持
- [ ] 咨询历史可查看 / 搜索 / 删除
- [ ] Flutter 和 Web 端均可正常咨询

### Phase 3：专家市场 + 支付系统（3-4 周）

**目标**：人工专家入驻，支持付费咨询

**数据库变更**：
```sql
-- 专家表
CREATE TABLE experts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  name TEXT NOT NULL,
  bio TEXT,
  expertise JSONB,                  -- 擅长领域
  hourly_rate DECIMAL(10,2),        -- 时薪
  rating DECIMAL(2,1) DEFAULT 5.0,
  status TEXT DEFAULT 'pending',    -- 'pending' | 'approved' | 'suspended'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 订单表
CREATE TABLE consultation_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  consultation_id UUID REFERENCES consultations(id),
  expert_id UUID REFERENCES experts(id),
  amount DECIMAL(10,2),
  status TEXT DEFAULT 'pending',    -- 'pending' | 'paid' | 'completed' | 'refunded'
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**核心功能**：
- 专家入驻申请 + 审核
- 服务目录展示
- AI 先答 → 转人工流程
- 支付集成（微信 / 支付宝）
- 评价系统

**验证标准**：
- [ ] 专家可申请入驻，管理员审核
- [ ] 用户可预约专家并支付
- [ ] AI 咨询不满意可转人工
- [ ] 评价和分成流程正常

### Phase 4：优化 + 上线（2 周）

- 咨询质量评价体系
- 数据分析看板（热门问题 / 满意度 / 转化率）
- 性能优化（向量检索缓存 / LLM 响应优化）
- 安全加固（完成现有 CSRF / 输入验证任务）
- 生产部署

---

## 四、改造成本估算

| 阶段 | 工作量 | 核心交付 |
|------|--------|---------|
| Phase 1 | 2-3 周 | 知识库 + RAG 问答 |
| Phase 2 | 2-3 周 | 咨询会话 + 前端 |
| Phase 3 | 3-4 周 | 专家市场 + 支付 |
| Phase 4 | 2 周 | 优化 + 上线 |
| **合计** | **9-12 周** | **完整 AI 咨询平台** |

### 关键依赖

- LLM API 密钥（OpenAI / Anthropic / 或国产大模型）
- Supabase 启用 pgvector 扩展
- 支付平台商户号（Phase 3）

---

## 五、现有代码复用率

| 现有模块 | 复用程度 | 说明 |
|----------|---------|------|
| 认证系统（7 个函数） | 100% 直接复用 | 注册 / 登录 / 权限完全复用 |
| 用户角色 / 审计日志 | 90% 复用 | 扩展 expert 角色即可 |
| 评论系统 | 70% 复用 | 改造为咨询评价 |
| 收藏系统 | 80% 复用 | 改造为咨询收藏 |
| 推荐系统 | 60% 复用 | 从内容推荐升级为方案推荐 |
| 爬虫系统 | 70% 复用 | 增加向量化管道 |
| 监控 / 部署体系 | 100% 复用 | Sentry / Grafana / Docker 不变 |
| **整体复用率** | **~75%** | 大部分基础设施可复用 |

---

## 六、风险与建议

1. **LLM 成本**：AI 咨询的 LLM 调用成本需控制，建议设置用量限制和缓存策略
2. **知识库质量**：爬虫数据需要清洗过滤，低质量内容会影响咨询效果
3. **合规风险**：AI 咨询涉及建议，需加免责声明，专家咨询需资质审核
4. **冷启动**：初期可先用 AI 咨询吸引用户，后期再引入专家市场
