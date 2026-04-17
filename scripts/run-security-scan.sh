#!/bin/bash
# 首次安全扫描脚本
# 用途：在本地或 CI 环境中运行完整的安全扫描

set -e

echo "=========================================="
echo "DaCong 项目安全扫描"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 创建报告目录
REPORT_DIR="security-reports"
mkdir -p "$REPORT_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "报告将保存到: $REPORT_DIR/"
echo ""

# ==========================================
# 1. Python 依赖扫描
# ==========================================
echo -e "${YELLOW}[1/5] 扫描 Python 依赖漏洞...${NC}"
if [ -f "dacong-spider/requirements.txt" ]; then
    echo "安装扫描工具..."
    pip install --quiet pip-audit safety 2>/dev/null || true

    echo "运行 pip-audit..."
    pip-audit --requirement dacong-spider/requirements.txt \
        --format json \
        --output "$REPORT_DIR/pip-audit-$TIMESTAMP.json" 2>/dev/null || true

    pip-audit --requirement dacong-spider/requirements.txt || true

    echo "运行 safety..."
    safety check --file dacong-spider/requirements.txt \
        --json \
        --output "$REPORT_DIR/safety-$TIMESTAMP.json" 2>/dev/null || true

    safety check --file dacong-spider/requirements.txt || true
    echo -e "${GREEN}✓ Python 扫描完成${NC}"
else
    echo -e "${RED}✗ 未找到 dacong-spider/requirements.txt${NC}"
fi
echo ""

# ==========================================
# 2. Flutter 客户端依赖扫描
# ==========================================
echo -e "${YELLOW}[2/5] 扫描 Flutter 客户端依赖...${NC}"
if [ -f "dacong-client/pubspec.yaml" ]; then
    if command -v flutter &> /dev/null; then
        cd dacong-client
        flutter pub get > /dev/null 2>&1 || true
        flutter pub outdated --json > "../$REPORT_DIR/flutter-client-outdated-$TIMESTAMP.json" 2>/dev/null || true
        flutter pub outdated || true
        cd ..
        echo -e "${GREEN}✓ Flutter 客户端扫描完成${NC}"
    else
        echo -e "${YELLOW}⚠ Flutter 未安装，跳过${NC}"
    fi
else
    echo -e "${RED}✗ 未找到 dacong-client/pubspec.yaml${NC}"
fi
echo ""

# ==========================================
# 3. Flutter 管理后台依赖扫描
# ==========================================
echo -e "${YELLOW}[3/5] 扫描 Flutter 管理后台依赖...${NC}"
if [ -f "dacong-admin/pubspec.yaml" ]; then
    if command -v flutter &> /dev/null; then
        cd dacong-admin
        flutter pub get > /dev/null 2>&1 || true
        flutter pub outdated --json > "../$REPORT_DIR/flutter-admin-outdated-$TIMESTAMP.json" 2>/dev/null || true
        flutter pub outdated || true
        cd ..
        echo -e "${GREEN}✓ Flutter 管理后台扫描完成${NC}"
    else
        echo -e "${YELLOW}⚠ Flutter 未安装，跳过${NC}"
    fi
else
    echo -e "${RED}✗ 未找到 dacong-admin/pubspec.yaml${NC}"
fi
echo ""

# ==========================================
# 4. NPM 依赖扫描
# ==========================================
echo -e "${YELLOW}[4/5] 扫描 NPM 依赖漏洞...${NC}"
if [ -f "dacong-console/package.json" ]; then
    if command -v npm &> /dev/null; then
        cd dacong-console
        npm audit --audit-level=moderate --json > "../$REPORT_DIR/npm-audit-$TIMESTAMP.json" 2>/dev/null || true
        npm audit --audit-level=moderate || true
        cd ..
        echo -e "${GREEN}✓ NPM 扫描完成${NC}"
    else
        echo -e "${YELLOW}⚠ NPM 未安装，跳过${NC}"
    fi
else
    echo -e "${RED}✗ 未找到 dacong-console/package.json${NC}"
fi
echo ""

# ==========================================
# 5. Trivy 全项目扫描
# ==========================================
echo -e "${YELLOW}[5/5] 运行 Trivy 容器和依赖扫描...${NC}"
if command -v trivy &> /dev/null; then
    trivy fs --security-checks vuln \
        --severity HIGH,CRITICAL \
        --format json \
        --output "$REPORT_DIR/trivy-$TIMESTAMP.json" \
        . 2>/dev/null || true

    trivy fs --security-checks vuln \
        --severity HIGH,CRITICAL \
        . || true

    echo -e "${GREEN}✓ Trivy 扫描完成${NC}"
else
    echo -e "${YELLOW}⚠ Trivy 未安装，跳过${NC}"
    echo "安装 Trivy: https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
fi
echo ""

# ==========================================
# 6. 密钥泄露扫描
# ==========================================
echo -e "${YELLOW}[6/6] 扫描密钥泄露...${NC}"
if [ -f "dacong-api/scripts/scan_for_secrets.sh" ]; then
    cd dacong-api
    chmod +x scripts/scan_for_secrets.sh
    ./scripts/scan_for_secrets.sh --ci > "../$REPORT_DIR/secrets-scan-$TIMESTAMP.txt" 2>&1 || true
    cd ..
    echo -e "${GREEN}✓ 密钥扫描完成${NC}"
else
    echo -e "${YELLOW}⚠ 密钥扫描脚本未找到${NC}"
fi
echo ""

# ==========================================
# 生成汇总报告
# ==========================================
echo "=========================================="
echo -e "${GREEN}扫描完成！${NC}"
echo "=========================================="
echo ""
echo "报告位置: $REPORT_DIR/"
echo ""
echo "生成的报告文件："
ls -lh "$REPORT_DIR/" | grep "$TIMESTAMP" || ls -lh "$REPORT_DIR/" | tail -10
echo ""
echo "下一步："
echo "1. 查看报告中的 HIGH 和 CRITICAL 漏洞"
echo "2. 运行 'bash scripts/fix-vulnerabilities.sh' 修复漏洞"
echo "3. 提交修复到版本控制"
echo ""
