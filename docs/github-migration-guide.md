# GitHub 迁移完整方案

## 迁移步骤

### 第 1 步：创建 GitHub 仓库

1. 访问 https://github.com/new
2. 填写仓库信息：
   - Repository name: `dacong`
   - Description: `DaCong - AI驱动的技术内容聚合平台`
   - Visibility: `Private` 或 `Public`
   - ❌ 不要勾选 "Initialize this repository with a README"
3. 点击 **Create repository**

### 第 2 步：迁移代码

```bash
# 1. 进入项目目录
cd e:/gitlab/dacong

# 2. 添加 GitHub 远程仓库（替换 your-username 为你的 GitHub 用户名）
git remote add github https://github.com/your-username/dacong.git

# 3. 查看远程仓库配置
git remote -v

# 4. 推送所有分支到 GitHub
git push github --all

# 5. 推送所有标签
git push github --tags

# 6. 设置 GitHub 为默认远程仓库（可选）
git remote rename origin gitlab
git remote rename github origin

# 7. 验证推送成功
git remote -v
```

### 第 3 步：配置 GitHub Secrets

在 GitHub 仓库中配置环境变量：

1. 进入仓库 → **Settings** → **Secrets and variables** → **Actions**
2. 点击 **New repository secret**
3. 添加以下 secrets：

| Name | Value | 说明 |
|------|-------|------|
| `SUPABASE_URL` | `https://xxx.supabase.co` | Supabase 项目 URL |
| `SUPABASE_SERVICE_ROLE_KEY` | `eyJxxx...` | Supabase 服务密钥 |
| `SUPABASE_ANON_KEY` | `eyJxxx...` | Supabase 匿名密钥 |

### 第 4 步：启用 GitHub Actions

1. 进入仓库 → **Actions**
2. 点击 **I understand my workflows, go ahead and enable them**

### 第 5 步：配置 GitHub Pages（可选）

如果需要部署 Web 应用：

1. 进入 **Settings** → **Pages**
2. Source: `GitHub Actions`
3. 保存

## 验证迁移

```bash
# 1. 克隆 GitHub 仓库到新目录验证
cd /tmp
git clone https://github.com/your-username/dacong.git dacong-test
cd dacong-test

# 2. 检查分支
git branch -a

# 3. 检查提交历史
git log --oneline -10

# 4. 检查文件完整性
ls -la
```

## 后续操作

### 1. 更新本地仓库配置

```bash
# 如果你想完全切换到 GitHub
cd e:/gitlab/dacong
git remote remove gitlab  # 删除 GitLab 远程仓库
git remote rename github origin  # 将 GitHub 设为默认远程仓库
```

### 2. 更新文档中的链接

需要更新以下文件中的 GitLab 链接为 GitHub 链接：
- README.md
- 各种文档中的仓库链接

### 3. 配置分支保护规则

1. 进入 **Settings** → **Branches**
2. 点击 **Add branch protection rule**
3. Branch name pattern: `main`
4. 勾选：
   - ✅ Require a pull request before merging
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging

### 4. 配置通知

1. 进入 **Settings** → **Notifications**
2. 配置邮件通知
3. 或集成 Slack/Discord

## 成本说明

### GitHub Free 版本包含：

- ✅ 无限私有仓库
- ✅ 无限协作者
- ✅ 2000 CI/CD 分钟/月（Linux）
- ✅ 500MB 包存储
- ✅ GitHub Actions
- ✅ GitHub Pages
- ✅ 社区支持

### 如果 CI/CD 分钟数不够：

**GitHub Pro**（$4/月）：
- 3000 CI/CD 分钟/月
- 2GB 包存储
- 高级代码审查工具

**GitHub Team**（$4/用户/月）：
- 3000 CI/CD 分钟/月
- 团队访问控制
- 代码所有者

## 故障排查

### 推送失败：Authentication failed

```bash
# 使用 Personal Access Token (PAT)
# 1. 访问 https://github.com/settings/tokens
# 2. Generate new token (classic)
# 3. 勾选 repo 权限
# 4. 生成并复制 token
# 5. 使用 token 作为密码推送

git push https://your-username:your-token@github.com/your-username/dacong.git --all
```

### 推送速度慢

```bash
# 使用 SSH 代替 HTTPS
# 1. 生成 SSH 密钥
ssh-keygen -t ed25519 -C "your-email@example.com"

# 2. 添加到 GitHub
# 访问 https://github.com/settings/keys
# 添加 ~/.ssh/id_ed25519.pub 的内容

# 3. 更改远程 URL
git remote set-url github git@github.com:your-username/dacong.git
```

## 下一步

查看以下文件了解 GitHub Actions 配置：
- `.github/workflows/ci.yml` - 主 CI/CD 流程
- `.github/workflows/security-scan.yml` - 安全扫描
- `.github/workflows/deploy.yml` - 部署流程
- `docs/github-actions-guide.md` - GitHub Actions 使用指南

## 相关文档

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [从 GitLab CI 迁移到 GitHub Actions](https://docs.github.com/en/actions/migrating-to-github-actions/migrating-from-gitlab-cicd-to-github-actions)
- [GitHub Secrets 管理](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
