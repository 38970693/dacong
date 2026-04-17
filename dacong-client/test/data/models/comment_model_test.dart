import 'package:flutter_test/flutter_test.dart';
import 'package:dacong_client/data/models/comment_model.dart';

void main() {
  group('CommentModel', () {
    final testJson = {
      'id': 'comment-123',
      'content_id': 'content-456',
      'user_id': 'user-789',
      'parent_id': 'parent-111',
      'content': 'Test comment',
      'likes_count': 10,
      'reply_count': 5,
      'is_liked': true,
      'created_at': '2024-01-01T00:00:00.000Z',
      'updated_at': '2024-01-02T00:00:00.000Z',
    };

    final testModel = CommentModel(
      id: 'comment-123',
      contentId: 'content-456',
      userId: 'user-789',
      parentId: 'parent-111',
      content: 'Test comment',
      likesCount: 10,
      replyCount: 5,
      isLiked: true,
      createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      updatedAt: DateTime.parse('2024-01-02T00:00:00.000Z'),
    );

    test('should create CommentModel from JSON', () {
      final result = CommentModel.fromJson(testJson);

      expect(result.id, 'comment-123');
      expect(result.contentId, 'content-456');
      expect(result.userId, 'user-789');
      expect(result.parentId, 'parent-111');
      expect(result.content, 'Test comment');
      expect(result.likesCount, 10);
      expect(result.replyCount, 5);
      expect(result.isLiked, true);
    });

    test('should convert CommentModel to JSON', () {
      final result = testModel.toJson();

      expect(result['id'], 'comment-123');
      expect(result['content_id'], 'content-456');
      expect(result['user_id'], 'user-789');
      expect(result['parent_id'], 'parent-111');
      expect(result['content'], 'Test comment');
      expect(result['likes_count'], 10);
      expect(result['reply_count'], 5);
      expect(result['is_liked'], true);
    });

    test('should handle default values for optional fields', () {
      final jsonWithDefaults = {
        'id': 'comment-123',
        'content_id': 'content-456',
        'user_id': 'user-789',
        'content': 'Test comment',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-02T00:00:00.000Z',
      };

      final result = CommentModel.fromJson(jsonWithDefaults);

      expect(result.parentId, isNull);
      expect(result.likesCount, 0);
      expect(result.replyCount, 0);
      expect(result.isLiked, false);
    });

    test('should convert to Comment entity', () {
      final entity = testModel.toEntity();

      expect(entity.id, 'comment-123');
      expect(entity.contentId, 'content-456');
      expect(entity.userId, 'user-789');
      expect(entity.content, 'Test comment');
      expect(entity.likesCount, 10);
    });
  });
}
