# 安全扫描快速启动指南

## 概述

本指南帮助您快速配置和运行 DaCong 项目的安全扫描系统。

## 快速开始

### 1. 本地运行首次安全扫描

```bash
# 赋予执行权限
chmod +x scripts/run-security-scan.sh

# 运行扫描
bash scripts/run-security-scan.sh
```

扫描报告将保存在 `security-reports/` 目录。

### 2. 修复发现的漏洞

```bash
# 赋予执行权限
chmod +x scripts/fix-vulnerabilities.sh

# 自动修复漏洞
bash scripts/fix-vulnerabilities.sh
```

### 3. 配置 GitLab CI/CD 定时任务

参考 [GitLab Schedules 配置指南](./gitlab-schedules-setup.md) 配置以下定时任务：

#### 每日安全扫描
- **Cron**: `0 2 * * *` (每天凌晨 2 点)
- **变量**: `SCHEDULE_TYPE=security`
- **分支**: `main`

#### 每周全面审计
- **Cron**: `0 3 * * 1` (每周一凌晨 3 点)
- **变量**: `SCHEDULE_TYPE=security`, `AUDIT_LEVEL=full`
- **分支**: `main`

#### 爬虫定时调度
- **Cron**: `0 * * * *` (每小时)
- **变量**: `SCHEDULE_TYPE=spider`
- **分支**: `main`

### 4. 配置 GitLab 环境变量

在 GitLab 项目中设置（**Settings** → **CI/CD** → **Variables**）：

| 变量名 | 说明 | 保护 | 掩码 |
|--------|------|------|------|
| `SUPABASE_URL` | Supabase 项目 URL | ✅ | ❌ |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase 服务密钥 | ✅ | ✅ |
| `SUPABASE_ANON_KEY` | Supabase 匿名密钥 | ✅ | ✅ |

## 安全扫描工具

项目使用以下工具进行安全扫描：

### Python 依赖扫描
- **pip-audit**: 检查 Python 包的已知漏洞
- **safety**: 扫描 Python 依赖的安全问题

```bash
cd dacong-spider
pip install pip-audit safety
pip-audit --requirement requirements.txt
safety check --file requirements.txt
```

### Flutter 依赖扫描
- **flutter pub outdated**: 检查过期的 Flutter 包

```bash
cd dacong-client
flutter pub outdated
```

### NPM 依赖扫描
- **npm audit**: 检查 Node.js 依赖漏洞

```bash
cd dacong-console
npm audit
```

### 容器和文件系统扫描
- **Trivy**: 全面的容器和依赖漏洞扫描

```bash
# 安装 Trivy (Linux)
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# 扫描项目
trivy fs --severity HIGH,CRITICAL .
```

### 密钥泄露扫描
- **自定义脚本**: 检查代码中的硬编码密钥

```bash
cd dacong-api
bash scripts/scan_for_secrets.sh --ci
```

## 手动触发 GitLab Pipeline

### 方法 1: 通过 GitLab UI
1. 进入 **CI/CD** → **Pipelines**
2. 点击 **Run pipeline**
3. 选择分支 `main`
4. 添加变量 `SCHEDULE_TYPE=security`
5. 点击 **Run pipeline**

### 方法 2: 通过 GitLab CLI
```bash
# 安装 glab
brew install glab  # macOS
# 或
sudo apt install glab  # Linux

# 触发 pipeline
glab ci run --branch main --variable SCHEDULE_TYPE=security
```

## 查看扫描报告

### 本地报告
```bash
# 查看最新报告
ls -lht security-reports/ | head -10

# 查看 JSON 报告
cat security-reports/trivy-*.json | jq '.Results[] | select(.Vulnerabilities != null)'
```

### GitLab Artifacts
1. 进入 **CI/CD** → **Pipelines**
2. 选择对应的 pipeline
3. 点击右侧的 **Download** 按钮下载 artifacts
4. 解压查看报告

## 常见漏洞修复

### Python 依赖更新
```bash
cd dacong-spider

# 更新特定包
pip install --upgrade requests scrapy aiohttp

# 更新所有包到最新兼容版本
pip install --upgrade -r requirements.txt
```

### Flutter 依赖更新
```bash
cd dacong-client

# 更新所有依赖
flutter pub upgrade

# 更新到最新主版本（可能有破坏性变更）
flutter pub upgrade --major-versions
```

### NPM 依赖修复
```bash
cd dacong-console

# 自动修复漏洞
npm audit fix

# 强制修复（可能有破坏性变更）
npm audit fix --force
```

## 持续集成流程

```
┌─────────────────────────────────────────────────────────┐
│  1. 代码提交到 dev/develop 分支                          │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│  2. 自动触发 CI Pipeline                                 │
│     - 密钥泄露扫描 (scan-secrets)                        │
│     - 依赖漏洞扫描 (security:*)                          │
│     - 代码质量检查 (lint:*)                              │
│     - 单元测试 (test-*)                                  │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│  3. 如果扫描失败                                         │
│     - 查看报告                                           │
│     - 修复漏洞                                           │
│     - 重新提交                                           │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│  4. 所有检查通过后                                       │
│     - 创建 Merge Request 到 main                         │
│     - Code Review                                        │
│     - 合并到 main                                        │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│  5. 定时任务持续监控                                     │
│     - 每日安全扫描                                       │
│     - 每周全面审计                                       │
│     - 发现问题自动通知                                   │
└─────────────────────────────────────────────────────────┘
```

## 通知配置

### Slack 通知
1. 进入 **Settings** → **Integrations** → **Slack notifications**
2. 输入 Webhook URL
3. 勾选 **Pipeline events**
4. 勾选 **Failed pipelines only**

### Email 通知
1. 进入 **Settings** → **Integrations** → **Emails on push**
2. 输入邮箱地址
3. 勾选 **Pipeline events**

## 故障排查

### 扫描工具未安装
```bash
# Python 工具
pip install pip-audit safety

# Trivy
# 参考: https://aquasecurity.github.io/trivy/latest/getting-started/installation/
```

### GitLab Runner 不可用
```bash
# 检查 Runner 状态
# GitLab UI: Settings → CI/CD → Runners

# 或使用 shared runners
# Settings → CI/CD → Runners → Enable shared runners
```

### 依赖安装失败
```bash
# 清理缓存
pip cache purge
flutter pub cache clean
npm cache clean --force

# 重新安装
pip install -r requirements.txt
flutter pub get
npm install
```

## 最佳实践

1. **定期更新依赖**: 每月至少更新一次依赖包
2. **及时修复漏洞**: HIGH 和 CRITICAL 漏洞应在 24 小时内修复
3. **测试后再部署**: 修复漏洞后必须运行完整测试套件
4. **保留审计记录**: 保存所有安全扫描报告至少 90 天
5. **监控告警**: 配置失败通知，确保及时响应

## 相关文档

- [GitLab Schedules 配置指南](./gitlab-schedules-setup.md)
- [GitLab CI/CD 配置](../.gitlab-ci.yml)
- [安全扫描脚本](../scripts/run-security-scan.sh)
- [漏洞修复脚本](../scripts/fix-vulnerabilities.sh)

## 支持

如有问题，请联系：
- 技术负责人: [您的联系方式]
- 安全团队: [安全团队联系方式]
