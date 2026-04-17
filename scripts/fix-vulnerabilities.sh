#!/bin/bash
# 自动修复已知漏洞脚本
# 用途：根据安全扫描结果自动修复依赖漏洞

set -e

echo "=========================================="
echo "DaCong 项目漏洞修复"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FIXED_COUNT=0
FAILED_COUNT=0

# ==========================================
# 1. 修复 Python 依赖漏洞
# ==========================================
echo -e "${YELLOW}[1/4] 修复 Python 依赖漏洞...${NC}"
if [ -f "dacong-spider/requirements.txt" ]; then
    cd dacong-spider

    # 备份原文件
    cp requirements.txt requirements.txt.backup

    # 更新已知有漏洞的包
    echo "更新 Python 依赖到安全版本..."

    # 检查并更新常见漏洞包
    if grep -q "requests<2.32.0" requirements.txt 2>/dev/null; then
        sed -i 's/requests>=2.31.0/requests>=2.32.0/g' requirements.txt
        echo "  ✓ 更新 requests 到 2.32.0+"
        ((FIXED_COUNT++))
    fi

    if grep -q "scrapy<2.11.2" requirements.txt 2>/dev/null; then
        sed -i 's/scrapy>=2.11.0/scrapy>=2.11.2/g' requirements.txt
        echo "  ✓ 更新 scrapy 到 2.11.2+"
        ((FIXED_COUNT++))
    fi

    if grep -q "aiohttp<3.10.0" requirements.txt 2>/dev/null; then
        sed -i 's/aiohttp>=3.9.0/aiohttp>=3.10.0/g' requirements.txt
        echo "  ✓ 更新 aiohttp 到 3.10.0+"
        ((FIXED_COUNT++))
    fi

    # 测试安装
    echo "测试依赖安装..."
    if pip install --dry-run -r requirements.txt > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Python 依赖修复完成${NC}"
    else
        echo -e "${RED}✗ 依赖安装测试失败，恢复备份${NC}"
        mv requirements.txt.backup requirements.txt
        ((FAILED_COUNT++))
    fi

    cd ..
else
    echo -e "${RED}✗ 未找到 dacong-spider/requirements.txt${NC}"
fi
echo ""

# ==========================================
# 2. 修复 Flutter 客户端依赖
# ==========================================
echo -e "${YELLOW}[2/4] 修复 Flutter 客户端依赖...${NC}"
if [ -f "dacong-client/pubspec.yaml" ]; then
    if command -v flutter &> /dev/null; then
        cd dacong-client

        # 备份
        cp pubspec.yaml pubspec.yaml.backup

        echo "更新 Flutter 依赖..."
        flutter pub upgrade --major-versions 2>/dev/null || flutter pub upgrade || true

        # 测试构建
        if flutter pub get > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Flutter 客户端依赖更新完成${NC}"
            ((FIXED_COUNT++))
        else
            echo -e "${RED}✗ Flutter 依赖更新失败，恢复备份${NC}"
            mv pubspec.yaml.backup pubspec.yaml
            ((FAILED_COUNT++))
        fi

        cd ..
    else
        echo -e "${YELLOW}⚠ Flutter 未安装，跳过${NC}"
    fi
else
    echo -e "${RED}✗ 未找到 dacong-client/pubspec.yaml${NC}"
fi
echo ""

# ==========================================
# 3. 修复 Flutter 管理后台依赖
# ==========================================
echo -e "${YELLOW}[3/4] 修复 Flutter 管理后台依赖...${NC}"
if [ -f "dacong-admin/pubspec.yaml" ]; then
    if command -v flutter &> /dev/null; then
        cd dacong-admin

        # 备份
        cp pubspec.yaml pubspec.yaml.backup

        echo "更新 Flutter 依赖..."
        flutter pub upgrade --major-versions 2>/dev/null || flutter pub upgrade || true

        # 测试构建
        if flutter pub get > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Flutter 管理后台依赖更新完成${NC}"
            ((FIXED_COUNT++))
        else
            echo -e "${RED}✗ Flutter 依赖更新失败，恢复备份${NC}"
            mv pubspec.yaml.backup pubspec.yaml
            ((FAILED_COUNT++))
        fi

        cd ..
    else
        echo -e "${YELLOW}⚠ Flutter 未安装，跳过${NC}"
    fi
else
    echo -e "${RED}✗ 未找到 dacong-admin/pubspec.yaml${NC}"
fi
echo ""

# ==========================================
# 4. 修复 NPM 依赖
# ==========================================
echo -e "${YELLOW}[4/4] 修复 NPM 依赖漏洞...${NC}"
if [ -f "dacong-console/package.json" ]; then
    if command -v npm &> /dev/null; then
        cd dacong-console

        # 备份
        cp package.json package.json.backup
        cp package-lock.json package-lock.json.backup 2>/dev/null || true

        echo "运行 npm audit fix..."
        npm audit fix --force 2>/dev/null || npm audit fix || true

        # 测试安装
        if npm install --dry-run > /dev/null 2>&1; then
            echo -e "${GREEN}✓ NPM 依赖修复完成${NC}"
            ((FIXED_COUNT++))
        else
            echo -e "${RED}✗ NPM 依赖修复失败，恢复备份${NC}"
            mv package.json.backup package.json
            mv package-lock.json.backup package-lock.json 2>/dev/null || true
            ((FAILED_COUNT++))
        fi

        cd ..
    else
        echo -e "${YELLOW}⚠ NPM 未安装，跳过${NC}"
    fi
else
    echo -e "${RED}✗ 未找到 dacong-console/package.json${NC}"
fi
echo ""

# ==========================================
# 汇总报告
# ==========================================
echo "=========================================="
echo -e "${GREEN}修复完成！${NC}"
echo "=========================================="
echo ""
echo "修复统计："
echo "  ✓ 成功修复: $FIXED_COUNT 项"
echo "  ✗ 修复失败: $FAILED_COUNT 项"
echo ""

if [ $FIXED_COUNT -gt 0 ]; then
    echo "下一步："
    echo "1. 运行测试确保功能正常"
    echo "2. 再次运行安全扫描验证修复"
    echo "3. 提交更改到版本控制"
    echo ""
    echo "提交命令："
    echo "  git add ."
    echo "  git commit -m 'fix: 修复依赖安全漏洞'"
    echo "  git push"
fi

if [ $FAILED_COUNT -gt 0 ]; then
    echo -e "${YELLOW}警告: 部分修复失败，请手动检查${NC}"
fi
echo ""
