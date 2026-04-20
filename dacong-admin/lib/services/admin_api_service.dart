import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'csrf_service.dart';

/// 管理后台 API 服务
class AdminApiService {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final CsrfService _csrfService;

  AdminApiService() {
    _csrfService = CsrfService(_supabase);
  }

  Future<Map<String, String>> get _headers async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw Exception('Not authenticated');
    }

    // 获取 CSRF Token
    final csrfToken = await _csrfService.getCsrfToken();

    return {
      'Authorization': 'Bearer ${session.accessToken}',
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken,
    };
  }

  // ── 内容管理 ────────────────────────────────────────────

  /// 获取内容列表
  Future<Map<String, dynamic>> getContentList({
    String status = 'pending',
    int page = 1,
    int limit = 20,
    String search = '',
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    final headers = await _headers;

    final response = await _supabase.functions.invoke(
      'admin-content-management',
      method: HttpMethod.get,
      headers: headers,
      queryParameters: {
        'status': status,
        'page': page.toString(),
        'limit': limit.toString(),
        'search': search,
        'sort_by': sortBy,
        'sort_order': sortOrder,
      },
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to fetch content');
    }

    return response.data['data'] as Map<String, dynamic>;
  }

  /// 审核内容（批量）
  Future<void> moderateContent({
    required String action,
    required List<String> contentIds,
    String? reason,
  }) async {
    final headers = await _headers;

    final response = await _supabase.functions.invoke(
      'admin-content-management',
      method: HttpMethod.post,
      headers: headers,
      body: {
        'action': action,
        'content_ids': contentIds,
        'reason': reason,
      },
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to moderate content');
    }

    // 记录操作日志
    await _logAction(
      action: 'moderate_content',
      targetType: 'content',
      targetIds: contentIds,
      details: {'action': action, 'reason': reason},
    );
  }

  /// 编辑内容
  Future<void> editContent({
    required String contentId,
    String? title,
    String? content,
    String? topicId,
  }) async {
    final headers = await _headers;

    final response = await _supabase.functions.invoke(
      'admin-content-management',
      method: HttpMethod.put,
      headers: headers,
      body: {
        'content_id': contentId,
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (topicId != null) 'topic_id': topicId,
      },
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to edit content');
    }
  }

  /// 删除内容（批量）
  Future<void> deleteContent(List<String> contentIds) async {
    final headers = await _headers;

    final response = await _supabase.functions.invoke(
      'admin-content-management',
      method: HttpMethod.delete,
      headers: headers,
      body: {
        'content_ids': contentIds,
      },
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to delete content');
    }
  }

  // ── 用户管理 ────────────────────────────────────────────

  /// 获取用户列表
  Future<Map<String, dynamic>> getUserList({
    int page = 1,
    int limit = 20,
    String search = '',
    String status = 'all',
  }) async {
    final headers = await _headers;

    final response = await _supabase.functions.invoke(
      'admin-user-management',
      method: HttpMethod.get,
      headers: headers,
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        'search': search,
        'status': status,
      },
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to fetch users');
    }

    return response.data['data'] as Map<String, dynamic>;
  }

  /// 获取用户详情
  Future<Map<String, dynamic>> getUserDetail(String userId) async {
    final headers = await _headers;

    final response = await _supabase.functions.invoke(
      'admin-user-management',
      method: HttpMethod.get,
      headers: headers,
      queryParameters: {
        'user_id': userId,
      },
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to fetch user detail');
    }

    return response.data['data'] as Map<String, dynamic>;
  }

  /// 封禁/解封用户
  Future<void> banUser({
    required String userId,
    required bool ban,
    String? reason,
  }) async {
    final headers = await _headers;

    final response = await _supabase.functions.invoke(
      'admin-user-management',
      method: HttpMethod.post,
      headers: headers,
      body: {
        'action': ban ? 'ban' : 'unban',
        'user_id': userId,
        'reason': reason,
      },
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to ban/unban user');
    }
  }

  /// 删除用户
  Future<void> deleteUser(String userId) async {
    final headers = await _headers;

    final response = await _supabase.functions.invoke(
      'admin-user-management',
      method: HttpMethod.delete,
      headers: headers,
      body: {
        'user_id': userId,
      },
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to delete user');
    }
  }

  // ── 评论审核 ────────────────────────────────────────────

  /// 获取待审核评论列表
  Future<Map<String, dynamic>> getCommentList({
    int page = 1,
    int limit = 20,
    String status = 'pending',
    bool reportedOnly = false,
  }) async {
    final headers = await _headers;

    final response = await _supabase.functions.invoke(
      'admin-comment-moderation',
      method: HttpMethod.get,
      headers: headers,
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        'status': status,
        'reported_only': reportedOnly.toString(),
      },
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to fetch comments');
    }

    return response.data['data'] as Map<String, dynamic>;
  }

  /// 审核评论
  Future<void> moderateComment({
    required String action,
    required List<String> commentIds,
    String? reason,
    bool banUser = false,
  }) async {
    final headers = await _headers;

    final response = await _supabase.functions.invoke(
      'admin-comment-moderation',
      method: HttpMethod.post,
      headers: headers,
      body: {
        'action': action,
        'comment_ids': commentIds,
        'reason': reason,
        'ban_user': banUser,
      },
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to moderate comment');
    }
  }

  // ── 操作日志 ────────────────────────────────────────────

  /// 记录管理操作日志
  Future<void> _logAction({
    required String action,
    required String targetType,
    required List<String> targetIds,
    Map<String, dynamic>? details,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('admin_logs').insert({
        'admin_id': userId,
        'action': action,
        'target_type': targetType,
        'target_ids': targetIds,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // 日志记录失败不应影响主操作
      debugPrint('Failed to log action: $e');
    }
  }

  /// 获取操作日志
  Future<Map<String, dynamic>> getAdminLogs({
    int page = 1,
    int limit = 50,
    String? adminId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('admin_logs')
          .select('*, profiles!admin_id(username, avatar_url)');

      if (adminId != null) {
        query = query.eq('admin_id', adminId);
      }

      if (action != null) {
        query = query.eq('action', action);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      // 获取总数（简化版本）
      final countQuery = _supabase.from('admin_logs').select('id');
      if (adminId != null) countQuery.eq('admin_id', adminId);
      if (action != null) countQuery.eq('action', action);
      if (startDate != null) countQuery.gte('created_at', startDate.toIso8601String());
      if (endDate != null) countQuery.lte('created_at', endDate.toIso8601String());

      final countResponse = await countQuery;
      final total = (countResponse as List).length;

      return {
        'items': response,
        'total': total,
      };
    } catch (e) {
      throw Exception('Failed to fetch admin logs: $e');
    }
  }
}
