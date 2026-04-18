# DaCong Docker 部署快速指南

## 一键启动

```bash
# 1. 配置环境变量
cp .env.example .env
vim .env  # 配置 SUPABASE_URL, SUPABASE_ANON_KEY, ANTHROPIC_API_KEY

# 2. 启动所有服务
./scripts/docker-start.sh

# 3. 验证部署
./scripts/docker-health-check.sh
```

## 访问地址

- **客户端**: http://localhost
- **管理后台**: http://localhost:8080  
- **API**: http://localhost:8000
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

## 服务架构

```
┌─────────────────────────────────────────┐
│         Docker Network                   │
│                                          │
│  Client:80  Admin:8080  API:8000       │
│      │          │          │            │
│      └──────────┴──────────┘            │
│              │                           │
│    ┌─────────┴─────────┐                │
│    │                   │                │
│  PostgreSQL:5432   Redis:6379  Spider  │
└─────────────────────────────────────────┘
```

## 镜像大小

| 服务 | 大小 | 说明 |
|------|------|------|
| postgres | 80MB | PostgreSQL 15 Alpine |
| redis | 30MB | Redis 7 Alpine |
| api | 150MB | Deno Edge Functions |
| spider | 200MB | Python 爬虫 |
| client | 50MB | Flutter Web + Nginx |
| admin | 50MB | Flutter Web + Nginx |
| **总计** | **560MB** | 多阶段构建优化 |

## 常用命令

```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart api

# 停止所有服务
docker-compose down

# 停止并删除数据
docker-compose down -v
```

## 环境变量

必须配置（`.env` 文件）：

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
ANTHROPIC_API_KEY=your_anthropic_key
POSTGRES_PASSWORD=your_secure_password
REDIS_PASSWORD=your_redis_password
```

## 开发模式

```bash
# 使用开发配置启动
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# 特性：
# - 代码热重载
# - 详细日志
# - 调试端口暴露
```

## 故障排查

```bash
# 检查服务健康
docker-compose ps

# 查看详细日志
docker-compose logs api

# 进入容器调试
docker-compose exec api sh

# 重新构建
docker-compose build --no-cache api
```

## 完整文档

详见 [Docker 部署文档](./dacong-docs/deployment/DOCKER_DEPLOYMENT.md)
