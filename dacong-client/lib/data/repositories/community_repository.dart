// 社区 Repository（帖子 + 评论）
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';
import '../models/topic_model.dart';
import '../../domain/entities/comment.dart';

class CommunityRepository {
  CommunityRepository._();
  static final _instance = CommunityRepository._();
  static CommunityRepository get instance => _instance;

  final _client = Supabase.instance.client;

  // ── 帖子 ─────────────────────────────────

  /// 获取帖子流（支持按话题过滤）
  Future<List<Post>> getPosts({
    int page = 0,
    int pageSize = 20,
    String? topicId,
  }) async {
    var query = _client.from('posts').select('*, profiles(username, avatar_url), topics(name)');

    if (topicId != null && topicId.isNotEmpty) {
      query = query.eq('topic_id', topicId);
    }

    final response = await query
        .eq('moderation_status', 'passed')
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return _parsePostsWithJoin(response);
  }

  /// 发帖
  Future<Post> createPost({
    required String title,
    required String content,
    required PostType postType,
    List<String> mediaUrls = const [],
    String? topicId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('未登录');

    final data = {
      'user_id': userId,
      'title': title,
      'content': content,
      'post_type': postType.name,
      'media_urls': mediaUrls,
      'topic_id': topicId,
    };

    final response = await _client.from('posts').insert(data).select().single();
    return Post.fromJson(response);
  }

  /// 删除帖子
  Future<void> deletePost(String postId) async {
    await _client.from('posts').delete().eq('id', postId);
  }

  /// 点赞帖子
  Future<void> toggleLike(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // 检查是否已点赞
    final existing = await _client
        .from('likes')
        .select('id')
        .match({'user_id': userId, 'target_type': 'post', 'target_id': postId})
        .maybeSingle();

    if (existing != null) {
      await _client.from('likes').delete().eq('id', existing['id']);
    } else {
      await _client.from('likes').insert({
        'user_id': userId,
        'target_type': 'post',
        'target_id': postId,
      });
    }
  }

  // ── 评论 ─────────────────────────────────

  /// 获取帖子评论
  Future<List<Comment>> getComments(String postId) async {
    final response = await _client
        .from('comments')
        .select('*, profiles(username, avatar_url)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return (response as List<dynamic>)
        .map((e) => Comment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 发评论
  Future<Comment> createComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('未登录');

    final data = {
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'parent_id': parentId,
    };

    final response = await _client.from('comments').insert(data).select().single();
    return Comment.fromJson(response);
  }

  // ── 话题 ─────────────────────────────────

  /// 获取所有话题
  Future<List<Topic>> getTopics() async {
    final response = await _client
        .from('topics')
        .select('*')
        .order('post_count', ascending: false);

    return (response as List<dynamic>)
        .map((e) => Topic.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── 工具 ─────────────────────────────────

  List<Post> _parsePostsWithJoin(dynamic response) {
    return (response as List<dynamic>).map((e) {
      final map = e as Map<String, dynamic>;
      // Supabase join 展平：profiles → author_name, author_avatar
      final profile = map['profiles'] as Map<String, dynamic>?;
      final topic = map['topics'] as Map<String, dynamic>?;
      return Post.fromJson(map).copyWith(
        authorName: profile?['username'] as String?,
        authorAvatar: profile?['avatar_url'] as String?,
        topicName: topic?['name'] as String?,
      );
    }).toList();
  }
}
