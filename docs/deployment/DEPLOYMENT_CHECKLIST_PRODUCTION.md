# 生产环境部署检查清单

## 概述

本检查清单确保生产环境部署的完整性和安全性。请在部署前、部署中和部署后逐项检查。

---

## 部署前检查（Pre-Deployment）

### 1. 代码准备（20 项）

#### 代码质量
- [ ] 所有代码已通过 Code Review
- [ ] 所有测试用例通过（单元测试、集成测试）
- [ ] 测试覆盖率 ≥ 80%
- [ ] 无已知的 Critical/High 级别 Bug
- [ ] 代码已合并到 main/master 分支
- [ ] Git 标签已创建（如 v1.0.0）

#### 依赖管理
- [ ] 所有依赖包版本已锁定
- [ ] 无已知的安全漏洞（运行 `npm audit` / `pip check`）
- [ ] 第三方服务 API 密钥已准备
- [ ] 依赖包镜像源配置正确

#### 配置文件
- [ ] 生产环境配置文件已准备（`.env.production`）
- [ ] 所有必需的环境变量已配置
- [ ] 敏感信息未提交到代码仓库
- [ ] 数据库连接字符串正确
- [ ] API 端点 URL 正确
- [ ] 日志级别设置为 `info` 或 `warn`

#### 文档
- [ ] 部署文档已更新
- [ ] API 文档已更新
- [ ] 变更日志（CHANGELOG）已更新
- [ ] 回滚计划已准备

---

### 2. 基础设施准备（15 项）

#### 服务器
- [ ] VPS 服务器已购买并初始化
- [ ] 服务器操作系统已更新到最新版本
- [ ] 必要的软件包已安装（Python, Node.js, PostgreSQL Client）
- [ ] 服务器时区设置正确（UTC 或本地时区）
- [ ] NTP 时间同步已启用

#### 网络
- [ ] 域名已购买
- [ ] DNS 记录已配置
- [ ] SSL 证书已准备（Let's Encrypt 或购买）
- [ ] 防火墙规则已配置
- [ ] CDN 已配置（Cloudflare）

#### 数据库
- [ ] Supabase 项目已创建
- [ ] 数据库密码已设置（强密码）
- [ ] 数据库备份已启用
- [ ] 连接池配置已优化
- [ ] RLS 策略已配置

---

### 3. 安全检查（25 项）

#### 认证和授权
- [ ] 用户认证机制已实现
- [ ] 密码策略已配置（最小长度、复杂度）
- [ ] JWT 过期时间已设置
- [ ] Refresh Token 机制已实现
- [ ] 多因素认证（2FA）已考虑（可选）

#### 数据安全
- [ ] 所有敏感数据已加密存储
- [ ] 数据库连接使用 SSL/TLS
- [ ] API 密钥未硬编码在代码中
- [ ] 环境变量文件权限正确（600）
- [ ] 备份文件已加密

#### 网络安全
- [ ] HTTPS 强制跳转已启用
- [ ] HSTS 头已配置
- [ ] CORS 策略已正确配置
- [ ] CSP（内容安全策略）已配置
- [ ] 防火墙规则已配置（仅开放必要端口）

#### 应用安全
- [ ] SQL 注入防护已实现（使用参数化查询）
- [ ] XSS 防护已实现（输入验证、输出转义）
- [ ] CSRF 防护已实现
- [ ] 文件上传限制已配置（类型、大小）
- [ ] API 限流已配置
- [ ] 错误信息不泄露敏感数据

#### 访问控制
- [ ] SSH 密钥认证已启用
- [ ] Root 登录已禁用
- [ ] Sudo 权限已正确配置
- [ ] 数据库用户权限最小化
- [ ] API 访问权限已配置

---

### 4. 监控和日志（10 项）

#### 监控
- [ ] Sentry 错误监控已配置
- [ ] 服务器监控已配置（Netdata/Prometheus）
- [ ] 数据库性能监控已启用
- [ ] API 性能监控已配置
- [ ] 告警规则已配置

#### 日志
- [ ] 应用日志已配置
- [ ] 日志级别正确（生产环境使用 info/warn）
- [ ] 日志轮转已配置
- [ ] 日志聚合已配置（可选）
- [ ] 敏感信息不记录到日志

