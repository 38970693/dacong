class AuditLog {
  final String id;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String action;
  final String resource;
  final String? ip;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.action,
    required this.resource,
    this.ip,
    this.details,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] ?? '',
      userId: json['admin_id'] ?? json['user_id'] ?? '',
      username: json['profiles']?['username'] ?? json['username'] ?? '未知用户',
      avatarUrl: json['profiles']?['avatar_url'] ?? json['avatar_url'],
      action: json['action'] ?? '',
      resource: json['target_type'] ?? json['resource'] ?? '',
      ip: json['ip_address'] ?? json['ip'],
      details: json['details'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get actionLabel {
    switch (action) {
      case 'moderate_content':
        return '审核内容';
      case 'edit_content':
        return '编辑内容';
      case 'delete_content':
        return '删除内容';
      case 'ban_user':
        return '封禁用户';
      case 'unban_user':
        return '解封用户';
      case 'delete_user':
        return '删除用户';
      case 'moderate_comment':
        return '审核评论';
      case 'delete_comment':
        return '删除评论';
      case 'login':
        return '登录';
      case 'logout':
        return '登出';
      default:
        return action;
    }
  }

  String get resourceLabel {
    switch (resource) {
      case 'content':
        return '内容';
      case 'user':
        return '用户';
      case 'comment':
        return '评论';
      case 'system':
        return '系统';
      default:
        return resource;
    }
  }
}

class AuditLogFilter {
  final String? userId;
  final String? action;
  final String? resource;
  final DateTime? startDate;
  final DateTime? endDate;

  AuditLogFilter({
    this.userId,
    this.action,
    this.resource,
    this.startDate,
    this.endDate,
  });

  AuditLogFilter copyWith({
    String? userId,
    String? action,
    String? resource,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return AuditLogFilter(
      userId: userId ?? this.userId,
      action: action ?? this.action,
      resource: resource ?? this.resource,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  bool get hasFilters =>
      userId != null ||
      action != null ||
      resource != null ||
      startDate != null ||
      endDate != null;
}
