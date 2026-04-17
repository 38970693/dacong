# 用户认证功能文档

## 概述

DaCong 客户端的用户认证系统基于 Supabase Auth 实现，提供完整的用户注册、登录、密码重置和资料管理功能。

## 功能特性

### 1. 用户注册
- 邮箱 + 密码注册
- 可选用户名设置
- 密码强度验证（至少8个字符，包含大小写字母和数字）
- 自动发送邮箱验证邮件
- 用户协议和隐私政策确认

**路由**: `/auth/register`

**实现文件**:
- `lib/presentation/pages/auth/register_page.dart`

### 2. 用户登录
- 邮箱 + 密码登录
- 记住我功能
- 密码可见性切换
- 错误提示

**路由**: `/auth/login`

**实现文件**:
- `lib/presentation/pages/auth/login_page.dart`

### 3. 密码重置
- 通过邮箱发送重置链接
- 重置邮件发送确认
- 支持重新发送

**路由**: `/auth/reset-password`

**实现文件**:
- `lib/presentation/pages/auth/reset_password_page.dart`

### 4. 用户资料编辑
- 头像上传（待实现）
- 用户名编辑
- 个人简介编辑
- 邮箱验证状态显示
- 账户信息展示

**路由**: `/user/profile/edit`

**实现文件**:
- `lib/presentation/pages/user/profile_edit_page.dart`

## 架构设计

### Clean Architecture 分层

```
presentation/          # 表现层
├── pages/
│   ├── auth/         # 认证页面
│   └── user/         # 用户页面
└── blocs/
    └── auth/         # 认证状态管理

domain/               # 领域层
├── entities/         # 实体
│   ├── user.dart
│   └── auth_session.dart
├── repositories/     # 仓储接口
│   └── i_auth_repository.dart
└── usecases/         # 用例
    └── auth/
        ├── login_use_case.dart
        ├── register_use_case.dart
        ├── logout_use_case.dart
        ├── get_current_user_use_case.dart
        ├── update_profile_use_case.dart
        └── send_password_reset_email_use_case.dart

data/                 # 数据层
├── datasources/      # 数据源
│   └── supabase_auth_data_source.dart
└── repositories/     # 仓储实现
    └── auth_repository.dart
```

### 状态管理

使用 **flutter_bloc** 进行状态管理：

**AuthBloc** 负责处理所有认证相关的事件和状态：

**事件 (AuthEvent)**:
- `authCheckRequested` - 检查认证状态
- `loginRequested` - 登录请求
- `registerRequested` - 注册请求
- `logoutRequested` - 登出请求
- `passwordResetRequested` - 密码重置请求
- `profileUpdateRequested` - 资料更新请求

**状态 (AuthState)**:
- `initial` - 初始状态
- `loading` - 加载中
- `authenticated` - 已认证（包含用户信息）
- `unauthenticated` - 未认证
- `error` - 错误状态（包含错误消息）

### 数据流

```
UI (Page) 
  ↓ dispatch event
AuthBloc
  ↓ call
UseCase
  ↓ call
Repository
  ↓ call
DataSource (Supabase)
  ↓ return
Repository
  ↓ return Either<Failure, Success>
UseCase
  ↓ return
AuthBloc
  ↓ emit state
UI (Page) - rebuild
```

## Supabase 集成

### 配置

在 `lib/core/constants/app_constants.dart` 中配置 Supabase：

```dart
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://your-project.supabase.co',
);

static const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'your-anon-key',
);
```

### 初始化

在 `main.dart` 中初始化：

```dart
await Supabase.initialize(
  url: AppConstants.supabaseUrl,
  anonKey: AppConstants.supabaseAnonKey,
);
```

### 认证方法

**SupabaseAuthDataSource** 封装了所有 Supabase Auth 操作：

- `register()` - 用户注册
- `login()` - 用户登录
- `logout()` - 用户登出
- `sendPasswordResetEmail()` - 发送密码重置邮件
- `getCurrentUser()` - 获取当前用户
- `updateProfile()` - 更新用户资料
- `authStateChanges` - 监听认证状态变化
- `refreshToken()` - 刷新访问令牌

## 错误处理

使用 **AuthFailure** 封装所有认证相关错误：

