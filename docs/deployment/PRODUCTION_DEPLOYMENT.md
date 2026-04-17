# 生产环境部署指南

## 概述

本文档提供完整的生产环境部署流程，确保 DaCong 应用可以安全、稳定地部署到生产环境。

## 架构概览

```
┌─────────────────┐
│   Cloudflare    │  CDN + DNS + DDoS 防护
└────────┬────────┘
         │
┌────────▼────────┐
│  Vercel/Nginx   │  前端静态资源托管
└────────┬────────┘
         │
┌────────▼────────┐
│  Supabase Cloud │  后端 API + 数据库 + 存储
│  - PostgreSQL   │
│  - Edge Funcs   │
│  - Storage      │
│  - Auth         │
└────────┬────────┘
         │
┌────────▼────────┐
│   VPS Server    │  爬虫 + 定时任务
│  - Python 3.11+ │
│  - Systemd      │
└─────────────────┘
```

## 部署流程

### 阶段 1: 前置准备（预计 2 小时）

#### 1.1 服务器准备

**需求清单**：
- VPS 服务器（推荐配置：2 核 4GB 内存，40GB SSD）
- 域名（如 `dacong.com`）
- SSL 证书（Let's Encrypt 免费）
- Supabase 账号
- Vercel 账号（可选，用于前端托管）

**推荐服务商**：
- VPS: DigitalOcean, Vultr, Linode
- 域名: Cloudflare, Namecheap, GoDaddy
- CDN: Cloudflare（免费）

#### 1.2 域名配置

1. 购买域名
2. 添加 DNS 记录到 Cloudflare：

```
类型    名称        内容                    TTL
A       @           your-vps-ip             Auto
A       www         your-vps-ip             Auto
CNAME   api         your-project.supabase.co Auto
CNAME   app         your-vercel-app.vercel.app Auto
```

3. 启用 Cloudflare 代理（橙色云朵图标）

#### 1.3 安全检查清单

- [ ] 服务器已更新到最新补丁
- [ ] 已配置防火墙（UFW/iptables）
- [ ] 已禁用 root SSH 登录
- [ ] 已配置 SSH 密钥认证
- [ ] 已安装 fail2ban
- [ ] 已配置自动安全更新

---

### 阶段 2: Supabase 部署（预计 1 小时）

详见 [SUPABASE_SETUP.md](./SUPABASE_SETUP.md)

**快速步骤**：

1. 创建 Supabase 项目
2. 运行数据库迁移
3. 配置 RLS 策略
4. 部署 Edge Functions
5. 配置 Storage
6. 配置 Auth

**验证**：
```bash
# 测试数据库连接
psql $DATABASE_URL -c "SELECT version();"

# 测试 API
curl https://your-project.supabase.co/rest/v1/
```

---

### 阶段 3: 数据库迁移（预计 30 分钟）

#### 3.1 安装 Supabase CLI

```bash
npm install -g supabase
supabase --version
```

#### 3.2 链接项目

```bash
cd dacong-api
supabase login
supabase link --project-ref your-project-ref
```

获取 `project-ref`：
- 访问 Supabase Dashboard
- Settings > General > Reference ID

#### 3.3 运行迁移

```bash
# 查看待执行的迁移
supabase db diff

# 执行所有迁移
supabase db push

# 验证迁移
supabase db remote list
```

#### 3.4 验证数据库结构

```sql
-- 连接到数据库
psql $DATABASE_URL

-- 检查表
\dt

-- 检查 RLS 策略
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public';

-- 检查索引
SELECT schemaname, tablename, indexname 
FROM pg_indexes 
WHERE schemaname = 'public';
```

---

### 阶段 4: Edge Functions 部署（预计 30 分钟）

#### 4.1 部署所有函数

```bash
cd dacong-api/supabase/functions

# 部署单个函数
supabase functions deploy rank-calc
supabase functions deploy moderation-trigger
supabase functions deploy push-trigger

# 或批量部署
for func in rank-calc moderation-trigger push-trigger; do
  supabase functions deploy $func
done
```

#### 4.2 配置环境变量

```bash
# 为 Edge Functions 设置环境变量
supabase secrets set OPENROUTER_API_KEY=sk-or-xxxxx
supabase secrets set GITHUB_TOKEN=ghp_xxxxx

# 查看已设置的密钥
supabase secrets list
```

#### 4.3 测试 Edge Functions

```bash
# 测试 rank-calc
curl -X POST \
  https://your-project.supabase.co/functions/v1/rank-calc \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"content_id": "test-id"}'

# 查看函数日志
supabase functions logs rank-calc
```

