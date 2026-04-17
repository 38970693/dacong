import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../../core/di/injection.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入密码';
    }
    if (value.length < 8) {
      return '密码至少需要8个字符';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return '密码需要包含至少一个大写字母';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return '密码需要包含至少一个小写字母';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return '密码需要包含至少一个数字';
    }
    return null;
  }

  void _handleRegister() {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先同意用户协议')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthEvent.registerRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              username: _usernameController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('注册'),
        ),
        body: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              state.maybeWhen(
                authenticated: (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('注册成功！请查收验证邮件')),
                  );
                  context.go('/');
                },
                error: (message) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                ),
                orElse: () {},
              );
            },
            builder: (context, state) {
              final isLoading = state.maybeWhen(
                loading: () => true,
                orElse: () => false,
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 标题
                      Text(
                        '创建账户',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '加入 DaCong 社区',
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

                      // 用户名输入
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: '用户名（可选）',
                          hintText: '请输入用户名',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
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
                          helperText: '至少8个字符，包含大小写字母和数字',
                        ),
                        validator: _validatePassword,
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 16),

                      // 确认密码输入
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: '确认密码',
                          hintText: '请再次输入密码',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请确认密码';
                          }
                          if (value != _passwordController.text) {
                            return '两次输入的密码不一致';
                          }
                          return null;
                        },
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 16),

                      // 用户协议
                      Row(
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            onChanged: isLoading
                                ? null
                                : (value) {
                                    setState(() {
                                      _agreedToTerms = value ?? false;
                                    });
                                  },
                          ),
                          Expanded(
                            child: Wrap(
                              children: [
                                const Text('我已阅读并同意'),
                                TextButton(
                                  onPressed: () {
                                    // TODO: 显示用户协议
                                  },
                                  child: const Text('用户协议'),
                                ),
                                const Text('和'),
                                TextButton(
                                  onPressed: () {
                                    // TODO: 显示隐私政策
                                  },
                                  child: const Text('隐私政策'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 注册按钮
                      ElevatedButton(
                        onPressed: isLoading ? null : _handleRegister,
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
                            : const Text('注册'),
                      ),
                      const SizedBox(height: 16),

                      // 登录链接
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('已有账户？'),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () => context.push('/auth/login'),
                            child: const Text('立即登录'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
