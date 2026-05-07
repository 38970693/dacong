import 'package:freezed_annotation/freezed_annotation.dart';
import 'user.dart';

part 'auth_session.freezed.dart';

@freezed
abstract class AuthSession with _$AuthSession {
  const factory AuthSession({
    required String accessToken,
    required String refreshToken,
    required User user,
    required DateTime expiresAt,
  }) = _AuthSession;
}
