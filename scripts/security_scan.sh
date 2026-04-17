#!/bin/bash
# 依赖漏洞扫描脚本
# 用途: 全面扫描项目依赖漏洞，生成详细报告

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== DaCong 依赖漏洞扫描工具 ===${NC}"
echo "扫描时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# 创建报告目录
REPORT_DIR="$PROJECT_ROOT/security-reports"
mkdir -p "$REPORT_DIR"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

# 漏洞计数器
TOTAL_VULNERABILITIES=0
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
LOW_COUNT=0

# ============================================
# 1. Flutter 客户端依赖扫描
# ============================================
echo -e "${BLUE}[1/5] 扫描 Flutter 客户端依赖...${NC}"
if [ -d "dacong-client" ]; then
    cd dacong-client

    echo "  → 检查过期依赖..."
    flutter pub get > /dev/null 2>&1
    flutter pub outdated --json > "$REPORT_DIR/flutter-client-scan-$TIMESTAMP.json" 2>&1 || true
    flutter pub outdated > "$REPORT_DIR/flutter-client-scan-$TIMESTAMP.txt" 2>&1 || true

    # 统计过期依赖数量
    if [ -f "$REPORT_DIR/flutter-client-scan-$TIMESTAMP.txt" ]; then
        OUTDATED_COUNT=$(grep -c "^  " "$REPORT_DIR/flutter-client-scan-$TIMESTAMP.txt" 2>/dev/null || echo "0")
        echo -e "  ${YELLOW}发现 $OUTDATED_COUNT 个过期依赖${NC}"
        TOTAL_VULNERABILITIES=$((TOTAL_VULNERABILITIES + OUTDATED_COUNT))
    fi

    cd "$PROJECT_ROOT"
    echo -e "${GREEN}  ✓ Flutter 客户端扫描完成${NC}"
else
    echo -e "${YELLOW}  ⊘ 跳过: dacong-client 目录不存在${NC}"
fi
echo ""

# ============================================
# 2. Flutter 管理后台依赖扫描
# ============================================
echo -e "${BLUE}[2/5] 扫描 Flutter 管理后台依赖...${NC}"
if [ -d "dacong-admin" ]; then
    cd dacong-admin

    echo "  → 检查过期依赖..."
    flutter pub get > /dev/null 2>&1
    flutter pub outdated --json > "$REPORT_DIR/flutter-admin-scan-$TIMESTAMP.json" 2>&1 || true
    flutter pub outdated > "$REPORT_DIR/flutter-admin-scan-$TIMESTAMP.txt" 2>&1 || true

    # 统计过期依赖数量
    if [ -f "$REPORT_DIR/flutter-admin-scan-$TIMESTAMP.txt" ]; then
        OUTDATED_COUNT=$(grep -c "^  " "$REPORT_DIR/flutter-admin-scan-$TIMESTAMP.txt" 2>/dev/null || echo "0")
        echo -e "  ${YELLOW}发现 $OUTDATED_COUNT 个过期依赖${NC}"
        TOTAL_VULNERABILITIES=$((TOTAL_VULNERABILITIES + OUTDATED_COUNT))
    fi

    cd "$PROJECT_ROOT"
    echo -e "${GREEN}  ✓ Flutter 管理后台扫描完成${NC}"
else
    echo -e "${YELLOW}  ⊘ 跳过: dacong-admin 目录不存在${NC}"
fi
echo ""

# ============================================
# 3. Python 爬虫依赖扫描
# ============================================
echo -e "${BLUE}[3/5] 扫描 Python 爬虫依赖...${NC}"
if [ -d "dacong-spider" ] && [ -f "dacong-spider/requirements.txt" ]; then
    cd dacong-spider

    echo "  → 检查过期依赖..."
    pip list --outdated > "$REPORT_DIR/python-scan-$TIMESTAMP.txt" 2>&1 || true

    echo "  → 使用 pip-audit 扫描漏洞..."
    if command -v pip-audit &> /dev/null; then
        pip-audit --requirement requirements.txt --format json --output "$REPORT_DIR/pip-audit-scan-$TIMESTAMP.json" 2>&1 || true
        pip-audit --requirement requirements.txt > "$REPORT_DIR/pip-audit-scan-$TIMESTAMP.txt" 2>&1 || true

        # 统计漏洞数量
        if [ -f "$REPORT_DIR/pip-audit-scan-$TIMESTAMP.json" ]; then
            VULN_COUNT=$(jq '.dependencies | length' "$REPORT_DIR/pip-audit-scan-$TIMESTAMP.json" 2>/dev/null || echo "0")
            echo -e "  ${YELLOW}pip-audit 发现 $VULN_COUNT 个漏洞${NC}"
            TOTAL_VULNERABILITIES=$((TOTAL_VULNERABILITIES + VULN_COUNT))
        fi
    else
        echo -e "  ${YELLOW}⚠ pip-audit 未安装，跳过漏洞扫描${NC}"
        echo "  提示: pip install pip-audit"
    fi

    echo "  → 使用 Safety 扫描已知漏洞..."
    if command -v safety &> /dev/null; then
        safety check --file requirements.txt --json --output "$REPORT_DIR/safety-scan-$TIMESTAMP.json" 2>&1 || true
        safety check --file requirements.txt > "$REPORT_DIR/safety-scan-$TIMESTAMP.txt" 2>&1 || true

        # 统计漏洞数量
        if [ -f "$REPORT_DIR/safety-scan-$TIMESTAMP.txt" ]; then
            VULN_COUNT=$(grep -c "vulnerability found" "$REPORT_DIR/safety-scan-$TIMESTAMP.txt" 2>/dev/null || echo "0")
            echo -e "  ${YELLOW}Safety 发现 $VULN_COUNT 个漏洞${NC}"
            TOTAL_VULNERABILITIES=$((TOTAL_VULNERABILITIES + VULN_COUNT))
        fi
    else
        echo -e "  ${YELLOW}⚠ safety 未安装，跳过漏洞扫描${NC}"
        echo "  提示: pip install safety"
    fi

    cd "$PROJECT_ROOT"
    echo -e "${GREEN}  ✓ Python 爬虫扫描完成${NC}"
