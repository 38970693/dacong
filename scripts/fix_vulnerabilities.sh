#!/bin/bash
# 依赖漏洞修复脚本
# 用途: 自动检查和修复项目中的依赖漏洞

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== DaCong 依赖漏洞修复工具 ===${NC}"
echo "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# 创建报告目录
REPORT_DIR="$PROJECT_ROOT/security-reports"
mkdir -p "$REPORT_DIR"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

# ============================================
# 1. Flutter 客户端依赖检查和更新
# ============================================
echo -e "${YELLOW}[1/4] 检查 Flutter 客户端依赖...${NC}"
if [ -d "dacong-client" ]; then
    cd dacong-client

    echo "  → 获取当前依赖..."
    flutter pub get

    echo "  → 检查过期依赖..."
    flutter pub outdated > "$REPORT_DIR/flutter-client-outdated-$TIMESTAMP.txt" 2>&1 || true

    echo "  → 升级依赖..."
    flutter pub upgrade

    echo "  → 验证构建..."
    flutter analyze --no-fatal-infos || echo -e "${RED}  ⚠ 分析发现问题，请手动检查${NC}"

    cd "$PROJECT_ROOT"
    echo -e "${GREEN}  ✓ Flutter 客户端依赖检查完成${NC}"
else
    echo -e "${YELLOW}  ⊘ 跳过: dacong-client 目录不存在${NC}"
fi
echo ""

# ============================================
# 2. Flutter 管理后台依赖检查和更新
# ============================================
echo -e "${YELLOW}[2/4] 检查 Flutter 管理后台依赖...${NC}"
if [ -d "dacong-admin" ]; then
    cd dacong-admin

    echo "  → 获取当前依赖..."
    flutter pub get

    echo "  → 检查过期依赖..."
    flutter pub outdated > "$REPORT_DIR/flutter-admin-outdated-$TIMESTAMP.txt" 2>&1 || true

    echo "  → 升级依赖..."
    flutter pub upgrade

    echo "  → 验证构建..."
    flutter analyze --no-fatal-infos || echo -e "${RED}  ⚠ 分析发现问题，请手动检查${NC}"

    cd "$PROJECT_ROOT"
    echo -e "${GREEN}  ✓ Flutter 管理后台依赖检查完成${NC}"
else
    echo -e "${YELLOW}  ⊘ 跳过: dacong-admin 目录不存在${NC}"
fi
echo ""

# ============================================
# 3. Python 爬虫依赖检查和更新
# ============================================
echo -e "${YELLOW}[3/4] 检查 Python 爬虫依赖...${NC}"
if [ -d "dacong-spider" ] && [ -f "dacong-spider/requirements.txt" ]; then
    cd dacong-spider

    echo "  → 检查过期依赖..."
    pip list --outdated > "$REPORT_DIR/python-outdated-$TIMESTAMP.txt" 2>&1 || true

    echo "  → 使用 pip-audit 扫描漏洞..."
    if command -v pip-audit &> /dev/null; then
        pip-audit --requirement requirements.txt > "$REPORT_DIR/pip-audit-$TIMESTAMP.txt" 2>&1 || true
    else
        echo "  ⚠ pip-audit 未安装，跳过漏洞扫描"
        echo "  提示: pip install pip-audit"
    fi

    echo "  → 使用 Safety 扫描已知漏洞..."
    if command -v safety &> /dev/null; then
        safety check --file requirements.txt > "$REPORT_DIR/safety-$TIMESTAMP.txt" 2>&1 || true
    else
        echo "  ⚠ safety 未安装，跳过漏洞扫描"
        echo "  提示: pip install safety"
    fi

    # 注意: 不自动升级 Python 依赖，因为可能导致破坏性变更
    echo -e "${YELLOW}  ⚠ Python 依赖需要手动审查和升级${NC}"
    echo "  提示: 查看报告后运行 'pip install --upgrade -r requirements.txt'"

    cd "$PROJECT_ROOT"
    echo -e "${GREEN}  ✓ Python 爬虫依赖检查完成${NC}"