---

### 阶段 5: VPS 部署（爬虫服务）（预计 1 小时）

#### 5.1 服务器初始化

```bash
# SSH 登录
ssh root@your-vps-ip

# 更新系统
apt update && apt upgrade -y

# 安装必要软件
apt install -y python3 python3-pip python3-venv git curl ufw fail2ban

# 配置防火墙
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable

# 创建应用用户
useradd -m -s /bin/bash dacong
usermod -aG sudo dacong
```

#### 5.2 部署爬虫代码

```bash
# 切换到应用用户
su - dacong

# 克隆代码
git clone https://gitlab.com/your-org/dacong.git
cd dacong/dacong-spider

# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt

# 配置环境变量
cp .env.example .env
nano .env  # 填写实际配置
```

#### 5.3 配置 Systemd 服务

```bash
# 创建服务文件
sudo nano /etc/systemd/system/dacong-spider.service
```

内容：
```ini
[Unit]
Description=DaCong Spider Service
After=network.target

[Service]
Type=simple
User=dacong
Group=dacong
WorkingDirectory=/home/dacong/dacong/dacong-spider
Environment="PATH=/home/dacong/dacong/dacong-spider/venv/bin"
ExecStart=/home/dacong/dacong/dacong-spider/venv/bin/python -m schedulers.jobs
Restart=always
RestartSec=10
StandardOutput=append:/var/log/dacong-spider.log
StandardError=append:/var/log/dacong-spider-error.log

[Install]
WantedBy=multi-user.target
```

启动服务：
```bash
# 重载 systemd
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start dacong-spider

# 设置开机自启
sudo systemctl enable dacong-spider

# 查看状态
sudo systemctl status dacong-spider

# 查看日志
sudo journalctl -u dacong-spider -f
```

---

### 阶段 6: 前端部署（预计 30 分钟）

#### 选项 A: Vercel 部署（推荐）

1. 安装 Vercel CLI：
```bash
npm install -g vercel
```

2. 部署：
```bash
cd dacong-client
vercel --prod
```

