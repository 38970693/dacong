import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment_model.dart';

/// 评论远程数据源
abstract class CommentRemoteDataSource {
  Future<List<CommentModel>> getComments({
    required String contentId,
    String? parentId,
    int page = 1,
    int limit = 20,
    String sort = 'latest',
  });

  Future<CommentModel> submitComment({
    required String contentId,
    required String content,
    String? parentId,
  });

  Future<void> likeComment(String commentId);

  Future<void> unlikeComment(String commentId);

  Future<void> reportComment({
    required String commentId,
    String? reason,
  });
}

/// 评论远程数据源实现
class CommentRemoteDataSourceImpl implements CommentRemoteDataSource {
  final SupabaseClient supabaseClient;

  CommentRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<CommentModel>> getComments({
    required String contentId,
    String? parentId,
    int page = 1,
    int limit = 20,
    String sort = 'latest',
  }) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'get-comments',
        body: {
          'content_id': contentId,
          'parent_id': parentId,
          'page': page,
          'limit': limit,
          'sort': sort,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to fetch comments: ${response.status}');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Unknown error');
      }

      final commentsData = data['data']['comments'] as List;
      return commentsData
          .map((json) => CommentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  @override
  Future<CommentModel> submitComment({
    required String contentId,
    required String content,
    String? parentId,
  }) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'submit-comment',
        body: {
          'content_id': contentId,
          'content': content,
          'parent_id': parentId,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to submit comment: ${response.status}');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Unknown error');
      }

      final commentData = data['data']['comment'] as Map<String, dynamic>;
      return CommentModel.fromJson(commentData);
    } catch (e) {
      throw Exception('Failed to submit comment: $e');
    }
  }

  @override
  Future<void> likeComment(String commentId) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'like-comment',
        body: {
          'comment_id': commentId,
          'action': 'like',
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to like comment: ${response.status}');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Unknown error');
      }
    } catch (e) {
      throw Exception('Failed to like comment: $e');
    }
  }

  @override
  Future<void> unlikeComment(String commentId) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'like-comment',
        body: {
          'comment_id': commentId,
          'action': 'unlike',
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to unlike comment: ${response.status}');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Unknown error');
      }
    } catch (e) {
      throw Exception('Failed to unlike comment: $e');
    }
  }

  @override
  Future<void> reportComment({
    required String commentId,
    String? reason,
  }) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'report-comment',
        body: {
          'comment_id': commentId,
          'reason': reason,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to report comment: ${response.status}');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Unknown error');
      }
    } catch (e) {
      throw Exception('Failed to report comment: $e');
    }
  }
}