---

### 5. 备份策略（8 项）

- [ ] 数据库自动备份已启用
- [ ] 备份保留策略已配置
- [ ] 备份验证脚本已准备
- [ ] 异地备份已配置
- [ ] 恢复流程已测试
- [ ] 备份监控告警已配置
- [ ] 配置文件备份已准备
- [ ] 代码仓库备份已配置

---

## 部署中检查（During Deployment）

### 6. 数据库部署（10 项）

- [ ] 数据库迁移脚本已准备
- [ ] 迁移前数据库快照已创建
- [ ] 数据库迁移已执行
- [ ] 迁移结果已验证
- [ ] 表结构正确
- [ ] 索引已创建
- [ ] RLS 策略已生效
- [ ] 触发器已创建
- [ ] 视图已创建
- [ ] 种子数据已导入

**执行命令**：
```bash
# 创建快照
pg_dump $DATABASE_URL > pre_migration_$(date +%Y%m%d).sql

# 执行迁移
supabase db push

# 验证
psql $DATABASE_URL -c "\dt"
psql $DATABASE_URL -c "SELECT count(*) FROM published_content;"
```

---

### 7. 后端部署（12 项）

#### Edge Functions
- [ ] Edge Functions 代码已部署
- [ ] 环境变量已配置
- [ ] 函数测试通过
- [ ] 函数日志正常

**执行命令**：
```bash
# 部署 Edge Functions
supabase functions deploy rank-calc
supabase functions deploy moderation-trigger
supabase functions deploy push-trigger

# 配置环境变量
supabase secrets set OPENROUTER_API_KEY=xxx
supabase secrets set GITHUB_TOKEN=xxx

# 测试
curl -X POST https://xxx.supabase.co/functions/v1/rank-calc \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY"
```

#### 爬虫服务
- [ ] 代码已部署到 VPS
- [ ] Python 虚拟环境已创建
- [ ] 依赖包已安装
- [ ] 环境变量已配置
- [ ] Systemd 服务已配置
- [ ] 服务已启动
- [ ] 服务状态正常
- [ ] 日志输出正常

**执行命令**：
```bash
# 部署代码
cd /home/dacong
git clone https://gitlab.com/your-org/dacong.git
cd dacong/dacong-spider

# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 配置服务
sudo systemctl enable dacong-spider
sudo systemctl start dacong-spider
sudo systemctl status dacong-spider
```

---

### 8. 前端部署（8 项）

- [ ] 前端代码已构建
- [ ] 构建产物已验证
- [ ] 环境变量已配置
- [ ] 静态资源已上传
- [ ] CDN 缓存已配置
- [ ] 域名已绑定
- [ ] HTTPS 已启用
- [ ] 页面可访问

**执行命令**：
```bash
# Vercel 部署
cd dacong-client
vercel --prod

# 或自托管
flutter build web --release
scp -r build/web/* user@server:/var/www/dacong/
```

---

### 9. 配置验证（10 项）

- [ ] DNS 解析正确
- [ ] SSL 证书有效
- [ ] 环境变量加载正确
- [ ] 数据库连接成功
- [ ] API 端点可访问
- [ ] 认证流程正常
- [ ] 文件上传功能正常
- [ ] 邮件发送功能正常（如有）
- [ ] 推送通知功能正常（如有）
- [ ] 第三方服务集成正常

**验证命令**：
```bash
# DNS
dig dacong.com

# SSL
openssl s_client -connect dacong.com:443 < /dev/null

# 数据库
psql $DATABASE_URL -c "SELECT 1;"

# API
curl https://api.dacong.com/health
```

---

## 部署后验证（Post-Deployment）

### 10. 功能验证（20 项）

#### 用户功能
- [ ] 用户注册功能正常
- [ ] 用户登录功能正常
- [ ] 密码重置功能正常
- [ ] 个人资料编辑功能正常
- [ ] 头像上传功能正常

#### 内容功能
- [ ] 内容列表加载正常
- [ ] 内容详情显示正常
- [ ] 内容搜索功能正常
- [ ] 内容分类筛选正常
- [ ] 内容排序功能正常

