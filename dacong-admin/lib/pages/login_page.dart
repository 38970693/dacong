import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. 登录认证
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user == null) {
        throw Exception('登录失败');
      }

      // 2. 验证管理员权限
      final adminCheck = await Supabase.instance.client
          .from('admin_users')
          .select()
          .eq('id', response.user!.id)
          .eq('is_active', true)
          .maybeSingle();

      if (adminCheck == null) {
        // 不是管理员，退出登录
        await Supabase.instance.client.auth.signOut();
        throw Exception('您没有管理员权限');
      }

      // 3. 记录登录日志
      await Supabase.instance.client.from('admin_logs').insert({
        'admin_id': response.user!.id,
        'action': 'login',
        'details': {'email': _emailController.text.trim()},
      });

      // 4. 跳转到看板
      if (mounted) {
        context.go('/');
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    const Icon(
                      Icons.admin_panel_settings,
                      size: 64,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'DaCong 运营后台',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // 邮箱
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: '邮箱',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入邮箱';
                        }
                        if (!value.contains('@')) {
                          return '请输入有效的邮箱';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 密码
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: '密码',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入密码';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // 错误信息
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // 登录按钮
                    FilledButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('登录'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
