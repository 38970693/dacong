# DaCong Worker

DaCong 项目的后台 Worker，负责：
- 爬虫抓取（36kr、虎嗅）
- AI 内容审核
- 榜单计算

## 快速开始

### 1. 安装依赖

```bash
cd dacong-worker
npm install
```

### 2. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env 填写实际值
```

### 3. 启动

```bash
# 开发模式（热重载）
npm run dev

# 生产模式
npm start
```

### 4. 单独运行任务

```bash
# 只爬取数据
npm run crawl

# 只运行审核
npm run moderate

# 只计算榜单
npm run trending
```

## 定时任务

| 任务 | 间隔 | 说明 |
|------|------|------|
| 爬虫 | 5 分钟 | 抓取 36kr、虎嗅最新文章 |
| 审核 | 30 秒 | AI 审核待发布内容 |
| 榜单 | 1 分钟 | 计算热榜、新榜 |

## 部署

### Railway（推荐）

1. 创建 Railway 项目
2. 连接 GitHub 仓库
3. 设置环境变量
4. 部署

### Docker

```bash
docker build -t dacong-worker .
docker run dacong-worker
```

## API 集成

### Supabase
- 使用 Service Role Key 连接数据库
- 写入 raw_posts、posts、trending_cache 表

### 阿里云内容安全（可选）
- 用于 AI 审核
- 免费额度：1000次/天
- 文档：https://help.aliyun.com/document_detail/28417.html

## 项目结构

```
dacong-worker/
├── src/
│   ├── index.ts          # 主入口，定时任务调度
│   ├── config.ts         # 环境变量验证
│   ├── logger.ts         # 日志
│   ├── supabase.ts       # Supabase 客户端
│   ├── types.ts          # 类型定义
│   ├── crawlers/
│   │   ├── index.ts      # 爬虫入口
│   │   ├── 36kr.ts       # 36kr 爬虫
│   │   └── huxiu.ts      # 虎嗅爬虫
│   ├── moderator.ts      # AI 审核
│   └── trending.ts       # 榜单计算
├── .env                  # 环境变量
├── package.json
└── tsconfig.json
```

## 监控

- 查看日志：`npm run start` 终端输出
- 健康检查：Worker 运行时会输出心跳日志