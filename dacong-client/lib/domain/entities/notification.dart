/// 通知实体
class Notification {
  final String id;
  final String type;
  final String title;
  final String content;
  final String? link;
  final bool isRead;
  final DateTime createdAt;

  const Notification({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    this.link,
    required this.isRead,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      link: json['link'] as String?,
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'content': content,
      'link': link,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Notification copyWith({
    String? id,
    String? type,
    String? title,
    String? content,
    String? link,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      link: link ?? this.link,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