#### 交互功能
- [ ] 点赞功能正常
- [ ] 收藏功能正常
- [ ] 评论功能正常
- [ ] 分享功能正常
- [ ] 举报功能正常

#### 后台功能
- [ ] 爬虫正常运行
- [ ] 内容审核正常
- [ ] 推送通知正常
- [ ] 数据统计正常
- [ ] 管理后台可访问

---

### 11. 性能验证（15 项）

#### 响应时间
- [ ] 首页加载时间 < 2 秒
- [ ] API 响应时间 < 500ms
- [ ] 数据库查询时间 < 100ms
- [ ] 图片加载时间 < 1 秒
- [ ] 搜索响应时间 < 1 秒

#### 资源使用
- [ ] 服务器 CPU 使用率 < 50%
- [ ] 服务器内存使用率 < 70%
- [ ] 磁盘使用率 < 70%
- [ ] 数据库连接数 < 50%
- [ ] 网络带宽使用正常

#### 优化验证
- [ ] CDN 缓存命中率 > 80%
- [ ] gzip/Brotli 压缩已启用
- [ ] 图片懒加载正常
- [ ] 代码分割正常
- [ ] Service Worker 正常（如有）

**性能测试**：
```bash
# 使用 Apache Bench 测试
ab -n 1000 -c 10 https://api.dacong.com/v1/content

# 使用 Lighthouse 测试
lighthouse https://app.dacong.com --view

# 查看服务器资源
top
free -h
df -h
```

---

### 12. 安全验证（15 项）

#### SSL/TLS
- [ ] HTTPS 强制跳转生效
- [ ] SSL 证书有效且未过期
- [ ] SSL Labs 评分 A 或 A+
- [ ] TLS 1.2+ 已启用
- [ ] 弱加密套件已禁用

#### 安全头
- [ ] HSTS 头已配置
- [ ] X-Frame-Options 已配置
- [ ] X-Content-Type-Options 已配置
- [ ] X-XSS-Protection 已配置
- [ ] CSP 头已配置

#### 访问控制
- [ ] RLS 策略生效
- [ ] API 认证正常
- [ ] 权限控制正常
- [ ] 敏感端点受保护
- [ ] 文件上传限制生效

**安全测试**：
```bash
# SSL 测试
https://www.ssllabs.com/ssltest/analyze.html?d=dacong.com

# 安全头测试
curl -I https://dacong.com | grep -i "strict-transport-security\|x-frame-options\|x-content-type-options"

# RLS 测试
psql $DATABASE_URL -c "SET ROLE anon; SELECT * FROM published_content;"
```

---

### 13. 监控验证（10 项）

- [ ] Sentry 接收错误报告
- [ ] 服务器监控数据正常
- [ ] 数据库监控数据正常
- [ ] API 监控数据正常
- [ ] 日志正常写入
- [ ] 告警规则已测试
- [ ] 告警通知正常（Email/Slack/Telegram）
- [ ] 监控仪表板可访问
- [ ] 性能指标正常
- [ ] 错误率 < 1%

**验证命令**：
```bash
# 发送测试错误到 Sentry
curl -X POST https://sentry.io/api/xxx/store/ \
  -H "X-Sentry-Auth: Sentry sentry_key=xxx" \
  -d '{"message": "Test error"}'

# 发送测试告警
/usr/local/bin/telegram-alert.sh "Test alert"

# 查看监控数据
curl http://localhost:19999/api/v1/data
```

---

### 14. 备份验证（8 项）

- [ ] 自动备份任务正常运行
- [ ] 最新备份在 24 小时内
- [ ] 备份文件完整性验证通过
- [ ] 备份文件大小正常
- [ ] 异地备份已上传
- [ ] 恢复流程已测试
- [ ] 备份监控告警正常
- [ ] 备份文档已更新

**验证命令**：
```bash
# 检查最新备份
ls -lh /home/dacong/backups/database/ | tail -5

# 验证备份
/home/dacong/scripts/verify-backup.sh $(ls -t /home/dacong/backups/database/*.sql.gz | head -1)

# 测试恢复
/home/dacong/scripts/disaster-recovery-drill.sh
```

