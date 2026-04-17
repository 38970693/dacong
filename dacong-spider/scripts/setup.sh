#!/bin/bash
# DaCong Spider 开发环境配置脚本 (Linux/Mac)

set -e

echo "=================================="
echo "DaCong Spider 环境配置"
echo "=================================="

# 1. 检查 Python 版本
echo ""
echo "[1/6] 检查 Python 版本..."
if ! command -v python3 &> /dev/null; then
    echo "❌ 错误: 未找到 python3"
    echo "请先安装 Python 3.11 或更高版本"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
REQUIRED_VERSION="3.11"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "❌ 错误: Python 版本过低 (当前: $PYTHON_VERSION, 需要: >= $REQUIRED_VERSION)"
    exit 1
fi

echo "✅ Python 版本: $PYTHON_VERSION"

# 2. 创建虚拟环境
echo ""
echo "[2/6] 创建虚拟环境..."
if [ -d "venv" ]; then
    echo "⚠️  虚拟环境已存在，跳过创建"
else
    python3 -m venv venv
    echo "✅ 虚拟环境创建成功"
fi

# 3. 激活虚拟环境
echo ""
echo "[3/6] 激活虚拟环境..."
source venv/bin/activate
echo "✅ 虚拟环境已激活"

# 4. 升级 pip
echo ""
echo "[4/6] 升级 pip..."
pip install --upgrade pip > /dev/null 2>&1
echo "✅ pip 已升级到最新版本"

# 5. 安装依赖
echo ""
echo "[5/6] 安装依赖包..."
pip install -r requirements.txt
echo "✅ 依赖包安装完成"

# 6. 配置环境变量
echo ""
echo "[6/6] 配置环境变量..."
if [ -f ".env" ]; then
    echo "⚠️  .env 文件已存在，跳过复制"
else
    cp .env.example .env
    echo "✅ 已创建 .env 文件"
    echo ""
    echo "⚠️  请编辑 .env 文件，填入真实的配置值："
    echo "   - SUPABASE_URL"
    echo "   - SUPABASE_SERVICE_ROLE_KEY"
    echo "   - GITHUB_TOKEN (可选，用于提高 API 限额)"
    echo "   - 其他 API 密钥（根据需要）"
fi

# 7. 创建日志目录
echo ""
echo "创建日志目录..."
mkdir -p logs
echo "✅ 日志目录已创建"

# 8. 验证配置
echo ""
echo "=================================="
echo "环境配置完成！"
echo "=================================="
echo ""
echo "下一步："
echo "1. 编辑 .env 文件，填入配置"
echo "2. 激活虚拟环境: source venv/bin/activate"
echo "3. 运行测试: pytest"
echo "4. 启动爬虫: python main.py"
echo ""
echo "更多信息请查看 README.md"
