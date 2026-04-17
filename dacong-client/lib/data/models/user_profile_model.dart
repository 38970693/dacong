// 用户 Profile 数据模型
class UserProfile {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 社区数据（join 所得，非 models 表字段）
  final int? postCount;
  final int? followerCount;
  final int? followingCount;

  const UserProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
    this.postCount,
    this.followerCount,
    this.followingCount,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      postCount: json['post_count'] as int?,
      followerCount: json['follower_count'] as int?,
      followingCount: json['following_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'avatar_url': avatarUrl,
        'bio': bio,
        'created_at': createdAt.toIso8601String(),
      };

  UserProfile copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? postCount,
    int? followerCount,
    int? followingCount,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      postCount: postCount ?? this.postCount,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }
}
