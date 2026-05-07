import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_event.freezed.dart';

@freezed
abstract class AuthEvent with _$AuthEvent {
  const factory AuthEvent.authCheckRequested() = _AuthCheckRequested;
  const factory AuthEvent.loginRequested({
    required String email,
    required String password,
  }) = _LoginRequested;
  const factory AuthEvent.registerRequested({
    required String email,
    required String password,
    String? username,
  }) = _RegisterRequested;
  const factory AuthEvent.logoutRequested() = _LogoutRequested;
  const factory AuthEvent.passwordResetRequested(String email) = _PasswordResetRequested;
  const factory AuthEvent.profileUpdateRequested({
    String? username,
    String? avatarUrl,
    String? bio,
  }) = _ProfileUpdateRequested;
}