else
    echo -e "${YELLOW}  ⊘ 跳过: dacong-spider 目录或 requirements.txt 不存在${NC}"
fi
echo ""

# ============================================
# 4. Next.js 控制台依赖检查和更新
# ============================================
echo -e "${YELLOW}[4/4] 检查 Next.js 控制台依赖...${NC}"
if [ -d "dacong-console" ] && [ -f "dacong-console/package.json" ]; then
    cd dacong-console

    echo "  → 运行 npm audit..."
    npm audit > "$REPORT_DIR/npm-audit-$TIMESTAMP.txt" 2>&1 || true

    echo "  → 自动修复可修复的漏洞..."
    npm audit fix || echo -e "${RED}  ⚠ 部分漏洞无法自动修复${NC}"

    echo "  → 检查过期依赖..."
    npm outdated > "$REPORT_DIR/npm-outdated-$TIMESTAMP.txt" 2>&1 || true

    cd "$PROJECT_ROOT"
    echo -e "${GREEN}  ✓ Next.js 控制台依赖检查完成${NC}"
else
    echo -e "${YELLOW}  ⊘ 跳过: dacong-console 目录或 package.json 不存在${NC}"
fi
echo ""

# ============================================
# 5. 生成汇总报告
# ============================================
echo -e "${YELLOW}生成汇总报告...${NC}"
SUMMARY_REPORT="$REPORT_DIR/vulnerability-summary-$TIMESTAMP.txt"

cat > "$SUMMARY_REPORT" <<EOF
===========================================
DaCong 依赖漏洞扫描汇总报告
===========================================
扫描时间: $(date '+%Y-%m-%d %H:%M:%S')
项目路径: $PROJECT_ROOT

-------------------------------------------
扫描结果文件:
-------------------------------------------
EOF

# 列出所有生成的报告
ls -lh "$REPORT_DIR"/*-$TIMESTAMP.txt 2>/dev/null | awk '{print $9}' | while read file; do
    echo "  - $(basename "$file")" >> "$SUMMARY_REPORT"
done

cat >> "$SUMMARY_REPORT" <<EOF

-------------------------------------------
修复建议:
-------------------------------------------
1. Flutter 依赖: 已自动升级，请运行测试验证
2. Python 依赖: 需手动审查报告后升级
3. npm 依赖: 已尝试自动修复，检查是否有遗留问题

-------------------------------------------
后续操作:
-------------------------------------------
1. 查看详细报告: ls -lh $REPORT_DIR/
2. 运行测试套件: ./scripts/run_all_tests.sh
3. 提交变更: git add . && git commit -m "chore(deps): fix security vulnerabilities"
4. 推送到远程: git push

-------------------------------------------
高危漏洞处理流程:
-------------------------------------------
1. 立即评估影响范围
2. 在 24 小时内修复
3. 通知相关团队
4. 更新安全文档

EOF

echo -e "${GREEN}✓ 汇总报告已生成: $SUMMARY_REPORT${NC}"
echo ""

# ============================================
# 6. 显示报告摘要
# ============================================
echo -e "${GREEN}=== 扫描完成 ===${NC}"
echo "完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "报告位置: $REPORT_DIR/"
echo ""
echo -e "${YELLOW}请查看以下报告文件:${NC}"
ls -lh "$REPORT_DIR"/*-$TIMESTAMP.txt 2>/dev/null || echo "  (无报告生成)"
echo ""
echo -e "${YELLOW}下一步操作:${NC}"
echo "  1. 查看汇总报告: cat $SUMMARY_REPORT"
echo "  2. 运行测试验证: ./scripts/run_all_tests.sh"
echo "  3. 提交修复: git add . && git commit -m 'chore(deps): fix vulnerabilities'"
echo ""
