# 依赖漏洞扫描文档

## 概述

本文档描述 DaCong 项目的依赖管理策略、漏洞扫描流程和修复流程。

## 目录

- [依赖管理策略](#依赖管理策略)
- [漏洞扫描流程](#漏洞扫描流程)
- [漏洞修复流程](#漏洞修复流程)
- [安全更新策略](#安全更新策略)
- [应急响应流程](#应急响应流程)
- [工具和配置](#工具和配置)

---

## 依赖管理策略

### 原则

1. **最小依赖原则**: 只引入必要的依赖，避免依赖膨胀
2. **及时更新原则**: 定期更新依赖，保持在安全版本
3. **版本锁定原则**: 使用锁文件固定依赖版本，确保构建可重现
4. **安全优先原则**: 安全漏洞修复优先于功能开发

### 依赖分类

| 类型 | 技术栈 | 管理工具 | 锁文件 |
|------|--------|---------|--------|
| Flutter 客户端 | Dart/Flutter | pub | pubspec.lock |
| Flutter 管理后台 | Dart/Flutter | pub | pubspec.lock |
| Python 爬虫 | Python 3.11 | pip | requirements.txt |
| Next.js 控制台 | Node.js/React | npm | package-lock.json |
| Deno API | Deno/TypeScript | deno | deno.lock |

### 版本策略

- **主版本 (Major)**: 手动审查后升级，可能包含破坏性变更
- **次版本 (Minor)**: 自动升级，向后兼容的新功能
- **补丁版本 (Patch)**: 自动升级，bug 修复和安全补丁

---

## 漏洞扫描流程

### 自动扫描

#### 1. CI/CD 集成扫描

在每次 MR 和主分支提交时自动触发：

```yaml
# .gitlab-ci.yml
security:flutter-client:
  stage: security
  script:
    - flutter pub outdated
  allow_failure: true

security:python:
  stage: security
  script:
    - pip-audit --requirement requirements.txt
    - safety check --file requirements.txt
  allow_failure: true

security:npm:
  stage: security
  script:
    - npm audit --audit-level=high
  allow_failure: true

security:trivy:
  stage: security
  script:
    - trivy fs --severity HIGH,CRITICAL .
  allow_failure: true
```

#### 2. 定期扫描

通过 GitLab CI/CD Schedules 配置：

- **频率**: 每周一次（周一上午 9:00）
- **触发条件**: `$CI_PIPELINE_SOURCE == "schedule"`
- **通知**: 扫描结果发送到安全团队

#### 3. Dependabot 自动更新

GitHub Dependabot 配置（`.github/dependabot.yml`）：

- **频率**: 每周一次
- **范围**: 所有依赖包
- **策略**: 仅更新安全漏洞（`versioning-strategy: increase-if-necessary`）
- **限制**: 每个生态系统最多 5 个 PR

### 手动扫描

#### 使用扫描脚本

```bash
# 全面扫描所有依赖
./scripts/security_scan.sh

# 查看扫描报告
ls -lh security-reports/

# 查看汇总报告
cat security-reports/scan-summary-*.txt
```

#### 扫描工具

| 工具 | 用途 | 支持语言 |
|------|------|---------|
| `flutter pub outdated` | Flutter 依赖检查 | Dart |
| `pip-audit` | Python 漏洞扫描 | Python |
| `safety` | Python 已知漏洞数据库 | Python |
| `npm audit` | npm 依赖审计 | JavaScript |
| `trivy` | 容器和文件系统扫描 | 多语言 |

---

## 漏洞修复流程

### 修复优先级

| 严重程度 | SLA | 处理方式 |
|---------|-----|---------|
| 严重 (Critical) | 24 小时 | 立即修复，紧急发布 |
| 高危 (High) | 7 天 | 优先修复，下个版本发布 |
| 中危 (Medium) | 30 天 | 计划修复，常规迭代 |
| 低危 (Low) | 90 天 | 择机修复，技术债务清理 |

### 修复步骤

#### 1. 评估漏洞

```bash
# 运行扫描
./scripts/security_scan.sh

# 查看详细报告
cat security-reports/scan-summary-*.txt
```

评估内容：
- 漏洞严重程度（CVSS 评分）
- 影响范围（哪些模块使用）
- 利用难度（是否有公开 exploit）
- 修复成本（是否有破坏性变更）

#### 2. 自动修复

```bash
# 运行修复脚本
./scripts/fix_vulnerabilities.sh

# 查看修复报告
cat security-reports/vulnerability-summary-*.txt
```

自动修复包括：
- Flutter 依赖自动升级
- npm 依赖自动修复（`npm audit fix`）
- Python 依赖生成升级建议

#### 3. 手动修复

对于无法自动修复的漏洞：

```bash
# Flutter
cd dacong-client
flutter pub upgrade <package_name>

# Python
cd dacong-spider
pip install --upgrade <package_name>
pip freeze > requirements.txt

# npm
cd dacong-console
npm install <package_name>@latest
```

#### 4. 验证修复

```bash
# 运行测试套件
./scripts/run_all_tests.sh

# 重新扫描
./scripts/security_scan.sh

# 验证漏洞已修复
cat security-reports/scan-summary-*.txt
```

#### 5. 提交变更

```bash
git add .
git commit -m "chore(deps): fix security vulnerabilities

- Upgrade package_name from x.x.x to y.y.y
- Fix CVE-YYYY-XXXXX (Critical)
- Fix CVE-YYYY-XXXXY (High)

Refs: #issue_number"

git push origin feature/security-fix
```

---

## 安全更新策略

### 更新频率

| 类型 | 频率 | 触发条件 |
|------|------|---------|
| 安全补丁 | 立即 | 发现严重/高危漏洞 |
| 依赖更新 | 每周 | Dependabot PR |
| 主版本升级 | 每季度 | 技术评审会议 |

### 更新流程

#### 1. 接收更新通知

来源：
- Dependabot PR
- GitLab CI/CD 扫描报告
- 安全邮件列表
- CVE 数据库订阅

#### 2. 评估更新

检查清单：
- [ ] 查看 CHANGELOG
- [ ] 检查破坏性变更
- [ ] 评估影响范围
- [ ] 确认测试覆盖

#### 3. 测试更新

```bash
# 创建测试分支
git checkout -b deps/update-package-name

# 更新依赖
./scripts/fix_vulnerabilities.sh

# 运行测试
./scripts/run_all_tests.sh

# 手动测试关键功能
```

#### 4. 合并更新

```bash
# 创建 MR
git push origin deps/update-package-name

# 等待 CI/CD 通过
# 代码审查
# 合并到主分支
```

---

## 应急响应流程

### 严重漏洞响应

当发现严重漏洞（CVSS >= 9.0）时：

#### 1. 立即响应（0-2 小时）

```bash
# 1. 确认漏洞
./scripts/security_scan.sh

# 2. 评估影响
# - 哪些服务受影响？
# - 是否已被利用？
# - 数据是否泄露？

# 3. 通知团队
# - 技术负责人
# - 安全团队
# - 运维团队
```

#### 2. 临时缓解（2-4 小时）

```bash
# 选项 1: 禁用受影响功能
# 选项 2: 添加 WAF 规则
# 选项 3: 限制访问权限
# 选项 4: 回滚到安全版本
```

#### 3. 修复部署（4-24 小时）

```bash
# 1. 修复漏洞
./scripts/fix_vulnerabilities.sh

# 2. 测试验证
./scripts/run_all_tests.sh

# 3. 紧急发布
./scripts/deploy_production.sh

# 4. 验证修复
./scripts/verify_deployment.sh
```

#### 4. 事后复盘（24-48 小时）

文档记录：
- 漏洞详情（CVE 编号、CVSS 评分）
- 影响范围（受影响的服务和用户）
- 响应时间线（发现、缓解、修复、验证）
- 根因分析（为什么会引入漏洞）
- 改进措施（如何避免类似问题）

---

## 工具和配置

### 安装扫描工具

#### pip-audit (Python)

```bash
pip install pip-audit
```

#### safety (Python)

```bash
pip install safety
```

#### Trivy (容器扫描)

```bash
# macOS
brew install aquasecurity/trivy/trivy

# Linux
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# Windows
choco install trivy
```

### 配置文件

#### .gitlab-ci.yml

安全扫描阶段已配置在 `.gitlab-ci.yml` 中，包括：
- Flutter 依赖扫描
- Python 依赖扫描
- npm 依赖扫描
- Trivy 容器扫描

#### .github/dependabot.yml

Dependabot 自动更新配置：
- 每周一上午 9:00 检查更新
- 每个生态系统最多 5 个 PR
- 仅更新安全漏洞

#### .snyk

Snyk 配置文件（可选）：

```yaml
# .snyk
version: v1.22.0
ignore: {}
patch: {}
```

### 脚本使用

#### 扫描脚本

```bash
# 全面扫描
./scripts/security_scan.sh

# 查看报告
ls -lh security-reports/
cat security-reports/scan-summary-*.txt
```

#### 修复脚本

```bash
# 自动修复
./scripts/fix_vulnerabilities.sh

# 查看修复报告
cat security-reports/vulnerability-summary-*.txt
```

---

## 最佳实践

### 开发阶段

1. **依赖审查**: 引入新依赖前检查安全记录
2. **版本锁定**: 提交锁文件到版本控制
3. **定期更新**: 每周检查依赖更新
4. **测试覆盖**: 确保测试覆盖率 >= 80%

### CI/CD 阶段

1. **自动扫描**: 每次 MR 触发安全扫描
2. **阻断机制**: 严重漏洞阻止合并
3. **报告归档**: 保存扫描报告 30 天
4. **通知机制**: 漏洞发现后自动通知

### 生产阶段

1. **监控告警**: 监控依赖漏洞公告
2. **快速响应**: 严重漏洞 24 小时内修复
3. **灰度发布**: 安全更新先灰度验证
4. **回滚准备**: 保留回滚能力

---

## 参考资源

### 漏洞数据库

- [CVE Details](https://www.cvedetails.com/)
- [NVD - National Vulnerability Database](https://nvd.nist.gov/)
- [Snyk Vulnerability Database](https://snyk.io/vuln/)
- [GitHub Advisory Database](https://github.com/advisories)

### 安全工具

- [Trivy](https://aquasecurity.github.io/trivy/)
- [pip-audit](https://pypi.org/project/pip-audit/)
- [Safety](https://pyup.io/safety/)
- [npm audit](https://docs.npmjs.com/cli/v8/commands/npm-audit)
- [Dependabot](https://github.com/dependabot)

### 安全标准

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE - Common Weakness Enumeration](https://cwe.mitre.org/)
- [CVSS - Common Vulnerability Scoring System](https://www.first.org/cvss/)

---

## 联系方式

如有安全问题，请联系：

- **安全团队邮箱**: security@dacong.ai
- **紧急联系人**: [技术负责人]
- **安全事件报告**: [GitLab Issues - Security Label]

---

**文档版本**: 1.0  
**最后更新**: 2026-04-17  
**维护者**: 安全工程团队
