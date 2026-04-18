# GitHub Actions 使用指南

## 概述

本项目使用 GitHub Actions 实现 CI/CD 自动化，包括代码检查、测试、安全扫描、构建和部署。

## Workflows 说明

### 1. CI/CD Pipeline (`.github/workflows/ci.yml`)

**触发条件**：
- Push 到 `main`, `dev`, `develop` 分支
- Pull Request 到 `main`, `dev`, `develop` 分支
- 每日定时任务（凌晨 2 点）
- 手动触发

**包含的 Jobs**：

#### 安全检查
- `scan-secrets` - 密钥泄露扫描
- `check-key-expiry` - 密钥过期检查（仅定时任务）
- `security-python` - Python 依赖漏洞扫描
- `security-flutter-client` - Flutter 客户端依赖扫描
- `security-flutter-admin` - Flutter 管理后台依赖扫描
- `security-npm` - NPM 依赖扫描
- `security-trivy` - Trivy 容器和依赖扫描

#### 代码质量检查
- `lint-client` - Flutter 客户端代码检查
- `lint-admin` - Flutter 管理后台代码检查
- `lint-api` - API 代码检查
- `lint-spider` - Python 爬虫代码检查

#### 测试
- `test-client` - Flutter 客户端测试（覆盖率 ≥ 80%）
- `test-admin` - Flutter 管理后台测试（覆盖率 ≥ 70%）
- `test-api` - API 测试（覆盖率 ≥ 85%）

#### 构建
- `build-web` - Flutter Web 构建
- `build-android` - Android APK 构建
- `build-ios` - iOS 构建（需要 macOS runner）

### 2. Security Scan (`.github/workflows/security-scan.yml`)

**触发条件**：
- 每日定时任务（凌晨 2 点）
- 每周全面审计（每周一凌晨 3 点）
- 手动触发

**功能**：
- 运行完整的安全扫描
- 生成详细报告
- 发现 CRITICAL 漏洞时自动创建 Issue

### 3. Deploy (`.github/workflows/deploy.yml`)

**触发条件**：
- Push 到 `main` 分支
- 创建版本标签（`v*`）
- 手动触发

**环境**：
- `staging` - 测试环境
- `production` - 生产环境

### 4. Spider Scheduler (`.github/workflows/spider.yml`)

**触发条件**：
- 每小时定时任务
- 手动触发

**功能**：
- 运行爬虫任务
- 上传日志

## 手动触发 Workflow

### 方法 1: GitHub UI

1. 进入仓库 → **Actions**
2. 选择要运行的 Workflow
3. 点击 **Run workflow**
4. 选择分支
5. 点击 **Run workflow**

### 方法 2: GitHub CLI

```bash
# 安装 GitHub CLI
# macOS
brew install gh

# Windows
winget install --id GitHub.cli

# Linux
sudo apt install gh

# 登录
gh auth login

# 触发 CI/CD Pipeline
gh workflow run ci.yml

# 触发安全扫描
gh workflow run security-scan.yml

# 触发部署
gh workflow run deploy.yml

# 查看运行状态
gh run list

# 查看特定运行的日志
gh run view <run-id> --log
```

## 查看 Workflow 结果

### 查看运行状态

1. 进入仓库 → **Actions**
2. 查看所有 Workflow 运行记录
3. 点击具体的运行查看详情

### 下载 Artifacts

1. 进入具体的 Workflow 运行
2. 滚动到底部 **Artifacts** 部分
3. 点击下载

### 查看安全扫描报告

1. 进入 **Security** → **Code scanning alerts**
2. 查看 Trivy 扫描结果
3. 或下载 Artifacts 中的 JSON 报告

## 配置 Secrets

### 必需的 Secrets

在 **Settings** → **Secrets and variables** → **Actions** 中配置：

