# Docker 部署文档

## 概述

DaCong 项目采用 Docker 容器化部署，支持一键启动所有服务。本文档提供完整的 Docker 部署指南。

## 架构

```
┌─────────────────────────────────────────────────────────┐
│                    Docker Network                        │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │ Client   │  │  Admin   │  │   API    │             │
│  │  :80     │  │  :8080   │  │  :8000   │             │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘             │
│       │             │              │                    │
│       └─────────────┴──────────────┘                    │
│                     │                                    │
│              ┌──────┴──────┐                            │
│              │             │                            │
│       ┌──────▼─────┐ ┌────▼─────┐  ┌──────────┐       │
│       │ PostgreSQL │ │  Redis   │  │  Spider  │       │
│       │   :5432    │ │  :6379   │  │          │       │
│       └────────────┘ └──────────┘  └──────────┘       │
└─────────────────────────────────────────────────────────┘
```

## 服务清单

| 服务 | 端口 | 说明 | 镜像大小 |
|------|------|------|----------|
| postgres | 5432 | PostgreSQL 15 数据库 | ~80MB |
| redis | 6379 | Redis 7 缓存 | ~30MB |
| api | 8000 | Deno Edge Functions | ~150MB |
| spider | - | Python 爬虫服务 | ~200MB |
| client | 80 | Flutter Web 客户端 | ~50MB |
| admin | 8080 | Flutter Web 管理后台 | ~50MB |

**总镜像大小**: ~560MB

## 快速开始

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+
- 8GB+ 可用内存
- 20GB+ 可用磁盘空间

### 1. 环境配置

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑环境变量（必须配置）
vim .env
```

**必须配置的环境变量**:

```bash
# Supabase 配置（从 Supabase 控制台获取）
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here

# AI 配置
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# 数据库密码（生产环境必须修改）
POSTGRES_PASSWORD=your_secure_password_here
REDIS_PASSWORD=your_redis_password_here
```

### 2. 一键启动

```bash
# 构建并启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 3. 验证部署

```bash
# 检查所有服务健康状态
docker-compose ps

# 测试 API
curl http://localhost:8000/health

# 访问客户端
open http://localhost

# 访问管理后台
open http://localhost:8080
```

## 服务详解

### PostgreSQL 数据库

```yaml
postgres:
  image: postgres:15-alpine
  volumes:
    - postgres-data:/var/lib/postgresql/data
    - ./dacong-api/supabase/migrations:/docker-entrypoint-initdb.d:ro
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U postgres"]
```

**特性**:
- 自动执行数据库迁移脚本
- 数据持久化到 Docker volume
- 健康检查确保服务可用

**连接信息**:
```bash
Host: localhost
Port: 5432
Database: dacong
User: postgres
Password: (见 .env 文件)
```

### Redis 缓存

```yaml
redis:
  image: redis:7-alpine
  command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
  volumes:
    - redis-data:/data
```

**特性**:
- AOF 持久化
- 密码保护
- 数据持久化

**连接信息**:
```bash
Host: localhost
Port: 6379
Password: (见 .env 文件)
```

### API 服务

基于 Deno 的 Supabase Edge Functions。

**Dockerfile 优化**:
- 多阶段构建减小镜像大小
- 依赖缓存加速构建
- 健康检查确保服务可用

**环境变量**:
```bash
DATABASE_URL=postgresql://...
SUPABASE_URL=https://...
SUPABASE_ANON_KEY=...
PORT=8000
```

### Spider 爬虫服务

基于 Python 的数据采集服务。

**Dockerfile 优化**:
- 多阶段构建分离编译和运行时依赖
- 非 root 用户运行提升安全性
- 仅安装运行时必需的系统库

**环境变量**:
```bash
DATABASE_URL=postgresql://...
ANTHROPIC_API_KEY=...
SPIDER_INTERVAL=3600  # 采集间隔（秒）
MAX_WORKERS=4         # 并发数
```

### Client 客户端

