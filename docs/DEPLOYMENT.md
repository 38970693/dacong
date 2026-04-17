# 部署文档

## 概述

本文档描述如何将大聪系统部署到测试环境和生产环境。

## 目录

- [部署前检查](#部署前检查)
- [环境配置](#环境配置)
- [部署步骤](#部署步骤)
- [验证部署](#验证部署)
- [回滚方案](#回滚方案)
- [故障排查](#故障排查)
- [监控和日志](#监控和日志)

## 部署前检查

### 必备工具

确保已安装以下工具：

```bash
# Supabase CLI
npm install -g supabase

# Flutter
flutter --version

# Deno (用于 Edge Functions)
deno --version

# Git
git --version
```

### 环境变量检查清单

- [ ] Supabase 项目已创建
- [ ] 获取了 `SUPABASE_URL`
- [ ] 获取了 `SUPABASE_ANON_KEY`
- [ ] 获取了 `SUPABASE_SERVICE_ROLE_KEY`
- [ ] 获取了 `DATABASE_URL`
- [ ] 配置了 `ANTHROPIC_API_KEY`（如需 AI 功能）
- [ ] 配置了前端部署 URL

### 代码检查清单

- [ ] 所有测试通过
- [ ] 代码已合并到目标分支
- [ ] 数据库迁移文件已准备
- [ ] 环境配置文件已更新
- [ ] 依赖包版本已锁定

## 环境配置

### 测试环境

1. 复制环境配置模板：

```bash
cp .env.test .env.test.local
```

2. 编辑 `.env.test.local`，填写实际值：

```bash
# Supabase 配置
SUPABASE_URL=https://your-test-project.supabase.co
SUPABASE_ANON_KEY=your-test-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-test-service-role-key
DATABASE_URL=postgresql://postgres:password@db.your-test-project.supabase.co:5432/postgres

# API 配置
ANTHROPIC_API_KEY=sk-ant-your-test-key

# 前端配置
FLUTTER_WEB_URL=http://localhost:8080
```

3. 验证配置：

```bash
# 检查环境变量
source .env.test.local
echo $SUPABASE_URL
```

### 生产环境

生产环境配置类似，但需要：

- 使用生产 Supabase 项目
- 使用生产 API 密钥
- 配置 CDN 和域名
- 启用 HTTPS
- 配置监控和告警

## 部署步骤

### 一键部署（推荐）

```bash
# 部署到测试环境
./scripts/deploy_test.sh
```

这个脚本会自动执行：

1. 环境检查
2. 数据库部署
3. API 部署
4. 前端构建
5. 健康检查
6. 冒烟测试
7. 生成部署报告

### 分步部署

如果需要单独部署某个组件：

#### 1. 部署数据库

```bash
./scripts/deploy_database.sh
```

这会：
- 运行所有数据库迁移
- 验证表结构
- 可选：初始化测试数据

#### 2. 部署 API (Edge Functions)

```bash
./scripts/deploy_api.sh
```

这会：
- 部署所有 Edge Functions
- 设置环境变量
- 验证部署状态

#### 3. 构建前端

```bash
./scripts/build_frontend.sh
```

这会：
- 清理旧构建
- 获取依赖
- 构建 Flutter Web
- 生成构建清单

#### 4. 验证部署

```bash
./scripts/verify_deployment.sh
```

这会：
- 测试数据库连接
- 测试所有 API 端点
- 验证前端构建
- 运行性能测试
- 生成验证报告

## 验证部署

### 手动验证

#### 1. 数据库验证

```bash
# 连接数据库
psql $DATABASE_URL

# 检查表
\dt

# 检查数据
SELECT COUNT(*) FROM published_content;
```

#### 2. API 验证

```bash
# 测试推荐接口
curl "$SUPABASE_URL/functions/v1/get-recommendations" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test-user","scenario":"morning","limit":5}'

# 测试搜索接口
curl "$SUPABASE_URL/functions/v1/search-content" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"技术","limit":10}'
```

#### 3. 前端验证

```bash
# 启动本地服务器
cd dacong-client/build/web
python3 -m http.server 8080

# 访问 http://localhost:8080
```

### 自动化测试

#### API 冒烟测试

```bash
./tests/smoke/test_api_smoke.sh
```

#### 前端冒烟测试

```bash
./tests/smoke/test_frontend_smoke.sh
```

#### 端到端测试

```bash
./tests/smoke/test_e2e_smoke.sh
```

## 回滚方案

### 快速回滚

如果部署出现问题，可以快速回滚：

```bash
# 1. 切换到上一个稳定版本
git checkout <previous-stable-commit>

# 2. 重新部署
./scripts/deploy_test.sh

# 3. 验证回滚
./scripts/verify_deployment.sh
```

### 数据库回滚

如果需要回滚数据库：

```bash
# 1. 查看迁移历史
supabase migration list

# 2. 回滚到指定版本
supabase db reset

# 3. 重新应用到目标版本
supabase db push
```

**警告**：数据库回滚可能导致数据丢失，请谨慎操作。

### API 回滚

```bash
# 重新部署上一个版本的 Functions
cd dacong-api/supabase/functions
git checkout <previous-commit> -- .
supabase functions deploy <function-name>
```

### 前端回滚

```bash
# 重新构建上一个版本
git checkout <previous-commit> -- dacong-client/
./scripts/build_frontend.sh
```

## 故障排查

### 常见问题

#### 1. 数据库连接失败

**症状**：
```
Error: Connection refused
```

**解决方案**：
- 检查 `DATABASE_URL` 是否正确
- 检查 Supabase 项目是否暂停
- 检查网络连接
- 验证数据库密码

#### 2. API 部署失败

**症状**：
```
Error: Function deployment failed
```

**解决方案**：
- 检查 Deno 版本是否兼容
- 检查函数代码是否有语法错误
- 检查环境变量是否设置
- 查看部署日志：`supabase functions logs <function-name>`

#### 3. 前端构建失败

**症状**：
```
Error: Build failed
```

**解决方案**：
- 运行 `flutter clean`
- 检查 Flutter 版本
- 检查依赖包版本
- 查看详细错误日志

#### 4. API 响应慢

**症状**：
- API 响应时间 > 3 秒

**解决方案**：
- 检查数据库索引
- 优化查询语句
- 增加缓存
- 检查 Edge Function 冷启动

#### 5. 前端加载慢

**症状**：
- 首屏加载时间 > 5 秒

**解决方案**：
- 启用 gzip 压缩
- 配置 CDN
- 优化资源大小
- 使用代码分割

### 日志查看

#### API 日志

```bash
# 查看所有 Functions 日志
supabase functions logs

# 查看特定 Function 日志
supabase functions logs get-recommendations

# 实时日志
supabase functions logs --tail
```

#### 数据库日志

```bash
# 在 Supabase Dashboard 查看
# Settings > Database > Logs
```

#### 前端日志

```bash
# 浏览器控制台
# F12 > Console
```

## 监控和日志

### 健康检查

设置定期健康检查：

```bash
# 每 5 分钟检查一次
*/5 * * * * curl -f $SUPABASE_URL/rest/v1/ -H "apikey: $SUPABASE_ANON_KEY" || echo "Health check failed"
```

### 性能监控

监控关键指标：

- API 响应时间
- 数据库查询时间
- 前端加载时间
- 错误率
- 并发用户数

### 告警配置

配置告警规则：

- API 响应时间 > 3 秒
- 错误率 > 1%
- 数据库连接失败
- 磁盘空间 < 10%

### 日志聚合

建议使用日志聚合服务：

- Supabase Logs
- Sentry (错误追踪)
- LogRocket (前端监控)
- Datadog (全栈监控)

## 部署清单

### 部署前

- [ ] 代码审查通过
- [ ] 所有测试通过
- [ ] 环境变量已配置
- [ ] 数据库备份已完成
- [ ] 部署计划已审批

### 部署中

- [ ] 数据库迁移成功
- [ ] API 部署成功
- [ ] 前端构建成功
- [ ] 健康检查通过
- [ ] 冒烟测试通过

### 部署后

- [ ] 验证核心功能
- [ ] 检查监控指标
- [ ] 通知相关人员
- [ ] 更新部署文档
- [ ] 归档部署报告

## 最佳实践

### 1. 蓝绿部署

- 保持两套环境（蓝/绿）
- 新版本部署到绿环境
- 验证通过后切换流量
- 保留蓝环境用于快速回滚

### 2. 金丝雀发布

- 先发布到 5% 用户
- 监控关键指标
- 逐步扩大到 100%
- 发现问题立即回滚

### 3. 数据库迁移

- 使用版本化迁移文件
- 先在测试环境验证
- 支持向前和向后迁移
- 大规模迁移分批执行

### 4. 零停机部署

- 使用滚动更新
- 保持 API 向后兼容
- 数据库迁移向后兼容
- 使用特性开关

### 5. 自动化

- 所有部署步骤自动化
- 使用 CI/CD 流水线
- 自动运行测试
- 自动生成部署报告

## 相关文档

- [API 文档](../dacong-api/docs/API.md)
- [数据库 Schema](../dacong-api/docs/DATABASE.md)
- [前端架构](../dacong-client/ARCHITECTURE.md)
- [测试指南](../dacong-api/docs/TESTING.md)

## 联系方式

如有问题，请联系：

- 技术负责人：dev@dacong.app
- 运维团队：ops@dacong.app
- 紧急联系：emergency@dacong.app
