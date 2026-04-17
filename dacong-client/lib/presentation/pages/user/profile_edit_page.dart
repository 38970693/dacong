import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../../core/di/injection.dart';
import '../../../domain/entities/user.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  String? _avatarUrl;
  User? _currentUser;

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthEvent.profileUpdateRequested(
              username: _usernameController.text.trim().isEmpty
                  ? null
                  : _usernameController.text.trim(),
              avatarUrl: _avatarUrl,
              bio: _bioController.text.trim().isEmpty
                  ? null
                  : _bioController.text.trim(),
            ),
          );
    }
  }

  Future<void> _pickImage() async {
    // TODO: 实现图片选择和上传
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('图片上传功能待实现')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>()..add(const AuthEvent.authCheckRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('编辑资料'),
          actions: [
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isLoading = state.maybeWhen(
                  loading: () => true,
                  orElse: () => false,
                );
                return TextButton(
                  onPressed: isLoading ? null : _handleSave,
                  child: const Text('保存'),
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            state.maybeWhen(
              authenticated: (user) {
                if (_currentUser == null) {
                  // 首次加载用户数据
                  setState(() {
                    _currentUser = user;
                    _usernameController.text = user.username ?? '';
                    _bioController.text = user.bio ?? '';
                    _avatarUrl = user.avatarUrl;
                  });
                } else {
                  // 更新成功
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('资料更新成功')),
                  );
                  context.pop();
                }
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

            if (_currentUser == null && !isLoading) {
              return const Center(
                child: Text('请先登录'),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 头像
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _avatarUrl != null
                                ? NetworkImage(_avatarUrl!)
                                : null,
                            child: _avatarUrl == null
                                ? const Icon(Icons.person, size: 60)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: isLoading ? null : _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 邮箱（只读）
                    TextFormField(
                      initialValue: _currentUser?.email ?? '',
                      decoration: const InputDecoration(
                        labelText: '邮箱',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                        enabled: false,
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),

                    // 用户名
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: '用户名',
                        hintText: '请输入用户名',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length < 2) {
                            return '用户名至少需要2个字符';
                          }
                          if (value.length > 20) {
                            return '用户名最多20个字符';
                          }
                        }
                        return null;
                      },
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),

                    // 个人简介
                    TextFormField(
                      controller: _bioController,
                      maxLines: 4,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        labelText: '个人简介',
                        hintText: '介绍一下自己吧',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 24),

                    // 邮箱验证状态
                    if (_currentUser != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                _currentUser!.emailVerified
                                    ? Icons.verified
                                    : Icons.warning,
                                color: _currentUser!.emailVerified
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentUser!.emailVerified
                                          ? '邮箱已验证'
                                          : '邮箱未验证',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    if (!_currentUser!.emailVerified)
                                      const Text(
                                        '请查收验证邮件以完成验证',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                  ],
                                ),
                              ),
                              if (!_currentUser!.emailVerified)
                                TextButton(
                                  onPressed: () {
                                    // TODO: 重新发送验证邮件
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('验证邮件已发送'),
                                      ),
                                    );
                                  },
                                  child: const Text('重新发送'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // 账户信息
                    if (_currentUser?.createdAt != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '账户信息',
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '注册时间: ${_formatDate(_currentUser!.createdAt!)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (_currentUser!.updatedAt != null)
                                Text(
                                  '最后更新: ${_formatDate(_currentUser!.updatedAt!)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
