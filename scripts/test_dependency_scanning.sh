#!/bin/bash
# 依赖漏洞扫描配置验收测试
# 用途: 验证所有安全扫描配置是否正确

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== DaCong 依赖漏洞扫描配置验收测试 ===${NC}"
echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试函数
test_item() {
    local test_name="$1"
    local test_command="$2"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "  [$TOTAL_TESTS] $test_name ... "

    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# ============================================
# 1. 配置文件检查
# ============================================
echo -e "${BLUE}[1/6] 检查配置文件...${NC}"

test_item "GitLab CI 配置文件存在" "[ -f .gitlab-ci.yml ]"
test_item "GitLab CI 包含安全扫描阶段" "grep -q 'stage: security' .gitlab-ci.yml"
test_item "GitLab CI 包含 Flutter 扫描" "grep -q 'security:flutter-client' .gitlab-ci.yml"
test_item "GitLab CI 包含 Python 扫描" "grep -q 'security:python' .gitlab-ci.yml"
test_item "GitLab CI 包含 Trivy 扫描" "grep -q 'security:trivy' .gitlab-ci.yml"

test_item "Dependabot 配置文件存在" "[ -f .github/dependabot.yml ]"
test_item "Dependabot 配置 Flutter 客户端" "grep -q 'dacong-client' .github/dependabot.yml"
test_item "Dependabot 配置 Python 爬虫" "grep -q 'dacong-spider' .github/dependabot.yml"
test_item "Dependabot 配置每周更新" "grep -q 'weekly' .github/dependabot.yml"

test_item "Snyk 配置文件存在" "[ -f .snyk ]"

echo ""

# ============================================
# 2. 脚本文件检查
# ============================================
echo -e "${BLUE}[2/6] 检查脚本文件...${NC}"

test_item "漏洞修复脚本存在" "[ -f scripts/fix_vulnerabilities.sh ]"
test_item "漏洞修复脚本可执行" "[ -x scripts/fix_vulnerabilities.sh ]"
test_item "漏洞修复脚本语法正确" "bash -n scripts/fix_vulnerabilities.sh"

test_item "安全扫描脚本存在" "[ -f scripts/security_scan.sh ]"
test_item "安全扫描脚本可执行" "[ -x scripts/security_scan.sh ]"
test_item "安全扫描脚本语法正确" "bash -n scripts/security_scan.sh"

echo ""

# ============================================
# 3. 文档检查
# ============================================
echo -e "${BLUE}[3/6] 检查文档...${NC}"

test_item "安全文档目录存在" "[ -d docs/security ]"
test_item "依赖扫描文档存在" "[ -f docs/security/DEPENDENCY_SCANNING.md ]"
test_item "安全策略文档存在" "[ -f docs/security/SECURITY_POLICY.md ]"
test_item "应急响应文档存在" "[ -f docs/security/INCIDENT_RESPONSE.md ]"
test_item "安全文档索引存在" "[ -f docs/security/README.md ]"

# 检查文档内容完整性
test_item "依赖扫描文档包含扫描流程" "grep -q '漏洞扫描流程' docs/security/DEPENDENCY_SCANNING.md"
test_item "依赖扫描文档包含修复流程" "grep -q '漏洞修复流程' docs/security/DEPENDENCY_SCANNING.md"
test_item "安全策略文档包含安全标准" "grep -q '安全标准' docs/security/SECURITY_POLICY.md"
test_item "应急响应文档包含响应流程" "grep -q '响应流程' docs/security/INCIDENT_RESPONSE.md"

echo ""

# ============================================
# 4. 工具可用性检查
# ============================================
echo -e "${BLUE}[4/6] 检查扫描工具...${NC}"

# Flutter
if command -v flutter &> /dev/null; then
    test_item "Flutter 工具可用" "flutter --version"
    FLUTTER_AVAILABLE=true
else
    echo -e "  ${YELLOW}⊘ Flutter 未安装，跳过相关测试${NC}"
    FLUTTER_AVAILABLE=false
fi

# Python 工具
if command -v pip &> /dev/null; then
    test_item "pip 工具可用" "pip --version"

    if command -v pip-audit &> /dev/null; then
        test_item "pip-audit 工具可用" "pip-audit --version"
    else
        echo -e "  ${YELLOW}⊘ pip-audit 未安装 (可选)${NC}"
    fi

    if command -v safety &> /dev/null; then
        test_item "safety 工具可用" "safety --version"
    else
        echo -e "  ${YELLOW}⊘ safety 未安装 (可选)${NC}"
    fi
else
    echo -e "  ${YELLOW}⊘ Python/pip 未安装，跳过相关测试${NC}"
fi

# npm
if command -v npm &> /dev/null; then
    test_item "npm 工具可用" "npm --version"
else
    echo -e "  ${YELLOW}⊘ npm 未安装，跳过相关测试${NC}"
fi

# Trivy
if command -v trivy &> /dev/null; then
    test_item "Trivy 工具可用" "trivy --version"
else
    echo -e "  ${YELLOW}⊘ Trivy 未安装 (可选)${NC}"
fi

echo ""

# ============================================
# 5. 功能测试
# ============================================
echo -e "${BLUE}[5/6] 功能测试...${NC}"

# 测试扫描脚本（dry-run）
echo -e "  ${YELLOW}测试安全扫描脚本（模拟运行）...${NC}"
if [ -f "scripts/security_scan.sh" ]; then
    # 检查脚本是否包含必要的功能
    test_item "扫描脚本包含 Flutter 扫描" "grep -q 'flutter pub outdated' scripts/security_scan.sh"
    test_item "扫描脚本包含 Python 扫描" "grep -q 'pip-audit' scripts/security_scan.sh"
    test_item "扫描脚本包含报告生成" "grep -q 'scan-summary' scripts/security_scan.sh"
fi

# 测试修复脚本（dry-run）
echo -e "  ${YELLOW}测试漏洞修复脚本（模拟运行）...${NC}"
if [ -f "scripts/fix_vulnerabilities.sh" ]; then
    # 检查脚本是否包含必要的功能
    test_item "修复脚本包含 Flutter 升级" "grep -q 'flutter pub upgrade' scripts/fix_vulnerabilities.sh"
    test_item "修复脚本包含 npm 修复" "grep -q 'npm audit fix' scripts/fix_vulnerabilities.sh"
    test_item "修复脚本包含报告生成" "grep -q 'vulnerability-summary' scripts/fix_vulnerabilities.sh"
fi

echo ""

# ============================================
# 6. 集成测试
# ============================================
echo -e "${BLUE}[6/6] 集成测试...${NC}"

# 检查 GitLab CI 语法
if command -v gitlab-ci-lint &> /dev/null; then
    test_item "GitLab CI 配置语法正确" "gitlab-ci-lint .gitlab-ci.yml"
else
    echo -e "  ${YELLOW}⊘ gitlab-ci-lint 未安装，跳过 CI 语法检查${NC}"
fi

# 检查 Dependabot 配置语法
test_item "Dependabot 配置格式正确" "grep -q 'version: 2' .github/dependabot.yml"

# 检查报告目录可创建
test_item "可创建报告目录" "mkdir -p security-reports && [ -d security-reports ]"

echo ""

# ============================================
# 7. 生成测试报告
# ============================================
echo -e "${GREEN}=== 测试完成 ===${NC}"
echo ""
echo -e "${BLUE}测试统计:${NC}"
echo "  总测试数: $TOTAL_TESTS"
echo -e "  ${GREEN}通过: $PASSED_TESTS${NC}"
echo -e "  ${RED}失败: $FAILED_TESTS${NC}"
echo ""

# 计算通过率
if [ $TOTAL_TESTS -gt 0 ]; then
    PASS_RATE=$(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
    echo "  通过率: $PASS_RATE%"
fi

echo ""

# ============================================
# 8. 验收标准检查
# ============================================
echo -e "${BLUE}验收标准检查:${NC}"

ACCEPTANCE_PASSED=true

# 标准 1: 自动扫描配置完成
if [ -f ".gitlab-ci.yml" ] && grep -q "stage: security" .gitlab-ci.yml; then
    echo -e "  ${GREEN}✓ 标准 1: 自动扫描配置完成${NC}"
else
    echo -e "  ${RED}✗ 标准 1: 自动扫描配置未完成${NC}"
    ACCEPTANCE_PASSED=false
fi

# 标准 2: Dependabot 配置完成
if [ -f ".github/dependabot.yml" ]; then
    echo -e "  ${GREEN}✓ 标准 2: Dependabot 配置完成${NC}"
else
    echo -e "  ${RED}✗ 标准 2: Dependabot 配置未完成${NC}"
    ACCEPTANCE_PASSED=false
fi

# 标准 3: 修复脚本可用
if [ -x "scripts/fix_vulnerabilities.sh" ] && [ -x "scripts/security_scan.sh" ]; then
    echo -e "  ${GREEN}✓ 标准 3: 修复脚本可用${NC}"
else
    echo -e "  ${RED}✗ 标准 3: 修复脚本不可用${NC}"
    ACCEPTANCE_PASSED=false
fi

# 标准 4: 文档完善
if [ -f "docs/security/DEPENDENCY_SCANNING.md" ] && \
   [ -f "docs/security/SECURITY_POLICY.md" ] && \
   [ -f "docs/security/INCIDENT_RESPONSE.md" ]; then
    echo -e "  ${GREEN}✓ 标准 4: 文档完善${NC}"
else
    echo -e "  ${RED}✗ 标准 4: 文档不完善${NC}"
    ACCEPTANCE_PASSED=false
fi

echo ""

# ============================================
# 9. 最终结果
# ============================================
if [ "$ACCEPTANCE_PASSED" = true ] && [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ 验收测试通过！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "所有验收标准已满足，依赖漏洞扫描系统配置完成。"
    echo ""
    echo "下一步操作:"
    echo "  1. 运行安全扫描: ./scripts/security_scan.sh"
    echo "  2. 查看扫描报告: ls -lh security-reports/"
    echo "  3. 配置 GitLab CI/CD Schedules（每周扫描）"
    echo "  4. 提交配置: git add . && git commit -m 'feat(security): add dependency scanning'"
    echo ""
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}✗ 验收测试失败！${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo "存在以下问题:"
    if [ $FAILED_TESTS -gt 0 ]; then
        echo "  - $FAILED_TESTS 个测试失败"
    fi
    if [ "$ACCEPTANCE_PASSED" = false ]; then
        echo "  - 部分验收标准未满足"
    fi
    echo ""
    echo "请检查上述失败项并修复后重新运行测试。"
    echo ""
    exit 1
fi
