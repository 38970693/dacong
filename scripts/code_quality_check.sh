#!/bin/bash

# 代码质量检查脚本
# 检查所有子项目的代码质量

set -e

echo "=========================================="
echo "DaCong 代码质量检查"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查结果统计
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# 检查函数
check_step() {
    local name=$1
    local command=$2
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -n "检查 $name... "
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 通过${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}✗ 失败${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

# 1. Flutter 客户端检查
echo "1. Flutter 客户端 (dacong-client)"
echo "------------------------------------------"

cd dacong-client

# 检查依赖
check_step "Flutter 依赖" "flutter pub get"

# 代码分析
check_step "Flutter 代码分析" "flutter analyze"

# 代码格式
check_step "Flutter 代码格式" "dart format --set-exit-if-changed ."

# 运行测试
check_step "Flutter 单元测试" "flutter test"

cd ..
echo ""

# 2. API 后端检查
echo "2. API 后端 (dacong-api)"
echo "------------------------------------------"

cd dacong-api

# 检查 Deno 格式
check_step "Deno 代码格式" "deno fmt --check supabase/functions/"

# 检查 Deno lint
check_step "Deno 代码检查" "deno lint supabase/functions/"

# 类型检查
check_step "TypeScript 类型检查" "deno check supabase/functions/**/*.ts"

cd ..
echo ""

# 3. Python 爬虫检查
echo "3. Python 爬虫 (dacong-spider)"
echo "------------------------------------------"

cd dacong-spider

# 检查是否有 Python
if command -v python3 &> /dev/null; then
    # 代码格式检查
    if command -v black &> /dev/null; then
        check_step "Python 代码格式 (black)" "black --check ."
    else
        echo -e "${YELLOW}⚠ black 未安装，跳过格式检查${NC}"
    fi
    
    # 代码质量检查
    if command -v flake8 &> /dev/null; then
        check_step "Python 代码质量 (flake8)" "flake8 . --max-line-length=100"
    else
        echo -e "${YELLOW}⚠ flake8 未安装，跳过质量检查${NC}"
    fi
    
    # 类型检查
    if command -v mypy &> /dev/null; then
        check_step "Python 类型检查 (mypy)" "mypy . --ignore-missing-imports"
    else
        echo -e "${YELLOW}⚠ mypy 未安装，跳过类型检查${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Python 未安装，跳过 Python 检查${NC}"
fi

cd ..
echo ""

# 4. 文档检查
echo "4. 文档检查"
echo "------------------------------------------"

# 检查必要的文档文件
check_step "README.md 存在" "test -f README.md"
check_step "QUICKSTART.md 存在" "test -f QUICKSTART.md"

echo ""

# 输出总结
echo "=========================================="
echo "检查总结"
echo "=========================================="
echo "总检查项: $TOTAL_CHECKS"
echo -e "通过: ${GREEN}$PASSED_CHECKS${NC}"
echo -e "失败: ${RED}$FAILED_CHECKS${NC}"
echo ""

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}✓ 所有检查通过！${NC}"
    exit 0
else
    echo -e "${RED}✗ 有 $FAILED_CHECKS 项检查失败${NC}"
    exit 1
fi
