#!/bin/bash

# 自动修复脚本
# 自动修复所有可修复的代码问题

set -e

echo "=========================================="
echo "DaCong 自动修复工具"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Flutter 客户端修复
echo "1. 修复 Flutter 客户端 (dacong-client)"
echo "------------------------------------------"

cd dacong-client

echo "安装依赖..."
flutter pub get

echo "格式化代码..."
dart format .

echo "修复可自动修复的问题..."
flutter analyze --fix

echo -e "${GREEN}✓ Flutter 客户端修复完成${NC}"
echo ""

cd ..

# 2. API 后端修复
echo "2. 修复 API 后端 (dacong-api)"
echo "------------------------------------------"

cd dacong-api

echo "格式化 Deno 代码..."
deno fmt supabase/functions/

echo -e "${GREEN}✓ API 后端修复完成${NC}"
echo ""

cd ..

# 3. Python 爬虫修复
echo "3. 修复 Python 爬虫 (dacong-spider)"
echo "------------------------------------------"

cd dacong-spider

if command -v python3 &> /dev/null; then
    if command -v black &> /dev/null; then
        echo "格式化 Python 代码..."
        black .
        echo -e "${GREEN}✓ Python 代码格式化完成${NC}"
    else
        echo -e "${YELLOW}⚠ black 未安装，跳过格式化${NC}"
        echo "安装命令: pip install black"
    fi
    
    if command -v isort &> /dev/null; then
        echo "排序 Python imports..."
        isort .
        echo -e "${GREEN}✓ Python imports 排序完成${NC}"
    else
        echo -e "${YELLOW}⚠ isort 未安装，跳过 imports 排序${NC}"
        echo "安装命令: pip install isort"
    fi
else
    echo -e "${YELLOW}⚠ Python 未安装，跳过 Python 修复${NC}"
fi

cd ..
echo ""

# 4. Git 检查
echo "4. Git 状态"
echo "------------------------------------------"

git status --short

echo ""
echo "=========================================="
echo -e "${GREEN}✓ 所有自动修复完成！${NC}"
echo "=========================================="
echo ""
echo "下一步："
echo "1. 运行 ./scripts/code_quality_check.sh 验证修复"
echo "2. 检查 git diff 查看更改"
echo "3. 提交更改: git add . && git commit -m 'fix: 代码质量优化'"
