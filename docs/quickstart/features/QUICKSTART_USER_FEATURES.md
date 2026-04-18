# 用户功能快速开始指南

## 快速部署

### 1. 后端部署（5分钟）

```bash
# 进入 API 目录
cd dacong-api

# 确保数据库迁移已执行
supabase db push

# 部署 Edge Functions
supabase functions deploy toggle-favorite
supabase functions deploy get-favorites

# 验证部署
supabase functions list
```

### 2. 前端构建（3分钟）

```bash
# 进入客户端目录
cd dacong-client

# 生成代码
dart run build_runner build --delete-conflicting-outputs

# 运行应用
flutter run
```

## 功能测试

### 测试注册登录

1. **注册新用户**
   ```
   邮箱: test@example.com
   密码: Test1234
   ```

2. **登录**
   - 使用注册的邮箱和密码登录
   - 验证登录成功跳转到首页

3. **密码重置**
   - 点击"忘记密码"
   - 输入邮箱
   - 检查邮件收件箱

### 测试收藏功能

1. **添加收藏**
   - 浏览内容列表
   - 点击收藏按钮
   - 验证按钮状态变化

2. **查看收藏列表**
   - 进入"我的收藏"页面
   - 验证收藏内容显示
   - 测试下拉刷新

3. **取消收藏**
   - 在收藏列表中点击取消收藏
   - 验证内容从列表中移除

### 测试用户资料

1. **编辑资料**
   - 进入"编辑资料"页面
   - 修改用户名和个人简介
   - 保存并验证更新成功

## API 测试

### 使用 curl 测试

```bash
# 获取访问令牌（登录后从浏览器开发者工具获取）
TOKEN="your_access_token"

# 测试切换收藏
curl -X POST https://your-project.supabase.co/functions/v1/toggle-favorite \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content_id": "uuid-here"}'

# 测试获取收藏列表
curl -X GET "https://your-project.supabase.co/functions/v1/get-favorites?page=1&limit=20" \
  -H "Authorization: Bearer $TOKEN"
```

## 常见问题

### Q: 注册后没有收到验证邮件？
A: 检查 Supabase 项目的邮件配置，确保 SMTP 设置正确。

### Q: 收藏功能报 401 错误？
A: 确保用户已登录，且 Authorization header 包含有效的访问令牌。

### Q: 收藏列表为空？
A: 检查数据库中 favorites 表是否有数据，验证 RLS 策略是否正确。

### Q: 头像上传功能在哪里？
A: 头像上传功能需要先配置 Supabase Storage，目前标记为待实现。

## 下一步

1. 配置 Supabase Storage 实现头像上传
2. 实现内容详情页跳转
3. 添加收藏列表搜索和筛选
4. 编写单元测试和集成测试
5. 配置 CI/CD 自动部署

## 技术支持

遇到问题？查看完整文档：`USER_AUTH_FAVORITES_IMPLEMENTATION.md`
