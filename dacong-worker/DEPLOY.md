# Worker 部署到 Railway

## 1. 创建 Railway 项目

1. 打开 [Railway](https://railway.app/dashboard)
2. 点击 "New Project" → "Deploy from GitHub repo"
3. 选择 `38970693/dacong` 仓库
4. 选择 `dacong-worker` 文件夹作为根目录

## 2. 配置环境变量

在 Railway 项目 Settings → Variables 中添加：

```
SUPABASE_URL=https://prszkdbdgffbdqclbgol.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByc3prZGJkZ2ZmYmRxY2xiZ29sIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NzY3NTIwOSwiZXhwIjoyMDkzMjUxMjA5fQ.29r5X7qDCLmzO2ALBZw_54UD5NLo4akWe2HY3OFStp0

# 可选：AI 审核
ALIYUN_ACCESS_KEY=your-access-key
ALIYUN_ACCESS_SECRET=your-access-secret

# 调试
LOG_LEVEL=info
```

## 3. 配置启动命令

Railway 会自动检测 Node.js 项目。确保 `package.json` 的 start 脚本正确：

```json
{
  "scripts": {
    "start": "tsx src/index.ts"
  }
}
```

`tsx` 已在 `devDependencies` 中，Railway 会自动安装。

## 4. 部署

1. Railway 会自动构建并部署
2. 构建日志可以在 Deployments 页面查看
3. 部署完成后，会得到一个 URL（如 `https://dacong-worker.up.railway.app`）

## 5. 验证

访问健康检查端点：
```
https://<your-railway-url>/health
```

应返回：
```json
{
  "status": "ok",
  "uptime": 12345,
  "nextCrawl": "2024-03-15T12:00:00Z"
}
```

## 6. 监控

- Railway 提供日志查看
- 可配置 UptimeRobot 监控健康检查端点
- 告警设置见 `.omc/grill-me-decisions.md`

---

## 常见问题

### Q: 找不到仓库？
确保 GitHub 已授权 Railway 访问你的仓库。

### Q: 构建失败？
检查 Railway 日志，常见原因：
- 环境变量未设置
- 依赖安装失败（检查 package-lock.json）

### Q: 如何查看日志？
Railway Dashboard → 项目 → Deployments → 查看日志