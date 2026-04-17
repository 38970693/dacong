import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_api_service.dart';

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  final _apiService = AdminApiService();
  final _searchController = TextEditingController();

  String _selectedStatus = 'all';
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _isLoading = false;
  List<dynamic> _users = [];
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final result = await _apiService.getUserList(
        page: _currentPage,
        limit: _pageSize,
        search: _searchController.text,
        status: _selectedStatus,
      );

      setState(() {
        _users = result['items'] as List;
        _totalCount = result['total'] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  Future<void> _showUserDetail(String userId) async {
    try {
      final detail = await _apiService.getUserDetail(userId);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('用户详情'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 基本信息
                  Text('基本信息', style: Theme.of(context).textTheme.titleMedium),
                  const Divider(),
                  _buildInfoRow('用户名', detail['profile']['username']),
                  _buildInfoRow('ID', detail['profile']['id']),
                  _buildInfoRow('注册时间', _formatDate(detail['profile']['created_at'])),
                  _buildInfoRow(
                    '状态',
                    detail['profile']['is_banned'] == true ? '已封禁' : '正常',
                  ),
                  if (detail['profile']['is_banned'] == true) ...[
                    _buildInfoRow('封禁原因', detail['profile']['banned_reason'] ?? '无'),
                    _buildInfoRow('封禁时间', _formatDate(detail['profile']['banned_at'])),
                  ],
                  const SizedBox(height: 16),

                  // 统计信息
                  Text('统计信息', style: Theme.of(context).textTheme.titleMedium),
                  const Divider(),
                  _buildInfoRow('发帖数', detail['stats']['posts_count'].toString()),
                  _buildInfoRow('评论数', detail['stats']['comments_count'].toString()),
                  _buildInfoRow('粉丝数', detail['stats']['followers_count'].toString()),
                  _buildInfoRow('关注数', detail['stats']['following_count'].toString()),
                  const SizedBox(height: 16),

                  // 最近活动
                  Text('最近发帖', style: Theme.of(context).textTheme.titleMedium),
                  const Divider(),
                  if (detail['recent_activity']['posts'].isEmpty)
                    const Text('暂无发帖')
                  else
                    ...List.generate(
                      detail['recent_activity']['posts'].length,
                      (index) {
                        final post = detail['recent_activity']['posts'][index];
                        return ListTile(
                          dense: true,
                          title: Text(post['title'] ?? '无标题'),
                          subtitle: Text(_formatDate(post['created_at'])),
                        );
                      },
                    ),
                  const SizedBox(height: 16),

                  Text('最近评论', style: Theme.of(context).textTheme.titleMedium),
                  const Divider(),
                  if (detail['recent_activity']['comments'].isEmpty)
                    const Text('暂无评论')
                  else
                    ...List.generate(
                      detail['recent_activity']['comments'].length,
                      (index) {
                        final comment = detail['recent_activity']['comments'][index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            comment['content'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(_formatDate(comment['created_at'])),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载用户详情失败: $e')),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _banUser(String userId, bool ban) async {
    String? reason;

    if (ban) {
      reason = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('封禁用户'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '封禁原因',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('确定'),
              ),
            ],
          );
        },
      );

      if (reason == null || reason.isEmpty) return;
    }

    try {
      await _apiService.banUser(
        userId: userId,
        ban: ban,
        reason: reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ban ? '封禁成功' : '解封成功')),
        );
      }

      _loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除此用户吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiService.deleteUser(userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功')),
        );
      }

      _loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户管理'),
      ),
      body: Column(
        children: [
          // 搜索栏
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '搜索用户（用户名）...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _loadUsers(),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('全部')),
                    DropdownMenuItem(value: 'active', child: Text('正常')),
                    DropdownMenuItem(value: 'banned', child: Text('已封禁')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                        _currentPage = 1;
                      });
                      _loadUsers();
                    }
                  },
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadUsers,
                  tooltip: '刷新',
                ),
              ],
            ),
          ),

          // 用户列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(child: Text('暂无用户'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('用户名')),
                              DataColumn(label: Text('ID')),
                              DataColumn(label: Text('注册时间')),
                              DataColumn(label: Text('状态')),
                              DataColumn(label: Text('操作')),
                            ],
                            rows: _users.map((user) {
                              final isBanned = user['is_banned'] == true;
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        if (user['avatar_url'] != null)
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundImage: NetworkImage(user['avatar_url']),
                                          )
                                        else
                                          const CircleAvatar(
                                            radius: 16,
                                            child: Icon(Icons.person, size: 16),
                                          ),
                                        const SizedBox(width: 8),
                                        Text(user['username'] ?? '未知'),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      user['id'].toString().substring(0, 8),
                                      style: const TextStyle(fontFamily: 'monospace'),
                                    ),
                                  ),
                                  DataCell(Text(_formatDate(user['created_at']))),
                                  DataCell(
                                    Chip(
                                      label: Text(isBanned ? '已封禁' : '正常'),
                                      backgroundColor: isBanned
                                          ? Colors.red.shade100
                                          : Colors.green.shade100,
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextButton(
                                          onPressed: () => _showUserDetail(user['id']),
                                          child: const Text('详情'),
                                        ),
                                        TextButton(
                                          onPressed: () => _banUser(user['id'], !isBanned),
                                          child: Text(isBanned ? '解封' : '封禁'),
                                        ),
                                        TextButton(
                                          onPressed: () => _deleteUser(user['id']),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('删除'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),

          // 分页
          if (_totalCount > 0)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage--);
                            _loadUsers();
                          }
                        : null,
                  ),
                  Text('第 $_currentPage 页 / 共 ${(_totalCount / _pageSize).ceil()} 页'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < (_totalCount / _pageSize).ceil()
                        ? () {
                            setState(() => _currentPage++);
                            _loadUsers();
                          }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