else
    echo -e "${YELLOW}  ⊘ 跳过: dacong-spider 目录或 requirements.txt 不存在${NC}"
fi
echo ""

# ============================================
# 4. Next.js 控制台依赖扫描
# ============================================
echo -e "${BLUE}[4/5] 扫描 Next.js 控制台依赖...${NC}"
if [ -d "dacong-console" ] && [ -f "dacong-console/package.json" ]; then
    cd dacong-console

    echo "  → 运行 npm audit..."
    npm audit --json > "$REPORT_DIR/npm-audit-scan-$TIMESTAMP.json" 2>&1 || true
    npm audit > "$REPORT_DIR/npm-audit-scan-$TIMESTAMP.txt" 2>&1 || true

    # 统计漏洞数量
    if [ -f "$REPORT_DIR/npm-audit-scan-$TIMESTAMP.json" ]; then
        CRITICAL_COUNT=$(jq '.metadata.vulnerabilities.critical // 0' "$REPORT_DIR/npm-audit-scan-$TIMESTAMP.json" 2>/dev/null || echo "0")
        HIGH_COUNT=$(jq '.metadata.vulnerabilities.high // 0' "$REPORT_DIR/npm-audit-scan-$TIMESTAMP.json" 2>/dev/null || echo "0")
        MEDIUM_COUNT=$(jq '.metadata.vulnerabilities.moderate // 0' "$REPORT_DIR/npm-audit-scan-$TIMESTAMP.json" 2>/dev/null || echo "0")
        LOW_COUNT=$(jq '.metadata.vulnerabilities.low // 0' "$REPORT_DIR/npm-audit-scan-$TIMESTAMP.json" 2>/dev/null || echo "0")

        echo -e "  ${RED}严重: $CRITICAL_COUNT${NC}"
        echo -e "  ${YELLOW}高危: $HIGH_COUNT${NC}"
        echo -e "  ${YELLOW}中危: $MEDIUM_COUNT${NC}"
        echo -e "  ${BLUE}低危: $LOW_COUNT${NC}"

        TOTAL_VULNERABILITIES=$((TOTAL_VULNERABILITIES + CRITICAL_COUNT + HIGH_COUNT + MEDIUM_COUNT + LOW_COUNT))
    fi

    cd "$PROJECT_ROOT"
    echo -e "${GREEN}  ✓ Next.js 控制台扫描完成${NC}"
else
    echo -e "${YELLOW}  ⊘ 跳过: dacong-console 目录或 package.json 不存在${NC}"
fi
echo ""

# ============================================
# 5. Trivy 容器和文件系统扫描
# ============================================
echo -e "${BLUE}[5/5] 使用 Trivy 扫描容器和文件系统...${NC}"
if command -v trivy &> /dev/null; then
    echo "  → 扫描文件系统漏洞..."
    trivy fs --security-checks vuln --severity HIGH,CRITICAL --format json --output "$REPORT_DIR/trivy-scan-$TIMESTAMP.json" . 2>&1 || true
    trivy fs --security-checks vuln --severity HIGH,CRITICAL . > "$REPORT_DIR/trivy-scan-$TIMESTAMP.txt" 2>&1 || true

    # 统计漏洞数量
    if [ -f "$REPORT_DIR/trivy-scan-$TIMESTAMP.json" ]; then
        TRIVY_COUNT=$(jq '[.Results[]?.Vulnerabilities[]?] | length' "$REPORT_DIR/trivy-scan-$TIMESTAMP.json" 2>/dev/null || echo "0")
        echo -e "  ${YELLOW}Trivy 发现 $TRIVY_COUNT 个高危/严重漏洞${NC}"
        TOTAL_VULNERABILITIES=$((TOTAL_VULNERABILITIES + TRIVY_COUNT))
    fi

    echo -e "${GREEN}  ✓ Trivy 扫描完成${NC}"
