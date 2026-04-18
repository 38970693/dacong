#!/bin/bash
# GitHub 快速迁移脚本

set -e

echo "=========================================="
echo "GitHub 迁移脚本"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查是否在 git 仓库中
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}错误: 当前目录不是 Git 仓库${NC}"
    exit 1
fi

echo -e "${BLUE}请输入你的 GitHub 用户名:${NC}"
read -r GITHUB_USERNAME

if [ -z "$GITHUB_USERNAME" ]; then
    echo -e "${RED}错误: GitHub 用户名不能为空${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}请输入仓库名称 (默认: dacong):${NC}"
read -r REPO_NAME
REPO_NAME=${REPO_NAME:-dacong}

echo ""
echo -e "${YELLOW}开始迁移到 GitHub...${NC}"
echo ""

# 1. 检查 GitHub 远程仓库是否已存在
if git remote | grep -q "^github$"; then
    echo -e "${YELLOW}GitHub 远程仓库已存在，将更新 URL${NC}"
    git remote set-url github "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
else
    echo -e "${GREEN}添加 GitHub 远程仓库${NC}"
    git remote add github "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
fi

# 2. 显示远程仓库配置
echo ""
echo -e "${GREEN}当前远程仓库配置:${NC}"
git remote -v
echo ""

# 3. 推送所有分支
echo -e "${YELLOW}推送所有分支到 GitHub...${NC}"
if git push github --all; then
    echo -e "${GREEN}✓ 所有分支推送成功${NC}"
else
    echo -e "${RED}✗ 分支推送失败${NC}"
    echo ""
    echo -e "${YELLOW}提示: 如果遇到认证问题，请使用 Personal Access Token${NC}"
    echo "1. 访问 https://github.com/settings/tokens"
    echo "2. 生成新 token (勾选 repo 权限)"
    echo "3. 使用以下命令推送:"
    echo "   git push https://$GITHUB_USERNAME:<your-token>@github.com/$GITHUB_USERNAME/$REPO_NAME.git --all"
    exit 1
fi

# 4. 推送所有标签
echo ""
echo -e "${YELLOW}推送所有标签到 GitHub...${NC}"
if git push github --tags; then
    echo -e "${GREEN}✓ 所有标签推送成功${NC}"
else
    echo -e "${YELLOW}⚠ 标签推送失败（可能没有标签）${NC}"
fi

# 5. 询问是否设置 GitHub 为默认远程仓库
echo ""
echo -e "${BLUE}是否将 GitHub 设置为默认远程仓库? (y/n):${NC}"
read -r SET_DEFAULT

if [ "$SET_DEFAULT" = "y" ] || [ "$SET_DEFAULT" = "Y" ]; then
    if git remote | grep -q "^origin$"; then
        git remote rename origin gitlab
        echo -e "${GREEN}✓ 原 origin 已重命名为 gitlab${NC}"
    fi
    git remote rename github origin
    echo -e "${GREEN}✓ GitHub 已设置为默认远程仓库 (origin)${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}迁移完成！${NC}"
echo "=========================================="
echo ""
echo "远程仓库配置:"
git remote -v
echo ""
echo "下一步:"
echo "1. 访问 https://github.com/$GITHUB_USERNAME/$REPO_NAME"
echo "2. 配置 Secrets (Settings → Secrets and variables → Actions):"
echo "   - SUPABASE_URL"
echo "   - SUPABASE_SERVICE_ROLE_KEY"
echo "   - SUPABASE_ANON_KEY"
echo "3. 启用 GitHub Actions (Actions → Enable workflows)"
echo "4. 配置分支保护规则 (Settings → Branches)"
echo ""
echo "详细文档:"
echo "- docs/github-migration-guide.md"
echo "- docs/github-actions-guide.md"
echo ""
