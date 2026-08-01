import 'package:dio/dio.dart';

import '../../models/api_connection.dart';

/// Result returned by a provider-specific test validator.
class ProviderValidationResult {
  const ProviderValidationResult._({required this.success, this.message});

  const ProviderValidationResult.success([this.message]) : success = true;

  const ProviderValidationResult.failure(this.message) : success = false;

  final bool success;
  final String? message;
}

/// A provider-specific validator defines the official test endpoint and the
/// rules used to verify the response body for a single API provider.
abstract class ProviderValidator {
  /// Human-readable provider name for debug logs.
  String get providerName;

  /// Whether this validator applies to the configured connection.
  bool supports(ApiConnection connection);

  /// The official test endpoint for the provider, relative to the configured
  /// base URL.
  String testEndpoint(ApiConnection connection);

  /// Headers that must be present on the final request before the test runs.
  /// The auth header/query parameter itself is validated separately.
  List<String> requiredHeaders(ApiConnection connection) => const [];

  /// Query parameters that must be present on the final request.
  List<String> requiredQueryParameters(ApiConnection connection) => const [];

  /// Validates a successful HTTP response for the provider.
  ProviderValidationResult validateResponse(
    Response<dynamic> response,
    ApiConnection connection,
  );

  /// Parses an exact provider error message from the response when available.
  String? parseError(
    Response<dynamic> response,
    ApiConnection connection,
  );
}
