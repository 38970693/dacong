import 'package:flutter_test/flutter_test.dart';
import 'package:dacong_client/data/models/user_profile_model.dart';

void main() {
  group('UserProfile Model', () {
    final testJson = {
      'id': 'user-123',
      'username': 'testuser',
      'avatar_url': 'https://example.com/avatar.jpg',
      'bio': 'Test bio',
      'created_at': '2024-01-01T00:00:00.000Z',
      'updated_at': '2024-01-02T00:00:00.000Z',
      'post_count': 10,
      'follower_count': 100,
      'following_count': 50,
    };

    final testProfile = UserProfile(
      id: 'user-123',
      username: 'testuser',
      avatarUrl: 'https://example.com/avatar.jpg',
      bio: 'Test bio',
      createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      updatedAt: DateTime.parse('2024-01-02T00:00:00.000Z'),
      postCount: 10,
      followerCount: 100,
      followingCount: 50,
    );

    test('should create UserProfile from JSON', () {
      final result = UserProfile.fromJson(testJson);

      expect(result.id, 'user-123');
      expect(result.username, 'testuser');
      expect(result.avatarUrl, 'https://example.com/avatar.jpg');
      expect(result.bio, 'Test bio');
      expect(result.postCount, 10);
      expect(result.followerCount, 100);
      expect(result.followingCount, 50);
    });

    test('should convert UserProfile to JSON', () {
      final result = testProfile.toJson();

      expect(result['id'], 'user-123');
      expect(result['username'], 'testuser');
      expect(result['avatar_url'], 'https://example.com/avatar.jpg');
      expect(result['bio'], 'Test bio');
      expect(result['created_at'], '2024-01-01T00:00:00.000Z');
    });

    test('should handle null optional fields', () {
      final jsonWithNulls = {
        'id': 'user-123',
        'username': 'testuser',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-02T00:00:00.000Z',
      };

      final result = UserProfile.fromJson(jsonWithNulls);

      expect(result.avatarUrl, isNull);
      expect(result.bio, isNull);
      expect(result.postCount, isNull);
      expect(result.followerCount, isNull);
      expect(result.followingCount, isNull);
    });

    test('should copy UserProfile with new values', () {
      final copied = testProfile.copyWith(
        username: 'newusername',
        bio: 'New bio',
      );

      expect(copied.id, 'user-123');
      expect(copied.username, 'newusername');
      expect(copied.bio, 'New bio');
      expect(copied.avatarUrl, 'https://example.com/avatar.jpg');
    });

    test('should copy UserProfile without changes', () {
      final copied = testProfile.copyWith();

      expect(copied.id, testProfile.id);
      expect(copied.username, testProfile.username);
      expect(copied.bio, testProfile.bio);
    });
  });
}
