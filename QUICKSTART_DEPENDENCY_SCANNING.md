# 依赖漏洞扫描 - 快速开始

## 5 分钟快速上手

### 1. 运行安全扫描

```bash
# 全面扫描所有依赖
./scripts/security_scan.sh

# 查看扫描报告
cat security-reports/scan-summary-*.txt
```

### 2. 修复发现的漏洞

```bash
# 自动修复
./scripts/fix_vulnerabilities.sh

# 查看修复报告
cat security-reports/vulnerability-summary-*.txt
```

### 3. 验证修复

```bash
# 运行测试
./scripts/run_all_tests.sh

# 重新扫描确认
./scripts/security_scan.sh
```

### 4. 提交变更

```bash
git add .
git commit -m "chore(deps): fix security vulnerabilities"
git push
```

---

## 配置定期扫描

### GitLab CI/CD Schedules

1. 进入 GitLab 项目页面
2. 导航到 **CI/CD → Schedules**
3. 点击 **New schedule**
4. 配置:
   - **Description**: Weekly Security Scan
   - **Interval pattern**: `0 9 * * 1` (每周一上午 9:00)
   - **Target branch**: `main`
   - **Variables**: `SCHEDULE_TYPE=security`
5. 点击 **Save pipeline schedule**

### Dependabot (已配置)

Dependabot 已配置为每周一上午 9:00 自动检查更新：
- 自动创建 PR
- 仅安全更新
- 每个生态系统最多 5 个 PR

---

## 处理漏洞

### 高危漏洞 (24 小时内)

```bash
# 1. 评估影响
./scripts/security_scan.sh

# 2. 立即修复
./scripts/fix_vulnerabilities.sh

# 3. 测试验证
./scripts/run_all_tests.sh

# 4. 紧急发布
./scripts/deploy_production.sh
```

### 中低危漏洞 (7-30 天内)

```bash
# 1. 创建修复分支
git checkout -b fix/security-vulnerabilities

# 2. 修复漏洞
./scripts/fix_vulnerabilities.sh

# 3. 测试验证
./scripts/run_all_tests.sh

# 4. 创建 MR
git add .
git commit -m "chore(deps): fix security vulnerabilities"
git push origin fix/security-vulnerabilities
```

---

## 常用命令

### 扫描命令

```bash
# 全面扫描
./scripts/security_scan.sh

# 仅扫描 Flutter
cd dacong-client && flutter pub outdated

# 仅扫描 Python
cd dacong-spider && pip-audit -r requirements.txt

# 仅扫描 npm
cd dacong-console && npm audit
```

### 修复命令

```bash
# 自动修复所有
./scripts/fix_vulnerabilities.sh

# 手动升级 Flutter 依赖
cd dacong-client && flutter pub upgrade <package>

# 手动升级 Python 依赖
cd dacong-spider && pip install --upgrade <package>

# 手动修复 npm 依赖
cd dacong-console && npm install <package>@latest
```

### 报告命令

```bash
# 查看最新扫描报告
cat security-reports/scan-summary-*.txt | tail -100

# 查看最新修复报告
cat security-reports/vulnerability-summary-*.txt | tail -100

# 列出所有报告
ls -lh security-reports/
```

---

## 工具安装

### 可选工具（推荐安装）

#### pip-audit (Python 漏洞扫描)

```bash
pip install pip-audit
```

#### safety (Python 已知漏洞检查)

```bash
pip install safety
```

#### Trivy (容器和文件系统扫描)

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

---

## 文档链接

- [完整文档](docs/security/DEPENDENCY_SCANNING.md) - 详细的扫描和修复流程
- [安全策略](docs/security/SECURITY_POLICY.md) - 安全标准和最佳实践
- [应急响应](docs/security/INCIDENT_RESPONSE.md) - 安全事件处理流程
- [文档索引](docs/security/README.md) - 所有安全文档导航

---

## 获取帮助

### 报告安全问题

- **邮箱**: security@dacong.ai
- **电话**: [紧急联系电话]
- **GitLab Issues**: 使用 `Security` 标签

### 常见问题

**Q: 扫描发现很多过期依赖，都需要升级吗？**  
A: 优先修复有已知漏洞的依赖。过期但无漏洞的依赖可以计划升级。

**Q: Dependabot PR 可以直接合并吗？**  
A: 建议先查看 CHANGELOG，确认无破坏性变更后再合并。

**Q: 如何处理无法自动修复的漏洞？**  
A: 查看详细报告，手动升级依赖或寻找替代方案。参考 [修复流程文档](docs/security/DEPENDENCY_SCANNING.md#漏洞修复流程)。

**Q: 扫描工具报告误报怎么办？**  
A: 人工审查确认后，可以在配置文件中添加忽略规则。

---

**快速开始版本**: 1.0  
**最后更新**: 2026-04-18
