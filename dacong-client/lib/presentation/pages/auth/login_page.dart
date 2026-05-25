import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../../core/di/injection.dart';
import '../../../l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthEvent.loginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>(),
      child: Scaffold(
        body: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              state.maybeWhen(
                authenticated: (_) => context.go('/'),
                error: (message) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                ),
                orElse: () {},
              );
            },
            builder: (context, state) {
              // 邮箱未验证状态
              if (state.maybeWhen(emailNotVerified: () => true, orElse: () => false)) {
                return _buildEmailNotVerifiedView(context);
              }

              // 邮件频率限制状态
              if (state.maybeWhen(emailRateLimit: () => true, orElse: () => false)) {
                return _buildEmailRateLimitView(context);
              }

              final isLoading = state.maybeWhen(
                loading: () => true,
                orElse: () => false,
              );

              return _buildLoginForm(context, isLoading);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmailNotVerifiedView(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_unread,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            Text(
              '邮箱未验证',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              email.isNotEmpty
                  ? '验证邮件已发送至 $email\n请查收邮件并点击验证链接'
                  : '请先登录以验证邮箱',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/auth/login'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('返回登录'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailRateLimitView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.hourglass_empty,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(
              '操作过于频繁',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '发送邮件过于频繁，请稍后再试\n\n通常等待 1-5 分钟后即可重新操作',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/auth/login'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('返回登录'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, bool isLoading) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Icon(
                Icons.account_circle,
                size: 100,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 32),

              // 标题
              Text(
                '欢迎回来',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '登录您的账户',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // 邮箱输入
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '邮箱',
                  hintText: '请输入邮箱',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入邮箱';
                  }
                  if (!value.contains('@')) {
                    return '请输入有效的邮箱地址';
                  }
                  return null;
                },
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),

              // 密码输入
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '密码',
                  hintText: '请输入密码',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入密码';
                  }
                  if (value.length < 6) {
                    return '密码至少需要6个字符';
                  }
                  return null;
                },
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),

              // 记住我 & 忘记密码
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                      ),
                      const Text('记住我'),
                    ],
                  ),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context.push('/auth/reset-password'),
                    child: const Text('忘记密码？'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 登录按钮
              ElevatedButton(
                onPressed: isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('登录'),
              ),
              const SizedBox(height: 16),

              // 注册链接
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('还没有账户？'),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context.push('/auth/register'),
                    child: const Text('立即注册'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