| Secret Name | 说明 | 示例 |
|-------------|------|------|
| `SUPABASE_URL` | Supabase 项目 URL | `https://xxx.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase 服务密钥 | `eyJxxx...` |
| `SUPABASE_ANON_KEY` | Supabase 匿名密钥 | `eyJxxx...` |

### 可选的 Secrets

| Secret Name | 说明 |
|-------------|------|
| `CODECOV_TOKEN` | Codecov 上传 token |
| `SLACK_WEBHOOK_URL` | Slack 通知 webhook |
| `SENTRY_DSN` | Sentry 错误追踪 DSN |

## 配置环境

### 创建环境

1. 进入 **Settings** → **Environments**
2. 点击 **New environment**
3. 输入环境名称（`staging` 或 `production`）
4. 配置保护规则：
   - ✅ Required reviewers（生产环境推荐）
   - ✅ Wait timer（等待时间）
   - ✅ Deployment branches（限制分支）

### 环境变量

在环境中配置特定的变量：
- `DEPLOY_URL` - 部署 URL
- `API_ENDPOINT` - API 端点

## 分支保护规则

### 推荐配置

1. 进入 **Settings** → **Branches**
2. 点击 **Add branch protection rule**
3. Branch name pattern: `main`
4. 勾选：
   - ✅ Require a pull request before merging
   - ✅ Require approvals (1)
   - ✅ Require status checks to pass before merging
     - `scan-secrets`
     - `security-trivy`
     - `lint-client`
     - `lint-admin`
     - `lint-api`
     - `lint-spider`
     - `test-client`
     - `test-admin`
     - `test-api`
   - ✅ Require branches to be up to date before merging
   - ✅ Require conversation resolution before merging

## 通知配置

### Slack 通知

使用 `slack-github-action`:

```yaml
- name: Slack 通知
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
    payload: |
      {
        "text": "部署完成: ${{ github.repository }}"
      }
```

### Email 通知

GitHub 默认会发送邮件通知，可在个人设置中配置：
1. **Settings** → **Notifications**
2. 配置 **Actions** 通知

## 成本优化

### GitHub Free 限制

- ✅ 2000 CI/CD 分钟/月（Linux）
- ✅ 500MB 存储空间
- ✅ 无限公开仓库
- ✅ 无限私有仓库

### 优化建议

1. **使用缓存**：
```yaml
- uses: actions/cache@v4
  with:
    path: ~/.pub-cache
    key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}
```

2. **条件执行**：
```yaml
if: github.ref == 'refs/heads/main'
```

3. **并发控制**：
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

4. **使用 self-hosted runners**（如果分钟数不够）

## 故障排查

### Workflow 失败

1. 查看日志找到错误信息
2. 检查 Secrets 是否配置正确
3. 检查依赖是否安装成功
4. 本地复现问题

### 权限问题

如果遇到权限错误，在 Workflow 中添加：

```yaml
permissions:
  contents: read
  security-events: write
  actions: read
```

### 超时问题

调整超时时间：

```yaml
jobs:
  my-job:
    timeout-minutes: 60
```

## 最佳实践

1. **使用矩阵策略测试多个版本**：
```yaml
strategy:
  matrix:
    flutter-version: ['3.22.0', '3.24.0']
```

2. **使用可复用的 Workflows**：
```yaml
jobs:
  call-workflow:
    uses: ./.github/workflows/reusable.yml
```

3. **使用 Dependabot 自动更新依赖**：
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

4. **定期审查 Workflow 运行时间和成本**

## 相关文档

- [GitHub Actions 官方文档](https://docs.github.com/en/actions)
- [Workflow 语法](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [从 GitLab CI 迁移](https://docs.github.com/en/actions/migrating-to-github-actions/migrating-from-gitlab-cicd-to-github-actions)
- [安全最佳实践](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)

## 监控和分析

### 查看使用情况

1. 进入 **Settings** → **Billing and plans**
2. 查看 **Actions** 使用分钟数
3. 查看 **Packages** 存储使用量

### 性能分析

1. 进入 **Insights** → **Actions**
2. 查看 Workflow 运行时间趋势
3. 识别慢速 Jobs 并优化

## 支持

如有问题：
1. 查看 [GitHub Actions 文档](https://docs.github.com/en/actions)
2. 搜索 [GitHub Community](https://github.community/)
3. 创建 Issue 寻求帮助