else
    echo -e "${YELLOW}  ⚠ Trivy 未安装，跳过容器扫描${NC}"
    echo "  提示: https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
fi
echo ""

# ============================================
# 6. 生成汇总报告
# ============================================
echo -e "${BLUE}生成汇总报告...${NC}"
SUMMARY_REPORT="$REPORT_DIR/scan-summary-$TIMESTAMP.txt"

cat > "$SUMMARY_REPORT" <<EOF
===========================================
DaCong 依赖漏洞扫描汇总报告
===========================================
扫描时间: $(date '+%Y-%m-%d %H:%M:%S')
项目路径: $PROJECT_ROOT

-------------------------------------------
扫描统计:
-------------------------------------------
总漏洞数: $TOTAL_VULNERABILITIES
  - 严重 (Critical): $CRITICAL_COUNT
  - 高危 (High): $HIGH_COUNT
  - 中危 (Medium): $MEDIUM_COUNT
  - 低危 (Low): $LOW_COUNT

-------------------------------------------
扫描结果文件:
-------------------------------------------
EOF

# 列出所有生成的报告
ls -lh "$REPORT_DIR"/*-$TIMESTAMP.* 2>/dev/null | awk '{print $9}' | while read file; do
    echo "  - $(basename "$file")" >> "$SUMMARY_REPORT"
done

cat >> "$SUMMARY_REPORT" <<EOF

-------------------------------------------
风险评估:
-------------------------------------------
EOF

if [ $CRITICAL_COUNT -gt 0 ]; then
    echo "🔴 严重风险: 发现 $CRITICAL_COUNT 个严重漏洞，需立即修复！" >> "$SUMMARY_REPORT"
elif [ $HIGH_COUNT -gt 0 ]; then
    echo "🟠 高风险: 发现 $HIGH_COUNT 个高危漏洞，建议 24 小时内修复" >> "$SUMMARY_REPORT"
elif [ $MEDIUM_COUNT -gt 0 ]; then
    echo "🟡 中风险: 发现 $MEDIUM_COUNT 个中危漏洞，建议本周内修复" >> "$SUMMARY_REPORT"
elif [ $LOW_COUNT -gt 0 ]; then
    echo "🟢 低风险: 发现 $LOW_COUNT 个低危漏洞，可在下次迭代修复" >> "$SUMMARY_REPORT"
else
    echo "✅ 安全: 未发现已知漏洞" >> "$SUMMARY_REPORT"
fi

cat >> "$SUMMARY_REPORT" <<EOF

-------------------------------------------
修复建议:
-------------------------------------------
1. 查看详细报告: ls -lh $REPORT_DIR/
2. 运行修复脚本: ./scripts/fix_vulnerabilities.sh
3. 手动审查高危漏洞
4. 运行测试验证: ./scripts/run_all_tests.sh
5. 提交修复: git commit -m "chore(deps): fix security vulnerabilities"

-------------------------------------------
参考文档:
-------------------------------------------
- 依赖扫描文档: docs/security/DEPENDENCY_SCANNING.md
- 安全策略: docs/security/SECURITY_POLICY.md
- 应急响应流程: docs/security/INCIDENT_RESPONSE.md

EOF

echo -e "${GREEN}✓ 汇总报告已生成: $SUMMARY_REPORT${NC}"
echo ""

# ============================================
# 7. 显示扫描结果
# ============================================
echo -e "${GREEN}=== 扫描完成 ===${NC}"
echo "完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo -e "${BLUE}扫描统计:${NC}"
echo "  总漏洞数: $TOTAL_VULNERABILITIES"
if [ $CRITICAL_COUNT -gt 0 ]; then
    echo -e "  ${RED}严重: $CRITICAL_COUNT${NC}"
fi
if [ $HIGH_COUNT -gt 0 ]; then
    echo -e "  ${YELLOW}高危: $HIGH_COUNT${NC}"
fi
if [ $MEDIUM_COUNT -gt 0 ]; then
    echo -e "  ${YELLOW}中危: $MEDIUM_COUNT${NC}"
fi
if [ $LOW_COUNT -gt 0 ]; then
    echo -e "  ${BLUE}低危: $LOW_COUNT${NC}"
fi
echo ""
echo "报告位置: $REPORT_DIR/"
echo ""
echo -e "${YELLOW}下一步操作:${NC}"
echo "  1. 查看汇总报告: cat $SUMMARY_REPORT"
echo "  2. 运行修复脚本: ./scripts/fix_vulnerabilities.sh"
echo "  3. 查看详细报告: ls -lh $REPORT_DIR/"
echo ""

# 如果发现严重或高危漏洞，返回非零退出码
if [ $CRITICAL_COUNT -gt 0 ] || [ $HIGH_COUNT -gt 0 ]; then
    echo -e "${RED}⚠ 发现高危漏洞，请立即处理！${NC}"
    exit 1
fi