Flutter Web 应用，使用 Nginx 提供服务。

**Dockerfile 优化**:
- 多阶段构建：Flutter 构建 + Nginx 运行
- 构建阶段 ~2GB，运行时镜像仅 ~50MB
- Gzip 压缩减少传输大小
- 静态资源长缓存策略

**Nginx 配置亮点**:
```nginx
# 静态资源长缓存
location ~* \.(js|css|woff|woff2)$ {
  expires 1y;
  add_header Cache-Control "public, immutable";
}

# HTML 不缓存
location / {
  add_header Cache-Control "no-cache, no-store, must-revalidate";
}

# API 代理
location /api/ {
  proxy_pass http://api:8000/;
}
```

### Admin 管理后台

与 Client 类似的 Flutter Web 应用。

## 常用命令

### 服务管理

```bash
# 启动所有服务
docker-compose up -d

# 启动指定服务
docker-compose up -d api spider

# 停止所有服务
docker-compose down

# 停止并删除数据卷（危险操作）
docker-compose down -v

# 重启服务
docker-compose restart api

# 查看服务状态
docker-compose ps

# 查看资源占用
docker stats
```

### 日志查看

```bash
# 查看所有服务日志
docker-compose logs -f

# 查看指定服务日志
docker-compose logs -f api

# 查看最近 100 行日志
docker-compose logs --tail=100 spider

# 查看实时日志（带时间戳）
docker-compose logs -f --timestamps
```

### 构建与更新

```bash
# 重新构建所有镜像
docker-compose build

# 重新构建指定服务
docker-compose build api

# 不使用缓存重新构建
docker-compose build --no-cache

# 拉取最新镜像
docker-compose pull

# 更新并重启服务
docker-compose up -d --build
```

### 数据库操作

```bash
# 进入 PostgreSQL 容器
docker-compose exec postgres psql -U postgres -d dacong

# 备份数据库
docker-compose exec postgres pg_dump -U postgres dacong > backup.sql

# 恢复数据库
docker-compose exec -T postgres psql -U postgres dacong < backup.sql

# 查看数据库大小
docker-compose exec postgres psql -U postgres -c "\l+"
```

### 调试

```bash
# 进入容器 shell
docker-compose exec api sh
docker-compose exec spider bash

# 查看容器详细信息
docker inspect dacong-api

# 查看网络配置
docker network inspect dacong_dacong-network

# 查看卷信息
docker volume inspect dacong_postgres-data
```

## 性能优化

### 构建优化

**1. 利用构建缓存**

```dockerfile
# 先复制依赖文件
COPY requirements.txt .
RUN pip install -r requirements.txt

# 再复制源代码（源代码变更不会重新安装依赖）
COPY . .
```

**2. 多阶段构建**

```dockerfile
# 构建阶段
FROM flutter:stable AS build
RUN flutter build web

# 运行阶段（仅包含构建产物）
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
```

**3. .dockerignore**

排除不必要的文件加速构建：

```
node_modules/
.git/
*.md
tests/
```

### 运行时优化

**1. 资源限制**

```yaml
services:
  api:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

**2. 健康检查**

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

**3. 依赖顺序**

```yaml
depends_on:
  postgres:
    condition: service_healthy  # 等待数据库就绪
```

## 生产环境部署

### 安全加固

**1. 使用 secrets 管理敏感信息**

```yaml
services:
  api:
    secrets:
      - db_password
      - api_key

secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_key:
    file: ./secrets/api_key.txt
```

**2. 非 root 用户运行**

```dockerfile
RUN useradd -m -u 1000 appuser
USER appuser
```

**3. 只读文件系统**

```yaml
services:
  api:
    read_only: true
    tmpfs:
      - /tmp
```

### 监控与日志

**1. 集成 Prometheus**

```yaml
services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
```

**2. 日志聚合**

```yaml
services:
  api:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### 高可用部署

**1. 使用 Docker Swarm**