3. 配置环境变量（Vercel Dashboard）：
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJxxx...
```

#### 选项 B: 自托管（Nginx）

1. 构建前端：
```bash
cd dacong-client
flutter build web --release
```

2. 配置 Nginx：
```nginx
server {
    listen 80;
    server_name app.dacong.com;
    
    root /var/www/dacong/build/web;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # 启用 gzip 压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
```

3. 启用 HTTPS（Let's Encrypt）：
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d app.dacong.com
```

---

### 阶段 7: 环境变量配置（预计 15 分钟）

#### 7.1 Supabase 环境变量

在 Supabase Dashboard > Settings > API 获取：
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

#### 7.2 VPS 环境变量

编辑 `/home/dacong/dacong/dacong-spider/.env`：
```env
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJxxx...

# OpenRouter
OPENROUTER_API_KEY=sk-or-xxxxx

# GitHub
GITHUB_TOKEN=ghp_xxxxx

# 日志
LOG_LEVEL=info
LOG_FORMAT=json

# 环境
NODE_ENV=production
```

#### 7.3 前端环境变量

Vercel 或 `.env.production`：
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJxxx...
```

---

### 阶段 8: 健康检查（预计 15 分钟）

#### 8.1 数据库健康检查

```bash
# 连接测试
psql $DATABASE_URL -c "SELECT 1;"

# 检查表数量
psql $DATABASE_URL -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';"

# 检查 RLS 策略
psql $DATABASE_URL -c "SELECT count(*) FROM pg_policies WHERE schemaname = 'public';"
```

#### 8.2 API 健康检查

```bash
# 测试 Supabase API
curl https://your-project.supabase.co/rest/v1/ \
  -H "apikey: $SUPABASE_ANON_KEY"

# 测试 Edge Functions
curl https://your-project.supabase.co/functions/v1/rank-calc \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY"
```

#### 8.3 爬虫服务健康检查

```bash
# 检查服务状态
sudo systemctl status dacong-spider

# 检查日志
sudo journalctl -u dacong-spider --since "10 minutes ago"

# 检查进程
ps aux | grep python
```

#### 8.4 前端健康检查

```bash
# 测试前端访问
curl -I https://app.dacong.com

# 检查 SSL 证书
openssl s_client -connect app.dacong.com:443 -servername app.dacong.com < /dev/null 2>/dev/null | openssl x509 -noout -dates
```

---

### 阶段 9: 性能优化（预计 30 分钟）

#### 9.1 数据库优化

```sql
-- 创建必要的索引
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_raw_data_created_at ON raw_data(created_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_published_content_status ON published_content(status);

-- 启用查询统计
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- 分析表
ANALYZE raw_data;
ANALYZE generated_content;
ANALYZE published_content;
```

#### 9.2 CDN 配置

在 Cloudflare Dashboard：
1. 启用 Auto Minify（HTML, CSS, JS）
2. 启用 Brotli 压缩
3. 设置缓存规则：
   - 静态资源：缓存 1 年
   - API 响应：不缓存
4. 启用 HTTP/3

#### 9.3 前端优化

```bash
# 启用 Service Worker
# 配置资源预加载
# 启用代码分割
# 压缩图片资源
```

---

### 阶段 10: 监控配置（预计 30 分钟）

详见 [MONITORING_SETUP.md](./MONITORING_SETUP.md)

**快速配置**：

1. Sentry 错误监控
2. Supabase 性能监控
3. 服务器监控（Netdata/Prometheus）
4. 日志聚合（Loki/ELK）

---

## 部署后验证清单

### 功能验证

- [ ] 用户可以注册/登录
- [ ] 可以浏览内容列表
- [ ] 可以查看内容详情
- [ ] 可以点赞/收藏
- [ ] 可以发表评论
- [ ] 爬虫正常运行
- [ ] AI 生成内容正常
- [ ] 推送通知正常

### 性能验证

- [ ] 首页加载时间 < 2 秒
- [ ] API 响应时间 < 500ms
- [ ] 数据库查询 < 100ms
- [ ] 静态资源通过 CDN 加载
- [ ] 启用 gzip/brotli 压缩
- [ ] 图片懒加载正常

### 安全验证

- [ ] HTTPS 强制跳转
- [ ] SSL 证书有效
- [ ] RLS 策略生效
- [ ] API 密钥未泄露
- [ ] CORS 配置正确
- [ ] 防火墙规则正确
- [ ] 敏感数据已加密

### 监控验证

- [ ] Sentry 接收错误报告
- [ ] 日志正常写入
- [ ] 告警规则配置
- [ ] 性能指标收集
- [ ] 备份任务运行

---

## 回滚计划

### 数据库回滚

```bash
# 查看迁移历史
supabase db remote list

# 回滚到指定版本
supabase db reset --version 20260417000001
```

### 代码回滚

```bash
# VPS 回滚
cd /home/dacong/dacong
git checkout <previous-commit>
sudo systemctl restart dacong-spider

# Vercel 回滚
vercel rollback
```

---

## 常见问题

详见 [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

### 数据库连接失败

**症状**：无法连接到 Supabase 数据库

**解决方案**：
1. 检查 `DATABASE_URL` 是否正确
2. 检查 IP 白名单（Supabase 免费版无限制）
3. 检查网络连接
4. 检查 Supabase 服务状态

### Edge Functions 超时

**症状**：Edge Functions 执行超过 10 秒超时

**解决方案**：
1. 优化函数代码
2. 使用异步处理
3. 拆分为多个小函数
4. 考虑使用 VPS 处理长时间任务

### 爬虫服务崩溃

**症状**：爬虫服务频繁重启

**解决方案**：
1. 查看日志：`journalctl -u dacong-spider -n 100`
2. 检查内存使用：`free -h`
3. 检查磁盘空间：`df -h`
4. 增加重启延迟：`RestartSec=30`

---

## 成本估算

| 服务 | 配置 | 月费用 |
|------|------|--------|
| Supabase | Free Plan | $0 |
| VPS | 2核4GB | $15 |
| Cloudflare | Free Plan | $0 |
| Vercel | Hobby Plan | $0 |
| 域名 | .com | $12/年 |
| **总计** | | **~$15/月** |

升级到付费版：
- Supabase Pro: $25/月（更多资源）
- VPS 升级: $30/月（4核8GB）
- Cloudflare Pro: $20/月（高级 DDoS 防护）

---

## 下一步

1. 配置监控告警：[MONITORING_SETUP.md](./MONITORING_SETUP.md)
2. 设置备份策略：[BACKUP_RECOVERY.md](./BACKUP_RECOVERY.md)
3. 完成部署检查清单：[DEPLOYMENT_CHECKLIST_PRODUCTION.md](./DEPLOYMENT_CHECKLIST_PRODUCTION.md)
4. 阅读故障排查指南：[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

---

## 支持

遇到问题？
- 查看文档：`docs/deployment/`
- 查看日志：`journalctl -u dacong-spider -f`
- 联系团队：support@dacong.com
