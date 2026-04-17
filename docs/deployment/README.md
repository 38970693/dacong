# 部署文档索引

## 概述

本目录包含 DaCong 项目的完整生产环境部署文档，涵盖从前期准备到部署后维护的全流程。

---

## 文档列表

### 1. [生产环境部署指南](./PRODUCTION_DEPLOYMENT.md)
**主文档** - 完整的部署流程和步骤

**内容**：
- 架构概览
- 10 个部署阶段详细说明
- 前置准备、Supabase 部署、数据库迁移
- Edge Functions、VPS、前端部署
- 环境变量配置、健康检查
- 性能优化、监控配置
- 部署后验证清单
- 回滚计划
- 成本估算

**适用场景**：首次部署或完整部署流程参考

---

### 2. [Supabase 配置指南](./SUPABASE_SETUP.md)
**核心配置** - Supabase 项目的详细配置

**内容**：
- 创建 Supabase 项目
- 数据库配置和迁移
- Row Level Security (RLS) 策略
- Storage 配置
- Authentication 配置
- Edge Functions 部署
- 数据库优化
- 监控和告警
- 备份和恢复
- 安全和性能检查清单

**适用场景**：配置 Supabase 后端服务

---

### 3. [域名和 SSL 配置指南](./DOMAIN_SSL_SETUP.md)
**网络配置** - 域名、DNS 和 SSL 证书配置

**内容**：
- 域名购买建议
- DNS 配置（Cloudflare）
- SSL 证书配置（Cloudflare / Let's Encrypt）
- HTTPS 强制跳转
- CDN 配置和优化
- 安全配置（防火墙、WAF）
- 性能优化（HTTP/2、HTTP/3）
- 监控和分析
- 备案流程（中国大陆）

**适用场景**：配置域名和 HTTPS 访问

---

### 4. [监控配置指南](./MONITORING_SETUP.md)
**运维监控** - 完整的监控和告警系统

**内容**：
- 监控架构
- Sentry 错误监控（前端 + 后端）
- Supabase 性能监控
- 服务器监控（Netdata / Prometheus + Grafana）
- 日志聚合（Loki + Promtail）
- 应用性能监控（APM）
- 告警配置（Email / Slack / Telegram）
- 监控仪表板
- 监控检查清单

**适用场景**：配置生产环境监控和告警

---

### 5. [备份和恢复指南](./BACKUP_RECOVERY.md)
**数据安全** - 备份策略和灾难恢复

**内容**：
- 备份策略（3-2-1 原则）
- 数据库备份（自动 + 手动）
- 文件备份（Storage、代码、配置）
- 异地备份（云存储）
- 数据恢复流程
- 灾难恢复计划
- 备份验证
- 备份监控
- 备份最佳实践
- 备份检查清单

**适用场景**：配置备份和准备灾难恢复

---

### 6. [故障排查指南](./TROUBLESHOOTING.md)
**问题诊断** - 常见问题的诊断和解决方案

**内容**：
- 故障排查流程
- 数据库问题（连接失败、查询慢、连接池耗尽）
- API 问题（响应慢、500 错误、CORS）
- 爬虫问题（服务停止、频繁失败、内存泄漏）
- 前端问题（加载慢、白屏、认证失败）
- 性能问题（CPU、内存、磁盘）
- 网络问题（DNS、SSL、CDN）
- 安全问题（攻击、数据泄露）
- 监控告警配置
- 常用命令速查

**适用场景**：生产环境问题诊断和修复

---

### 7. [部署检查清单](./DEPLOYMENT_CHECKLIST_PRODUCTION.md)
**质量保证** - 206 项部署检查清单

**内容**：
- **部署前检查**（78 项）
  - 代码准备（20 项）
  - 基础设施准备（15 项）
  - 安全检查（25 项）
  - 监控和日志（10 项）
  - 备份策略（8 项）

- **部署中检查**（40 项）
  - 数据库部署（10 项）
  - 后端部署（12 项）
  - 前端部署（8 项）
  - 配置验证（10 项）

- **部署后验证**（88 项）
  - 功能验证（20 项）
  - 性能验证（15 项）
  - 安全验证（15 项）
  - 监控验证（10 项）
  - 备份验证（8 项）
  - 文档验证（5 项）
  - 用户验证（5 项）
  - 业务验证（5 项）
  - 通知和沟通（5 项）

- **回滚检查清单**

**适用场景**：部署前后的完整检查

---

## 快速导航

### 按部署阶段