---

### 15. 文档验证（5 项）

- [ ] 部署文档已更新
- [ ] API 文档已更新
- [ ] 运维手册已更新
- [ ] 故障排查指南已更新
- [ ] 变更日志已更新

---

### 16. 用户验证（5 项）

- [ ] 内部测试用户验证通过
- [ ] Beta 用户反馈收集
- [ ] 关键用户流程测试通过
- [ ] 用户体验满意度 > 80%
- [ ] 无阻塞性问题

---

### 17. 业务验证（5 项）

- [ ] 核心业务指标正常
- [ ] 数据统计准确
- [ ] 收入相关功能正常（如有）
- [ ] 第三方集成正常
- [ ] 业务流程完整

---

## 部署后任务

### 18. 通知和沟通（5 项）

- [ ] 团队成员已通知
- [ ] 用户已通知（如需要）
- [ ] 部署报告已发送
- [ ] 变更日志已发布
- [ ] 文档已更新

---

### 19. 监控和观察（5 项）

- [ ] 持续监控 24 小时
- [ ] 错误率监控
- [ ] 性能指标监控
- [ ] 用户反馈收集
- [ ] 准备回滚计划

---

### 20. 清理工作（5 项）

- [ ] 临时文件已清理
- [ ] 测试数据已清理
- [ ] 旧版本代码已归档
- [ ] 部署脚本已更新
- [ ] 经验教训已记录

---

## 回滚检查清单

### 回滚准备

- [ ] 回滚计划已准备
- [ ] 回滚脚本已测试
- [ ] 数据库回滚脚本已准备
- [ ] 备份已验证
- [ ] 团队成员已通知

### 回滚执行

- [ ] 停止新流量
- [ ] 回滚数据库（如需要）
- [ ] 回滚应用代码
- [ ] 验证回滚结果
- [ ] 恢复流量

### 回滚后验证

- [ ] 功能正常
- [ ] 性能正常
- [ ] 无数据丢失
- [ ] 用户反馈正常
- [ ] 问题已记录

---

## 检查清单总结

### 统计

- **部署前检查**：78 项
- **部署中检查**：40 项
- **部署后验证**：88 项
- **总计**：206 项

### 优先级

**P0（必须）**：
- 所有安全检查
- 数据库迁移验证
- 核心功能验证
- 备份验证

**P1（重要）**：
- 性能验证
- 监控验证
- 文档更新

**P2（建议）**：
- 优化验证
- 用户体验验证

---

## 使用说明

### 如何使用本检查清单

1. **打印或复制**：打印本检查清单或复制到项目管理工具
2. **分配责任**：为每个检查项分配负责人
3. **逐项检查**：按顺序完成每个检查项
4. **记录问题**：发现问题立即记录并解决
5. **最终确认**：所有检查项完成后才能上线

### 检查清单模板

```markdown
## 部署检查记录

**部署日期**：2024-04-17
**部署版本**：v1.0.0
**负责人**：张三
**检查人**：李四

### 部署前检查
- [x] 代码质量检查 - 张三 - 2024-04-17 10:00
- [x] 安全检查 - 李四 - 2024-04-17 11:00
- [ ] ...

### 部署中检查
- [x] 数据库迁移 - 张三 - 2024-04-17 14:00
- [ ] ...

### 部署后验证
- [x] 功能验证 - 李四 - 2024-04-17 16:00
- [ ] ...

### 问题记录
1. 数据库迁移时发现索引缺失 - 已修复
2. API 响应时间略高 - 已优化

### 最终确认
- [x] 所有检查项已完成
- [x] 所有问题已解决
- [x] 部署成功

**签字**：张三、李四
**日期**：2024-04-17 18:00
```

---

## 相关文档

- [生产环境部署指南](./PRODUCTION_DEPLOYMENT.md)
- [Supabase 配置指南](./SUPABASE_SETUP.md)
- [域名和 SSL 配置](./DOMAIN_SSL_SETUP.md)
- [监控配置指南](./MONITORING_SETUP.md)
- [备份和恢复指南](./BACKUP_RECOVERY.md)
- [故障排查指南](./TROUBLESHOOTING.md)