```bash
# 初始化 Swarm
docker swarm init

# 部署 stack
docker stack deploy -c docker-compose.yml dacong

# 扩展服务
docker service scale dacong_api=3
```

**2. 使用 Kubernetes**

参考 `k8s/` 目录下的 Kubernetes 配置文件。

## 故障排查

### 常见问题

**1. 服务无法启动**

```bash
# 查看详细日志
docker-compose logs api

# 检查端口占用
netstat -tulpn | grep 8000

# 检查磁盘空间
df -h
```

**2. 数据库连接失败**

```bash
# 检查数据库是否就绪
docker-compose exec postgres pg_isready

# 测试连接
docker-compose exec api sh -c 'echo "SELECT 1" | psql $DATABASE_URL'

# 检查网络
docker network inspect dacong_dacong-network
```

**3. 构建失败**

```bash
# 清理构建缓存
docker builder prune -a

# 不使用缓存重新构建
docker-compose build --no-cache

# 检查 Docker 版本
docker --version
docker-compose --version
```

**4. 内存不足**

```bash
# 查看资源占用
docker stats

# 清理未使用的资源
docker system prune -a

# 增加 Docker 内存限制（Docker Desktop）
# Settings -> Resources -> Memory
```

### 健康检查

```bash
# 检查所有服务健康状态
docker-compose ps

# 手动测试健康检查
docker-compose exec api curl http://localhost:8000/health

# 查看健康检查日志
docker inspect --format='{{json .State.Health}}' dacong-api | jq
```

## 备份与恢复

### 数据备份

```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# 备份数据库
docker-compose exec -T postgres pg_dump -U postgres dacong > "$BACKUP_DIR/database.sql"

# 备份 Redis
docker-compose exec -T redis redis-cli --rdb "$BACKUP_DIR/redis.rdb"

# 备份配置文件
cp .env "$BACKUP_DIR/"
cp docker-compose.yml "$BACKUP_DIR/"

echo "Backup completed: $BACKUP_DIR"
```

### 数据恢复

```bash
#!/bin/bash
# restore.sh

BACKUP_DIR=$1

if [ -z "$BACKUP_DIR" ]; then
  echo "Usage: ./restore.sh <backup_directory>"
  exit 1
fi

# 停止服务
docker-compose down

# 恢复数据库
docker-compose up -d postgres
sleep 10
docker-compose exec -T postgres psql -U postgres dacong < "$BACKUP_DIR/database.sql"

# 恢复 Redis
docker-compose up -d redis
docker-compose cp "$BACKUP_DIR/redis.rdb" redis:/data/dump.rdb
docker-compose restart redis

# 启动所有服务
docker-compose up -d

echo "Restore completed"
```

## 性能基准

### 镜像大小对比

| 服务 | 未优化 | 优化后 | 减少 |
|------|--------|--------|------|
| API | 450MB | 150MB | 67% |
| Spider | 800MB | 200MB | 75% |
| Client | 2.1GB | 50MB | 98% |
| Admin | 2.1GB | 50MB | 98% |

### 构建时间

| 服务 | 首次构建 | 缓存构建 |
|------|----------|----------|
| API | 2m 30s | 15s |
| Spider | 3m 45s | 20s |
| Client | 8m 20s | 30s |
| Admin | 8m 15s | 30s |

### 启动时间

| 服务 | 冷启动 | 热启动 |
|------|--------|--------|
| PostgreSQL | 5s | 2s |
| Redis | 2s | 1s |
| API | 8s | 3s |
| Spider | 10s | 4s |
| Client | 3s | 1s |
| Admin | 3s | 1s |

## 下一步

- [Kubernetes 部署](./KUBERNETES_DEPLOYMENT.md)
- [CI/CD 集成](./CICD_INTEGRATION.md)
- [监控告警](./MONITORING.md)
- [性能调优](./PERFORMANCE_TUNING.md)

## 参考资料

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [Dockerfile 最佳实践](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [多阶段构建](https://docs.docker.com/build/building/multi-stage/)