1. **准备阶段**
   - [生产环境部署指南 - 阶段 1](./PRODUCTION_DEPLOYMENT.md#阶段-1-前置准备预计-2-小时)
   - [域名和 SSL 配置](./DOMAIN_SSL_SETUP.md)
   - [部署检查清单 - 部署前](./DEPLOYMENT_CHECKLIST_PRODUCTION.md#部署前检查pre-deployment)

2. **部署阶段**
   - [Supabase 配置](./SUPABASE_SETUP.md)
   - [生产环境部署指南 - 阶段 2-8](./PRODUCTION_DEPLOYMENT.md#阶段-2-supabase-部署预计-1-小时)
   - [部署检查清单 - 部署中](./DEPLOYMENT_CHECKLIST_PRODUCTION.md#部署中检查during-deployment)

3. **验证阶段**
   - [生产环境部署指南 - 阶段 8-9](./PRODUCTION_DEPLOYMENT.md#阶段-8-健康检查预计-15-分钟)
   - [部署检查清单 - 部署后](./DEPLOYMENT_CHECKLIST_PRODUCTION.md#部署后验证post-deployment)

4. **运维阶段**
   - [监控配置](./MONITORING_SETUP.md)
   - [备份和恢复](./BACKUP_RECOVERY.md)
   - [故障排查](./TROUBLESHOOTING.md)

### 按问题类型

- **数据库问题** → [故障排查指南 - 数据库问题](./TROUBLESHOOTING.md#2-数据库问题)
- **API 问题** → [故障排查指南 - API 问题](./TROUBLESHOOTING.md#3-api-问题)
- **性能问题** → [故障排查指南 - 性能问题](./TROUBLESHOOTING.md#6-性能问题)
- **安全问题** → [故障排查指南 - 安全问题](./TROUBLESHOOTING.md#8-安全问题)
- **网络问题** → [故障排查指南 - 网络问题](./TROUBLESHOOTING.md#7-网络问题)

### 按任务类型

- **首次部署** → [生产环境部署指南](./PRODUCTION_DEPLOYMENT.md)
- **配置 Supabase** → [Supabase 配置指南](./SUPABASE_SETUP.md)
- **配置域名** → [域名和 SSL 配置](./DOMAIN_SSL_SETUP.md)
- **配置监控** → [监控配置指南](./MONITORING_SETUP.md)
- **配置备份** → [备份和恢复指南](./BACKUP_RECOVERY.md)
- **问题诊断** → [故障排查指南](./TROUBLESHOOTING.md)
- **部署检查** → [部署检查清单](./DEPLOYMENT_CHECKLIST_PRODUCTION.md)

---

## 推荐阅读顺序

### 首次部署

1. [生产环境部署指南](./PRODUCTION_DEPLOYMENT.md) - 了解整体流程
2. [部署检查清单](./DEPLOYMENT_CHECKLIST_PRODUCTION.md) - 准备检查清单
3. [Supabase 配置指南](./SUPABASE_SETUP.md) - 配置后端
4. [域名和 SSL 配置](./DOMAIN_SSL_SETUP.md) - 配置网络
5. [监控配置指南](./MONITORING_SETUP.md) - 配置监控
6. [备份和恢复指南](./BACKUP_RECOVERY.md) - 配置备份
7. [故障排查指南](./TROUBLESHOOTING.md) - 了解常见问题

### 日常运维

1. [监控配置指南](./MONITORING_SETUP.md) - 查看监控指标
2. [故障排查指南](./TROUBLESHOOTING.md) - 诊断问题
3. [备份和恢复指南](./BACKUP_RECOVERY.md) - 验证备份

### 问题处理

1. [故障排查指南](./TROUBLESHOOTING.md) - 定位问题
2. 相关配置指南 - 查看详细配置
3. [备份和恢复指南](./BACKUP_RECOVERY.md) - 必要时恢复数据

---

## 文档统计

| 文档 | 页数（估算） | 检查项 | 代码示例 |
|------|------------|--------|---------|
| 生产环境部署指南 | 25 | 40+ | 50+ |
| Supabase 配置指南 | 20 | 30+ | 40+ |
| 域名和 SSL 配置 | 18 | 25+ | 30+ |
| 监控配置指南 | 22 | 20+ | 45+ |
| 备份和恢复指南 | 20 | 35+ | 40+ |
| 故障排查指南 | 24 | 50+ | 60+ |
| 部署检查清单 | 15 | 206 | 20+ |
| **总计** | **144** | **406+** | **285+** |

---

## 维护说明

### 文档更新

- **频率**：每次重大部署后更新
- **责任人**：运维团队
- **审核**：技术负责人

### 版本控制

- 所有文档纳入 Git 版本控制
- 重大变更创建新版本标签
- 保留历史版本供参考

### 反馈渠道

- 发现问题或改进建议：提交 Issue
- 文档错误：提交 PR
- 紧急问题：联系运维团队

---

## 相关资源

### 外部文档

- [Supabase 官方文档](https://supabase.com/docs)
- [Cloudflare 文档](https://developers.cloudflare.com/)
- [PostgreSQL 文档](https://www.postgresql.org/docs/)
- [Flutter 部署指南](https://docs.flutter.dev/deployment)

### 工具和服务

- [Supabase Dashboard](https://app.supabase.com/)
- [Cloudflare Dashboard](https://dash.cloudflare.com/)
- [Sentry Dashboard](https://sentry.io/)
- [SSL Labs](https://www.ssllabs.com/ssltest/)

### 社区支持

- [Supabase Discord](https://discord.supabase.com/)
- [Supabase GitHub](https://github.com/supabase/supabase)

---

## 联系方式

- **技术支持**：tech@dacong.com
- **运维团队**：ops@dacong.com
- **紧急联系**：+86 138-xxxx-xxxx

---

**最后更新**：2024-04-17
**文档版本**：v1.0.0
**维护团队**：DaCong 运维团队
