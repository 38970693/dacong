# 安全文档索引

## 概述

本目录包含 DaCong 项目的安全相关文档，涵盖安全策略、依赖管理、应急响应等方面。

## 文档列表

### 核心文档

| 文档 | 描述 | 维护者 |
|------|------|--------|
| [SECURITY_POLICY.md](./SECURITY_POLICY.md) | 安全策略和标准 | 安全工程团队 |
| [DEPENDENCY_SCANNING.md](./DEPENDENCY_SCANNING.md) | 依赖漏洞扫描流程 | 安全工程团队 |
| [INCIDENT_RESPONSE.md](./INCIDENT_RESPONSE.md) | 安全应急响应流程 | 安全工程团队 |

### 快速链接

#### 日常操作

- **扫描依赖漏洞**: `./scripts/security_scan.sh`
- **修复依赖漏洞**: `./scripts/fix_vulnerabilities.sh`
- **查看扫描报告**: `ls -lh security-reports/`

#### 应急响应

- **报告安全事件**: security@dacong.ai
- **紧急联系电话**: [紧急联系电话]
- **事件报告模板**: [INCIDENT_RESPONSE.md](./INCIDENT_RESPONSE.md#事件报告)

#### 配置文件

- **GitLab CI 安全扫描**: `.gitlab-ci.yml` (security stage)
- **Dependabot 配置**: `.github/dependabot.yml`
- **Snyk 配置**: `.snyk`

## 安全检查清单

### 开发阶段

- [ ] 遵循安全编码规范
- [ ] 输入验证和输出编码
- [ ] 使用参数化查询（防 SQL 注入）
- [ ] 实施 CSRF 防护
- [ ] 正确的认证和授权
- [ ] 敏感数据加密
- [ ] 错误处理不泄露信息
- [ ] 日志不记录敏感数据

### 代码提交前

- [ ] 无硬编码密钥和密码
- [ ] 依赖漏洞扫描通过
- [ ] 代码静态分析通过
- [ ] 单元测试覆盖率 >= 80%
- [ ] 安全代码审查通过

### 部署前

- [ ] 安全配置检查
- [ ] 密钥管理正确
- [ ] 最小权限原则
- [ ] 安全头配置
- [ ] 限流规则配置
- [ ] 监控告警配置

## 安全工具

### 扫描工具

| 工具 | 用途 | 安装命令 |
|------|------|---------|
| Trivy | 容器和文件系统扫描 | `brew install trivy` |
| pip-audit | Python 依赖扫描 | `pip install pip-audit` |
| safety | Python 已知漏洞检查 | `pip install safety` |
| npm audit | npm 依赖审计 | 内置 |
| flutter pub outdated | Flutter 依赖检查 | 内置 |

### 开发工具

| 工具 | 用途 | 文档 |
|------|------|------|
| Git Secrets | 防止密钥提交 | [GitHub](https://github.com/awslabs/git-secrets) |
| pre-commit | Git 钩子管理 | [官网](https://pre-commit.com/) |
| OWASP ZAP | Web 应用扫描 | [官网](https://www.zaproxy.org/) |

## 安全指标

### 当前状态

| 指标 | 目标 | 当前 | 状态 |
|------|------|------|------|
| 高危漏洞修复时间 | < 24h | - | 🟢 |
| 中危漏洞修复时间 | < 7d | - | 🟢 |
| 安全扫描覆盖率 | 100% | 100% | ✅ |
| 依赖漏洞修复率 | > 95% | - | 🟡 |
| 测试覆盖率 | > 80% | - | 🟡 |

### 图例

- ✅ 已达标
- 🟢 正常
- 🟡 需关注
- 🔴 需改进

## 培训资源

### 内部培训

- 安全意识培训（新员工必修）
- 安全编码规范（开发人员必修）
- 应急响应演练（每季度）

### 外部资源

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [PortSwigger Web Security Academy](https://portswigger.net/web-security)
- [CWE Top 25](https://cwe.mitre.org/top25/)

## 合规要求

### GDPR (欧盟)

- 数据最小化
- 用户同意机制
- 数据可携带权
- 被遗忘权
- 72 小时内报告数据泄露

### 个人信息保护法 (中国)

- 告知-同意原则
- 数据本地化存储
- 敏感信息单独同意
- 个人信息影响评估

## 联系方式

### 安全团队

- **邮箱**: security@dacong.ai
- **电话**: [紧急联系电话]
- **值班**: 7x24 小时

### 报告安全问题

如果您发现安全漏洞，请通过以下方式报告：

1. **邮件**: security@dacong.ai
2. **GitLab Issues**: 使用 `Security` 标签（私有）
3. **紧急情况**: 拨打 [紧急联系电话]

**请勿**在公开渠道（如公开 Issues、社交媒体）披露安全漏洞。

### 漏洞奖励计划

我们感谢安全研究人员的贡献，并提供漏洞奖励：

| 严重程度 | 奖励 |
|---------|------|
| Critical | ¥5,000 - ¥20,000 |
| High | ¥2,000 - ¥5,000 |
| Medium | ¥500 - ¥2,000 |
| Low | ¥100 - ¥500 |

详情请联系: security@dacong.ai

## 更新日志

| 日期 | 版本 | 变更 | 作者 |
|------|------|------|------|
| 2026-04-17 | 1.0 | 初始版本 | 安全工程团队 |

---

**维护者**: 安全工程团队  
**最后更新**: 2026-04-17  
**文档版本**: 1.0
