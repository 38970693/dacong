# 手动部署 Edge Functions 指南

由于 Supabase CLI 遇到版本问题，需要通过 Supabase Dashboard 手动部署函数。

## 方法 1：通过 Supabase Dashboard 部署（推荐）

### 步骤：

1. **登录 Supabase Dashboard**
   - 访问：https://supabase.com/dashboard
   - 使用你的账号登录（密码：Fan03Zhou24）

2. **选择项目**
   - 项目 ref: `twrxnqrisplmetbceyqm`
   - API URL: https://twrxnqrisplmetbceyqm.supabase.co

3. **进入 Edge Functions**
   - 左侧菜单 → Edge Functions
   - 点击 "Create a new function"

4. **部署以下函数**（按优先级）：

   **高优先级（数据看板需要）：**
   - `get-realtime-stats` - 实时统计
   - `get-trend-data` - 趋势数据
   - `admin-stats` - 管理员统计

   **中优先级（其他功能）：**
   - `admin-content-management` - 内容管理
   - `admin-users-list` - 用户列表
   - `admin-comment-moderation` - 评论审核
   - `admin-audit-logs` - 审计日志

5. **部署方式**
   - 对于每个函数，复制对应文件夹中的 `index.ts` 内容
   - 粘贴到 Dashboard 的代码编辑器
   - 点击 "Deploy"

## 方法 2：修复 Supabase CLI

如果想修复 CLI 问题：

```bash
# 卸载当前版本
scoop uninstall supabase

# 重新安装
scoop install supabase

# 或者使用 npm 版本
npm install -g supabase
```

## 方法 3：使用开发模式（临时方案）

如果暂时不想部署，可以修改后端配置返回模拟数据：

1. 修改 `dacong-admin/lib/services/dashboard_service.dart`
2. 添加开发模式判断，返回模拟数据
3. 这样可以先开发前端界面，后续再连接真实 API

## 数据库表问题

错误提示 `table 'public.reports' not found`，需要创建数据库表：

1. Dashboard → SQL Editor
2. 运行迁移文件：`dacong-api/supabase/migrations/*.sql`
3. 或者手动创建缺失的表

## 需要创建的表

```sql
-- reports 表（举报/投诉）
CREATE TABLE IF NOT EXISTS public.reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id UUID REFERENCES public.posts(id),
  comment_id UUID REFERENCES public.comments(id),
  reporter_id UUID REFERENCES auth.users(id),
  reason TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

## 验证部署

部署完成后：
1. 刷新后台页面
2. 检查数据是否正常加载
3. 查看浏览器控制台是否还有错误

## 联系我

如果遇到问题，提供以下信息：
- 错误截图
- 浏览器控制台日志
- 具体操作步骤
