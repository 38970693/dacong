// 话题数据模型
class Topic {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final int postCount;
  final DateTime createdAt;

  const Topic({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.postCount = 0,
    required this.createdAt,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      postCount: json['post_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'description': description,
        'post_count': postCount,
        'created_at': createdAt.toIso8601String(),
      };
}
