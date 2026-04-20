# 启动说明

## 问题：浏览器界面空白

原因：Flutter 应用需要 Supabase 配置才能启动，但启动时没有传入环境变量。

## 解决方案

### 方法 1：使用启动脚本（推荐）

1. 打开 `dacong-admin/start-dev-with-config.bat`
2. 将 `SUPABASE_ANON_KEY` 中的 `placeholder` 替换为真实的 anon key
3. 双击运行脚本

### 方法 2：手动启动

```bash
cd dacong-admin

flutter run -d chrome \
  --dart-define=DEV_MODE=true \
  --dart-define=SUPABASE_URL=https://twrxnqrisplmetbceyqm.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=你的真实anon_key
```

### 获取 SUPABASE_ANON_KEY

1. 登录 Supabase Dashboard: https://supabase.com/dashboard
2. 选择项目 `twrxnqrisplmetbceyqm`
3. 进入 Settings > API
4. 复制 `anon` `public` key

## 验证启动成功

启动后应该看到：
```
✓ Supabase init completed
✓ Flutter DevTools debugger available
```

然后浏览器会自动打开登录页面，显示：
- 邮箱输入框
- 密码输入框
- 登录按钮
- 🟠 开发模式进入按钮
