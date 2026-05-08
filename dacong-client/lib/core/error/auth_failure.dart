import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_failure.freezed.dart';

@freezed
abstract class AuthFailure with _$AuthFailure {
  const factory AuthFailure.invalidCredentials() = _InvalidCredentials;
  const factory AuthFailure.emailAlreadyInUse() = _EmailAlreadyInUse;
  const factory AuthFailure.weakPassword() = _WeakPassword;
  const factory AuthFailure.userNotFound() = _UserNotFound;
  const factory AuthFailure.emailNotVerified() = _EmailNotVerified;
  const factory AuthFailure.networkError() = _NetworkError;
  const factory AuthFailure.emailRateLimit() = _EmailRateLimit;
  const factory AuthFailure.serverError(String message) = _ServerError;
  const factory AuthFailure.unknown(String message) = _Unknown;
}
