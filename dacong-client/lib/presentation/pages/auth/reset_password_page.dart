import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../../core/di/injection.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendResetEmail() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthEvent.passwordResetRequested(_emailController.text.trim()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('重置密码'),
        ),
        body: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              state.maybeWhen(
                error: (message) {
                  if (!message.contains('重置')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  } else {
                    setState(() {
                      _emailSent = true;
                    });
                  }
                },
                loading: () {
                  // loading 状态不处理
                },
                orElse: () {
                  // 如果不是 error 和 loading 状态，说明邮件发送成功
                  if (_emailController.text.isNotEmpty) {
                    setState(() {
                      _emailSent = true;
                    });
                  }
                },
              );
            },
            builder: (context, state) {
              final isLoading = state.maybeWhen(
                loading: () => true,
                orElse: () => false,
              );

              if (_emailSent) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mark_email_read,
                          size: 100,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          '邮件已发送',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '我们已向 ${_emailController.text} 发送了密码重置链接。\n请查收邮件并按照说明重置密码。',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () => context.go('/auth/login'),
                          child: const Text('返回登录'),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _emailSent = false;
                            });
                          },
                          child: const Text('重新发送'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Icon
                        Icon(
                          Icons.lock_reset,
                          size: 100,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 32),

                        // 标题
                        Text(
                          '重置密码',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '输入您的邮箱地址，我们将发送重置密码的链接',
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
                            hintText: '请输入注册时使用的邮箱',
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
                        const SizedBox(height: 24),

                        // 发送按钮
                        ElevatedButton(
                          onPressed: isLoading ? null : _handleSendResetEmail,
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
                              : const Text('发送重置链接'),
                        ),
                        const SizedBox(height: 16),

                        // 返回登录
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('记起密码了？'),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => context.go('/auth/login'),
                              child: const Text('返回登录'),
                            ),
                          ],
                        ),
                      ],
                    ),
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
