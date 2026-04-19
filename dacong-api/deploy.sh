#!/bin/bash

echo "🚀 DaCong API 部署脚本"
echo "===================="

# 检查 Supabase CLI
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI 未安装"
    echo "请运行: npm install -g supabase"
    exit 1
fi

echo "✅ Supabase CLI 已安装"

# 检查环境变量
if [ ! -f .env ]; then
    echo "⚠️  .env 文件不存在，从 .env.example 复制"
    cp .env.example .env
    echo "📝 请编辑 .env 文件填写实际配置"
    exit 1
fi

echo "✅ 环境变量配置存在"

# 应用数据库迁移
echo ""
echo "📦 步骤 1: 应用数据库迁移"
echo "------------------------"
cd supabase
supabase db push --dry-run

read -p "确认应用迁移？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    supabase db push
    echo "✅ 数据库迁移完成"
else
    echo "⏭️  跳过数据库迁移"
fi

# 部署 Edge Functions
echo ""
echo "🔧 步骤 2: 部署 Edge Functions"
echo "----------------------------"
echo "新增函数列表:"
echo "  - auth-register, auth-login, auth-logout"
echo "  - auth-refresh, auth-reset-password, auth-change-password, auth-verify-email"
echo "  - favorites-add, favorites-remove, favorites-check"
echo "  - admin-users-list, admin-users-ban, admin-users-unban"
echo "  - admin-audit-logs, admin-stats, admin-batch-approve, admin-batch-delete"

read -p "部署所有函数？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd functions
    
    # 部署认证函数
    echo "部署认证函数..."
    for func in auth-register auth-login auth-logout auth-refresh auth-reset-password auth-change-password auth-verify-email; do
        echo "  部署 $func..."
        supabase functions deploy $func
    done
    
    # 部署收藏函数
    echo "部署收藏函数..."
    for func in favorites-add favorites-remove favorites-check; do
        echo "  部署 $func..."
        supabase functions deploy $func
    done
    
    # 部署管理函数
    echo "部署管理函数..."
    for func in admin-users-list admin-users-ban admin-users-unban admin-audit-logs admin-stats admin-batch-approve admin-batch-delete; do
        echo "  部署 $func..."
        supabase functions deploy $func
    done
    
    echo "✅ 所有函数部署完成"
else
    echo "⏭️  跳过函数部署"
fi

# 运行测试
echo ""
echo "🧪 步骤 3: 运行测试"
echo "------------------"
read -p "运行测试？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd tests
    deno test --allow-net --allow-env --allow-read
    echo "✅ 测试完成"
else
    echo "⏭️  跳过测试"
fi

echo ""
echo "🎉 部署完成！"
echo ""
echo "📋 后续步骤:"
echo "1. 创建首个管理员账号（参考 docs/DEPLOYMENT.md）"
echo "2. 配置函数环境变量: supabase secrets set KEY=VALUE"
echo "3. 验证 API 端点: curl https://your-project.supabase.co/functions/v1/auth-login"
echo ""
