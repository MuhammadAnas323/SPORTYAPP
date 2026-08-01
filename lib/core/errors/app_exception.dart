import 'package:flutter/foundation.dart';

/// Root exception hierarchy for SportSync.
///
/// Every failure surfaced to the UI (adapter failures, repository failures,
/// network errors) is normalised into an [AppException] so ViewModels can show
/// a single, readable error message without leaking provider-specific details.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  /// Human-readable message safe to show in the UI.
  final String message;

  /// The underlying error, when one exists (never rendered, but kept for
  /// debugging).
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Raised when a user-supplied connection fails its test or feed fetch.
class AdapterException extends AppException {
  const AdapterException(super.message, {super.cause});
}

/// Raised when a remote response exists but does not match any recognised
/// shape the adapter understands.
class UnexpectedResponseException extends AdapterException {
  const UnexpectedResponseException(super.message, {super.cause});
}

/// Raised when the configured host/URL is invalid or unreachable.
class InvalidHostException extends AdapterException {
  const InvalidHostException(super.message, {super.cause});
}

/// Raised when the host rejects the configured credentials.
class UnauthorizedException extends AdapterException {
  const UnauthorizedException(super.message, {super.cause});
}

/// Raised by the local persistence layer (secure storage / preferences).
class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}

/// Raised when Firebase authentication fails (bad credentials, disabled
/// account, network error during sign-in, etc.).
class AuthException extends AppException {
  const AuthException(super.message, {super.cause});
}

/// Raised when a requested entity (connection, match) does not exist.
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.cause});
}

/// Generic catch-all for non-[AppException] errors surfaced at layer boundaries.
class UnknownException extends AppException {
  const UnknownException(super.message, {super.cause});
}

/// Maps any caught error into an [AppException] with a readable message.
///
/// Used at the boundary between adapters / repositories and ViewModels.
AppException normalizeError(Object error, {StackTrace? stackTrace}) {
  if (error is AppException) return error;
  if (error is Exception) {
    return UnknownException(error.toString(), cause: error);
  }
  return UnknownException('Unexpected error: ${error.runtimeType}', cause: error);
}

/// Convenience for throwing during debug builds only.
void debugOnlyLog(Object message, [StackTrace? stack]) {
  debugPrint('SportSync: $message');
  if (stack != null) debugPrintStack(stackTrace: stack);
}
