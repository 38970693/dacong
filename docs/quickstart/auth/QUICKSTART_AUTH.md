# 用户认证功能 - 快速启动指南

## 前置条件

1. Flutter SDK 已安装（3.8.0+）
2. Supabase 项目已创建
3. 已配置 Supabase Auth

## 快速开始

### 1. 配置环境变量

在 `dacong-client/.env` 文件中配置：

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

或者在 `lib/core/constants/app_constants.dart` 中直接配置：

```dart
static const String supabaseUrl = 'https://your-project.supabase.co';
static const String supabaseAnonKey = 'your-anon-key';
```

### 2. 安装依赖

```bash
cd dacong-client
flutter pub get
```

### 3. 生成代码

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. 运行应用

```bash
flutter run
```

## 测试认证流程

### 注册新用户

1. 启动应用后，导航到注册页面：
   ```
   /auth/register
   ```

2. 填写表单：
   - 邮箱：test@example.com
   - 用户名：testuser（可选）
   - 密码：Test1234（至少8字符，包含大小写字母和数字）
   - 确认密码：Test1234
   - 勾选用户协议

3. 点击"注册"按钮

4. 查收验证邮件（检查垃圾邮件文件夹）

### 登录

1. 导航到登录页面：
   ```
   /auth/login
   ```

2. 输入邮箱和密码

3. 点击"登录"按钮

4. 登录成功后会跳转到首页

### 密码重置

1. 在登录页面点击"忘记密码？"

2. 输入注册时使用的邮箱

3. 点击"发送重置链接"

4. 查收邮件并点击重置链接

5. 在 Supabase 提供的页面中设置新密码

### 编辑资料

1. 登录后，导航到资料编辑页面：
   ```
   /user/profile/edit
   ```

2. 修改用户名或个人简介

3. 点击右上角的"保存"按钮

## 在代码中使用认证

### 获取 AuthBloc

```dart
import 'package:dacong_client/core/di/injection.dart';
import 'package:dacong_client/presentation/blocs/auth/auth_bloc.dart';

final authBloc = getIt<AuthBloc>();
```

### 监听认证状态

```dart
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    return state.when(
      initial: () => Text('初始化中...'),
      loading: () => CircularProgressIndicator(),
      authenticated: (user) => Text('欢迎, ${user.username ?? user.email}'),
      unauthenticated: () => Text('请登录'),
      error: (message) => Text('错误: $message'),
    );
  },
)
```

### 触发登录

```dart
context.read<AuthBloc>().add(
  AuthEvent.loginRequested(
    email: 'user@example.com',
    password: 'password123',
  ),
);
```

### 触发注册

```dart
context.read<AuthBloc>().add(
  AuthEvent.registerRequested(
    email: 'user@example.com',
    password: 'SecurePass123',
    username: 'username',
  ),
);
```

### 触发登出

```dart
context.read<AuthBloc>().add(
  const AuthEvent.logoutRequested(),
);
```

### 更新资料

```dart
context.read<AuthBloc>().add(
  AuthEvent.profileUpdateRequested(
    username: 'new_username',
    bio: 'My new bio',
  ),
);
```

## 路由导航

### 使用 GoRouter 导航

```dart
import 'package:go_router/go_router.dart';

// 跳转到登录页面
context.push('/auth/login');

// 跳转到注册页面
context.push('/auth/register');

// 跳转到密码重置页面
context.push('/auth/reset-password');

// 跳转到资料编辑页面
context.push('/user/profile/edit');

// 返回上一页
context.pop();

// 替换当前页面（用于登录后跳转）
context.go('/');
```

## 常见问题

### Q: 注册后没有收到验证邮件？
A: 
1. 检查垃圾邮件文件夹
2. 确认 Supabase Email 配置正确
3. 检查 Supabase Dashboard 中的 Email Templates

### Q: 登录失败提示"Invalid login credentials"？
A: 
1. 确认邮箱和密码正确
2. 检查账户是否已注册
3. 查看 Supabase Dashboard 的 Auth 日志

### Q: 如何自定义邮件模板？
A: 
1. 登录 Supabase Dashboard
2. 进入 Authentication > Email Templates
3. 编辑相应的模板

### Q: 如何启用邮箱验证强制？
A: 
1. 登录 Supabase Dashboard
2. 进入 Authentication > Settings
3. 启用 "Confirm email" 选项

### Q: 密码强度要求是什么？
A: 
- 至少 8 个字符
- 至少包含一个大写字母
- 至少包含一个小写字母
- 至少包含一个数字

## 调试技巧

### 查看 Supabase 日志

```dart
// 在 main.dart 中启用调试日志
await Supabase.initialize(
  url: AppConstants.supabaseUrl,
  anonKey: AppConstants.supabaseAnonKey,
  debug: true, // 启用调试模式
);
```

### 查看 Bloc 状态变化

```dart
BlocObserver 可以帮助你追踪所有 Bloc 事件和状态变化
```

### 使用 Flutter DevTools

```bash
flutter run --observatory-port=8888
```

然后在浏览器中打开 DevTools 查看网络请求和状态。

## 下一步

1. 实现头像上传功能
2. 添加第三方登录（Google、Apple）
3. 实现双因素认证
4. 添加单元测试和集成测试
5. 优化错误提示和用户体验

## 相关文档

- [完整功能文档](./docs/features/USER_AUTH.md)
- [实现总结](./P1_USER_AUTH_IMPLEMENTATION.md)
- [Supabase Auth 文档](https://supabase.com/docs/guides/auth)
- [Flutter Bloc 文档](https://bloclibrary.dev/)

## 技术支持

如有问题，请查看：
1. `docs/features/USER_AUTH.md` - 完整文档
2. Supabase Dashboard - Auth 日志
3. Flutter DevTools - 网络和状态调试