```dart
@freezed
class AuthFailure with _$AuthFailure {
  const factory AuthFailure.invalidCredentials() = _InvalidCredentials;
  const factory AuthFailure.emailAlreadyInUse() = _EmailAlreadyInUse;
  const factory AuthFailure.weakPassword() = _WeakPassword;
  const factory AuthFailure.userNotFound() = _UserNotFound;
  const factory AuthFailure.emailNotVerified() = _EmailNotVerified;
  const factory AuthFailure.networkError() = _NetworkError;
  const factory AuthFailure.serverError(String message) = _ServerError;
  const factory AuthFailure.unknown(String message) = _Unknown;
}
```

错误会被映射为用户友好的中文消息：

- `invalidCredentials` → "邮箱或密码错误"
- `emailAlreadyInUse` → "该邮箱已被注册"
- `weakPassword` → "密码强度不足"
- 等等...

## 依赖注入

使用 **injectable** 和 **get_it** 进行依赖注入：

```dart
// 注册依赖
@injectable
class LoginUseCase { ... }

@injectable
class SupabaseAuthDataSource { ... }

@LazySingleton(as: IAuthRepository)
class AuthRepository implements IAuthRepository { ... }

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> { ... }

// 使用依赖
final authBloc = getIt<AuthBloc>();
```

## 使用示例

### 登录

```dart
// 在 UI 中触发登录
context.read<AuthBloc>().add(
  AuthEvent.loginRequested(
    email: 'user@example.com',
    password: 'password123',
  ),
);

// 监听状态变化
BlocConsumer<AuthBloc, AuthState>(
  listener: (context, state) {
    state.maybeWhen(
      authenticated: (user) => context.go('/'),
      error: (message) => showSnackBar(message),
      orElse: () {},
    );
  },
  builder: (context, state) {
    // 根据状态构建 UI
  },
)
```

### 注册

```dart
context.read<AuthBloc>().add(
  AuthEvent.registerRequested(
    email: 'user@example.com',
    password: 'SecurePass123',
    username: 'username',
  ),
);
```

### 更新资料

```dart
context.read<AuthBloc>().add(
  AuthEvent.profileUpdateRequested(
    username: 'new_username',
    bio: 'My bio',
  ),
);
```

## 安全性

### 密码要求
- 最少 8 个字符
- 至少包含一个大写字母
- 至少包含一个小写字母
- 至少包含一个数字

### Token 管理
- Access Token 和 Refresh Token 由 Supabase 自动管理
- Token 存储在安全的本地存储中
- 自动刷新过期的 Token

### 邮箱验证
- 注册后自动发送验证邮件
- 未验证用户可以登录但会显示验证提示
- 支持重新发送验证邮件

## 待实现功能

1. **头像上传**
   - 集成图片选择器
   - 上传到 Supabase Storage
   - 图片压缩和优化

2. **第三方登录**
   - Google 登录
   - Apple 登录
   - 微信登录

3. **双因素认证 (2FA)**
   - 短信验证码
   - TOTP 认证器

4. **账户管理**
   - 修改密码
   - 删除账户
   - 账户安全日志

## 测试

### 单元测试
- Use Cases 测试
- Repository 测试
- Bloc 测试

### 集成测试
- 完整的注册流程
- 完整的登录流程
- 密码重置流程

### UI 测试
- 表单验证
- 错误提示
- 加载状态

## 故障排查

### 常见问题

**1. 登录失败 - "Invalid login credentials"**
- 检查邮箱和密码是否正确
- 确认账户已注册
- 检查 Supabase 配置

**2. 注册失败 - "User already registered"**
- 该邮箱已被使用
- 尝试使用其他邮箱或直接登录

**3. 密码重置邮件未收到**
- 检查垃圾邮件文件夹
- 确认邮箱地址正确
- 检查 Supabase Email 配置

**4. Token 过期**
- AuthBloc 会自动处理 Token 刷新
- 如果刷新失败，用户需要重新登录

## 相关文档

- [Supabase Auth 文档](https://supabase.com/docs/guides/auth)
- [Flutter Bloc 文档](https://bloclibrary.dev/)
- [Go Router 文档](https://pub.dev/packages/go_router)
- [Injectable 文档](https://pub.dev/packages/injectable)

## 更新日志

### v0.1.0 (2026-04-17)
- ✅ 实现用户注册功能
- ✅ 实现用户登录功能
- ✅ 实现密码重置功能
- ✅ 实现用户资料编辑功能
- ✅ 集成 Supabase Auth
- ✅ 实现 AuthBloc 状态管理
- ✅ 配置路由和依赖注入
