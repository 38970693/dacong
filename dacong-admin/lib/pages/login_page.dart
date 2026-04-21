import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _rememberPassword = false;

  // 开发模式标志（从环境变量读取）
  static const bool _isDevMode = bool.fromEnvironment('DEV_MODE', defaultValue: false);

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 加载保存的账号（仅加载邮箱）
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      final rememberPassword = prefs.getBool('remember_password') ?? false;

      if (rememberPassword && savedEmail != null) {
        setState(() {
          _emailController.text = savedEmail;
          _rememberPassword = true;
        });
      }
    } catch (e) {
      debugPrint('加载凭据失败: $e');
    }
  }

  /// 保存账号（仅保存邮箱，不保存密码）
  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberPassword) {
        await prefs.setString('saved_email', _emailController.text.trim());
        await prefs.setBool('remember_password', true);
      } else {
        await prefs.remove('saved_email');
        await prefs.setBool('remember_password', false);
      }
    } catch (e) {
      debugPrint('保存凭据失败: $e');
    }
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

      // 3. 保存账号密码（如果勾选了记住密码）
      await _saveCredentials();

      // 4. 记录登录日志
      try {
        await Supabase.instance.client.from('admin_logs').insert({
          'admin_id': response.user!.id,
          'action': 'login',
          'details': {
            'email': _emailController.text.trim().replaceAll(RegExp(r'[^\w@.]'), '')
          },
        });
      } catch (e) {
        debugPrint('记录登录日志失败: $e');
      }

      // 5. 跳转到看板
      if (mounted) {
        context.go('/');
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } catch (e) {
      debugPrint('未预期的登录错误: $e');
      setState(() {
        _errorMessage = '登录失败，请稍后重试';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 开发模式直接进入（跳过登录验证）
  void _devModeEnter() {
    if (!mounted) return;

    // 显示提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔧 开发模式：已跳过登录验证'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );

    // 直接跳转到看板（路由守卫已在 main.dart 中配置为开发模式跳过验证）
    context.go('/');
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
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
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

                    // 记住邮箱选项
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberPassword,
                          onChanged: (value) {
                            setState(() {
                              _rememberPassword = value ?? false;
                            });
                          },
                        ),
                        const Text('记住邮箱'),
                      ],
                    ),
                    const SizedBox(height: 8),

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

                    // 开发模式进入按钮
                    if (_isDevMode) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _devModeEnter,
                        icon: const Icon(Icons.developer_mode, size: 18),
                        label: const Text('开发模式进入'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '⚠️ 仅开发环境可用',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
