# DaCong 开发启动指南

> 版本：v1.0  
> 更新日期：2026-04-17

---

## 🎯 快速开始

本指南帮助你快速启动 DaCong 项目的开发环境。

---

## 📋 前置要求

### 必需工具

| 工具 | 版本 | 用途 |
|------|------|------|
| **Flutter** | 3.x+ | 前端开发 |
| **Python** | 3.11+ | 爬虫开发 |
| **Node.js** | 18+ | 后端开发（Deno会自动安装） |
| **Git** | 2.x+ | 版本控制 |
| **VS Code** | 最新版 | 推荐IDE |

### 可选工具

- **Docker** - 容器化部署
- **Postman** - API测试
- **DBeaver** - 数据库管理

---

## 🚀 环境配置

### 1. 克隆项目

```bash
cd e:\gitlab
git clone <your-repo-url> dacong
cd dacong
```

### 2. 配置 Supabase

#### 2.1 创建 Supabase 项目

1. 访问 https://supabase.com
2. 创建新项目
3. 记录以下信息：
   - Project URL: `https://xxx.supabase.co`
   - Anon Key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
   - Service Role Key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

#### 2.2 初始化数据库

```bash
cd dacong-api
# 安装 Supabase CLI
npm install -g supabase

# 登录
supabase login

# 链接项目
supabase link --project-ref <your-project-ref>

# 运行 migrations
supabase db push
```

### 3. 配置爬虫模块

```bash
cd dacong-spider

# 创建虚拟环境
python -m venv venv

# 激活虚拟环境
# Windows
venv\Scripts\activate
# Linux/Mac
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt

# 配置环境变量
cp .env.example .env
# 编辑 .env 文件，填入以下信息：
# SUPABASE_URL=https://xxx.supabase.co
# SUPABASE_KEY=your-service-role-key
# GITHUB_TOKEN=your-github-token
# REDDIT_CLIENT_ID=your-reddit-client-id
# REDDIT_CLIENT_SECRET=your-reddit-client-secret
```

### 4. 配置后端API

```bash
cd dacong-api

# 安装 Deno（如果未安装）
# Windows (PowerShell)
irm https://deno.land/install.ps1 | iex
# Linux/Mac
curl -fsSL https://deno.land/install.sh | sh

# 配置环境变量
cd supabase/functions
# 每个 function 都需要配置 .env
echo "SUPABASE_URL=https://xxx.supabase.co" > .env
echo "SUPABASE_ANON_KEY=your-anon-key" >> .env
```

### 5. 配置前端客户端

```bash
cd dacong-client

# 检查 Flutter 环境
flutter doctor

# 安装依赖
flutter pub get

# 配置 Supabase
# 编辑 lib/core/constants/app_constants.dart
# 修改以下内容：
# static const String supabaseUrl = 'https://xxx.supabase.co';
# static const String supabaseAnonKey = 'your-anon-key';

# 生成代码（freezed + json_serializable + injectable）
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 🧪 运行测试

### 爬虫模块测试

```bash
cd dacong-spider

# 运行所有测试
pytest

# 运行特定测试
pytest tests/test_github_spider.py

# 查看覆盖率
pytest --cov=core --cov=spiders --cov-report=html
```

### 后端API测试

```bash
cd dacong-api/supabase/functions

# 测试单个 function
deno test _shared/domain/Content.test.ts

# 测试所有
deno test --allow-all
```

### 前端测试

```bash
cd dacong-client

# 运行单元测试
flutter test

# 运行特定测试
flutter test test/core/domain/entities/content_test.dart

# 查看覆盖率
flutter test --coverage
```

---

## 🏃 启动开发服务器

### 1. 启动爬虫（后台运行）

```bash
cd dacong-spider

# 方式1：直接运行
python main.py

# 方式2：Docker运行
docker-compose up -d
```

### 2. 启动后端API（本地测试）

```bash
cd dacong-api

# 启动本地 Supabase
supabase start

# 部署 functions 到本地
supabase functions serve

# 测试 API
curl http://localhost:54321/functions/v1/get-recommendations \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"scenario": "coding", "language": "zh"}'
```

### 3. 启动前端（Web开发）

```bash
cd dacong-client

# 启动 Web 开发服务器
flutter run -d chrome

