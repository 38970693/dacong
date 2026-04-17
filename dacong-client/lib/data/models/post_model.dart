// 帖子数据模型
class Post {
  final String id;
  final String userId;
  final String title;
  final String content;
  final PostType postType;   // text / link / image
  final List<String> mediaUrls;
  final String? topicId;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final ModerationStatus moderationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 关联数据（join 所得）
  final String? authorName;
  final String? authorAvatar;
  final String? topicName;

  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.postType,
    this.mediaUrls = const [],
    this.topicId,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.moderationStatus = ModerationStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.authorName,
    this.authorAvatar,
    this.topicName,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      postType: PostType.values.firstWhere(
        (e) => e.name == (json['post_type'] as String? ?? 'text'),
        orElse: () => PostType.text,
      ),
      mediaUrls: (json['media_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      topicId: json['topic_id'] as String?,
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      shareCount: json['share_count'] as int? ?? 0,
      moderationStatus: ModerationStatus.values.firstWhere(
        (e) => e.name == (json['moderation_status'] as String? ?? 'pending'),
        orElse: () => ModerationStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      authorName: json['author_name'] as String?,
      authorAvatar: json['author_avatar'] as String?,
      topicName: json['topic_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'content': content,
        'post_type': postType.name,
        'media_urls': mediaUrls,
        'topic_id': topicId,
        'created_at': createdAt.toIso8601String(),
      };

  Post copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    PostType? postType,
    List<String>? mediaUrls,
    String? topicId,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    ModerationStatus? moderationStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorName,
    String? authorAvatar,
    String? topicName,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      postType: postType ?? this.postType,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      topicId: topicId ?? this.topicId,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      topicName: topicName ?? this.topicName,
    );
  }
}

enum PostType { text, link, image }

enum ModerationStatus { pending, passed, flagged }