# 或者指定端口
flutter run -d chrome --web-port=8080
```

---

## 📁 项目结构

```
dacong/
├── dacong-docs/              # 📚 项目文档
│   ├── 00-架构总览.md
│   ├── 00-产品定位与战略.md
│   ├── 01-产品需求文档PRD.md
│   ├── 02-分阶段实施计划.md
│   ├── 03-系统架构设计.md
│   ├── 04-数据库设计.md
│   ├── 05-AI内容生成设计.md
│   └── 06-爬虫设计文档.md
│
├── dacong-spider/            # 🕷️ 爬虫模块（Python）
│   ├── core/                 # 核心抽象层
│   │   ├── interfaces.py     # 8个核心接口
│   │   ├── base.py          # BaseSpider + 工具类
│   │   ├── factory.py       # SpiderFactory
│   │   └── db.py            # 数据库连接
│   ├── spiders/             # 具体爬虫实现
│   │   ├── github_spider.py
│   │   ├── huggingface_spider.py
│   │   ├── openrouter_spider.py
│   │   ├── reddit_spider.py
│   │   └── hackernews_spider.py
│   ├── schedulers/          # 定时调度
│   │   └── scheduler.py
│   ├── tests/               # 单元测试
│   └── docs/                # 模块文档
│       ├── ARCHITECTURE.md
│       └── CLASS_DIAGRAM.md
│
├── dacong-api/              # 🔌 后端API（TypeScript + Deno）
│   └── supabase/
│       └── functions/
│           ├── _shared/     # 共享代码
│           │   ├── domain/          # 领域模型
│           │   ├── repositories/    # 仓储接口+实现
│           │   ├── services/        # 业务逻辑
│           │   ├── dto/            # 数据传输对象
│           │   └── infrastructure/ # 基础设施
│           ├── get-recommendations/  # API端点
│           ├── get-content-detail/
│           ├── submit-feedback/
│           ├── search-content/
│           └── get-weekly-report/
│
└── dacong-client/           # 📱 前端客户端（Flutter）
    ├── lib/
    │   ├── core/
    │   │   ├── domain/      # 领域层
    │   │   │   ├── entities/
    │   │   │   ├── repositories/
    │   │   │   └── usecases/
    │   │   ├── error/       # 错误处理
    │   │   ├── network/     # 网络层
    │   │   └── di/          # 依赖注入
    │   ├── data/            # 数据层
    │   │   ├── models/
    │   │   ├── repositories/
    │   │   └── datasources/
    │   └── presentation/    # 表现层
    │       ├── pages/
    │       ├── blocs/
    │       └── widgets/
    └── test/                # 测试
```

---

## 🔧 开发工作流

### 1. 创建新功能分支

```bash
git checkout -b feature/your-feature-name
```

### 2. 开发流程

#### 爬虫开发
1. 在 `spiders/` 创建新爬虫类
2. 继承 `BaseSpider`
3. 实现 `fetch_data()` 方法
4. 在 `factory.py` 注册爬虫
5. 编写单元测试
6. 运行测试验证

#### 后端开发
1. 在 `_shared/domain/` 定义实体
2. 在 `_shared/repositories/` 定义接口
3. 在 `_shared/services/` 实现业务逻辑
4. 创建新的 Edge Function
5. 编写单元测试
6. 本地测试 API

#### 前端开发
1. 在 `core/domain/` 定义实体和用例
2. 在 `data/` 实现仓储
3. 在 `presentation/` 创建 BLoC 和页面
4. 编写 Widget 测试
5. 运行应用验证

### 3. 提交代码

```bash
# 运行测试
pytest  # 爬虫
deno test --allow-all  # 后端
flutter test  # 前端

# 提交代码
git add .
git commit -m "feat: add new feature"
git push origin feature/your-feature-name
```

### 4. 创建 Pull Request

1. 在 GitLab 创建 MR
2. 等待 CI/CD 通过
3. 代码审查
4. 合并到 main

---

## 🐛 常见问题

### Q1: Flutter 依赖安装失败

```bash
# 清理缓存
flutter clean
flutter pub cache repair
flutter pub get
```

### Q2: Supabase 连接失败

检查：
1. `.env` 文件配置是否正确
2. Supabase 项目是否启动
3. 网络连接是否正常

### Q3: 爬虫运行失败

检查：
1. API Token 是否配置
2. 网络是否可以访问目标网站
3. 查看日志文件

### Q4: 代码生成失败

```bash
# Flutter
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs

# 如果还是失败，删除生成的文件
find . -name "*.g.dart" -delete
find . -name "*.freezed.dart" -delete
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📚 学习资源

### 架构设计
- [00-架构总览.md](./00-架构总览.md) - 整体架构
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [SOLID 原则](https://en.wikipedia.org/wiki/SOLID)

### Flutter
- [Flutter 官方文档](https://flutter.dev/docs)
- [BLoC 模式](https://bloclibrary.dev/)
- [Clean Architecture in Flutter](https://resocoder.com/flutter-clean-architecture-tdd/)

### Supabase
- [Supabase 官方文档](https://supabase.com/docs)
- [Edge Functions](https://supabase.com/docs/guides/functions)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)

### Python
- [Scrapy 文档](https://docs.scrapy.org/)
- [APScheduler 文档](https://apscheduler.readthedocs.io/)

---

## 🎯 下一步

1. ✅ 阅读架构文档
2. ✅ 配置开发环境
3. ⏳ 运行测试验证
4. ⏳ 开始开发第一个功能
5. ⏳ 提交第一个 PR

---

## 📞 获取帮助

遇到问题？
1. 查看相关模块的 README
2. 查看 `dacong-docs/` 文档
3. 创建 Issue
4. 联系团队成员

---

**文档版本**：v1.0  
**最后更新**：2026-04-17  
**维护者**：DaCong Team
