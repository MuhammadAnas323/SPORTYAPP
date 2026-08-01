import 'package:dio/dio.dart';

import '../../core/constants/app_strings.dart';
import '../../models/api_connection.dart';
import 'json_guard.dart';
import 'provider_validator.dart';

/// Generic shape validator that can be reused across providers.
class ShapeProviderValidator implements ProviderValidator {
  ShapeProviderValidator({
    required this.providerName,
    required this.supportsConnection,
    required this.testEndpointFor,
    this.requiredHeadersFor = _emptyHeaders,
    this.requiredQueryParametersFor = _emptyHeaders,
    required this.bodyRecognizer,
    this.errorParser,
  });

  @override
  final String providerName;

  final bool Function(ApiConnection connection) supportsConnection;

  final String Function(ApiConnection connection) testEndpointFor;

  final List<String> Function(ApiConnection connection) requiredHeadersFor;

  final List<String> Function(ApiConnection connection) requiredQueryParametersFor;

  final bool Function(dynamic body) bodyRecognizer;
  final String? Function(Response<dynamic>, ApiConnection)? errorParser;

  static List<String> _emptyHeaders(ApiConnection _) => const [];

  @override
  bool supports(ApiConnection connection) => supportsConnection(connection);

  @override
  String testEndpoint(ApiConnection connection) => testEndpointFor(connection);

  @override
  List<String> requiredHeaders(ApiConnection connection) =>
      requiredHeadersFor(connection);

  @override
  List<String> requiredQueryParameters(ApiConnection connection) =>
      requiredQueryParametersFor(connection);

  @override
  ProviderValidationResult validateResponse(
    Response<dynamic> response,
    ApiConnection connection,
  ) {
    final body = response.data;
    if (body == null) {
      return const ProviderValidationResult.failure('Empty response body.');
    }

    if (_looksLikeHtml(body)) {
      return const ProviderValidationResult.failure(AppStrings.invalidJsonResponse);
    }

    if (body is String) {
      return const ProviderValidationResult.failure(
        'Unexpected text response. Expected JSON.',
      );
    }

    final error = parseError(response, connection);
    if (error != null) {
      return ProviderValidationResult.failure(error);
    }

    if (!bodyRecognizer(body)) {
      return ProviderValidationResult.failure(
        'The response body did not match the expected shape for $providerName.',
      );
    }

    return const ProviderValidationResult.success();
  }

  @override
  String? parseError(Response<dynamic> response, ApiConnection connection) {
    if (errorParser != null) {
      return errorParser!(response, connection);
    }
    return _parseProviderError(response.data);
  }

  static bool _looksLikeHtml(dynamic body) {
    if (body is String) {
      final trimmed = body.trimLeft();
      return trimmed.startsWith('<!DOCTYPE') || trimmed.startsWith('<html');
    }
    return false;
  }

  static String? _parseProviderError(dynamic body) {
    final map = JsonGuard.asMap(body);
    if (map == null) return null;

    final status = JsonGuard.asString(JsonGuard.pick(map, ['status', 'code']))
        ?.toLowerCase();
    if (status == 'error' || status == 'failed' || status == 'failure') {
      return _reasonFrom(map) ?? 'The API rejected the request.';
    }

    if (!JsonGuard.asBool(JsonGuard.pick(map, ['success', 'ok']), fallback: true)) {
      return _reasonFrom(map) ?? 'The API rejected the request.';
    }

    final errorValue = JsonGuard.pick(map, [
      'error',
      'errors',
      'message',
      'reason',
      'detail',
    ]);

    if (errorValue is String) return errorValue;
    if (errorValue is Map) return _reasonFrom(JsonGuard.asMap(errorValue) ?? {});
    if (errorValue is List && errorValue.isNotEmpty) {
      final first = errorValue.first;
      if (first is String) return first;
      if (first is Map) return _reasonFrom(JsonGuard.asMap(first) ?? {});
    }
    return null;
  }

  static String? _reasonFrom(Map<String, dynamic> map) {
    return JsonGuard.asString(
      JsonGuard.pick(map, [
        'reason',
        'message',
        'msg',
        'error_description',
        'detail',
        'error',
      ]),
    );
  }
}

List<ProviderValidator> defaultProviderValidators() => [
      ShapeProviderValidator(
        providerName: 'API-SPORTS',
        supportsConnection: (connection) {
          final url = connection.baseUrl.toLowerCase();
          return url.contains('api-sports.io') ||
              url.contains('api-football.com') ||
              url.contains('api-cricket.com') ||
              connection.extraHeaders.keys
                  .any((key) => key.toLowerCase() == 'x-apisports-key') ||
              connection.headerName?.toLowerCase() == 'x-apisports-key';
        },
        testEndpointFor: (_) => '/status',
        requiredHeadersFor: (_) => const ['x-apisports-key'],
        bodyRecognizer: (body) {
          final map = JsonGuard.asMap(body);
          if (map == null) return false;
          if (JsonGuard.asMap(map['response']) != null) return true;
          if (JsonGuard.asList(map['response']).isNotEmpty) return true;
          if (JsonGuard.asBool(JsonGuard.pick(map, ['success', 'ok']), fallback: false)) {
            return true;
          }
          return map.containsKey('parameters') || map.containsKey('errors');
        },
      ),
      ShapeProviderValidator(
        providerName: 'RapidAPI',
        supportsConnection: (connection) {
          final url = connection.baseUrl.toLowerCase();
          return url.contains('rapidapi.com') ||
              connection.extraHeaders.keys
                  .any((key) => key.toLowerCase() == 'x-rapidapi-key') ||
              connection.extraHeaders.keys
                  .any((key) => key.toLowerCase() == 'x-rapidapi-host') ||
              connection.headerName?.toLowerCase() == 'x-rapidapi-key' ||
              connection.headerName?.toLowerCase() == 'x-rapidapi-host';
        },
        testEndpointFor: (_) => '/',
        requiredHeadersFor: (_) => const ['x-rapidapi-key', 'x-rapidapi-host'],
        bodyRecognizer: (body) {
          final map = JsonGuard.asMap(body);
          if (map == null) return false;
          if (map.containsKey('response') || map.containsKey('data')) return true;
          if (map.containsKey('errors') || map.containsKey('error')) return true;
          final status = JsonGuard.asString(JsonGuard.pick(map, ['status', 'result', 'ok']))?.toLowerCase();
          return status == 'ok' || status == 'success';
        },
      ),
      ShapeProviderValidator(
        providerName: 'CricAPI',
        supportsConnection: (connection) {
          final url = connection.baseUrl.toLowerCase();
          return url.contains('cricapi.com') || url.contains('cricketapi.com');
        },
        testEndpointFor: (_) => '/',
        bodyRecognizer: (body) {
          final map = JsonGuard.asMap(body);
          if (map == null) return false;
          if (JsonGuard.asBool(JsonGuard.pick(map, ['success', 'ok']), fallback: false)) {
            return true;
          }
          if (JsonGuard.asString(JsonGuard.pick(map, ['status', 'message', 'result'])) != null) {
            return true;
          }
          return JsonGuard.asList(map['data']).isNotEmpty || JsonGuard.asList(map['matches']).isNotEmpty;
        },
      ),
      ShapeProviderValidator(
        providerName: 'Cricbuzz',
        supportsConnection: (connection) {
          final url = connection.baseUrl.toLowerCase();
          return url.contains('cricbuzz.com') || url.contains('cricbuzz');
        },
        testEndpointFor: (_) => '/',
        bodyRecognizer: (body) {
          final map = JsonGuard.asMap(body);
          if (map == null) return false;
          if (map.containsKey('score') || map.containsKey('match') || map.containsKey('series')) {
            return true;
          }
          return JsonGuard.asList(map['matches']).isNotEmpty || JsonGuard.asList(map['data']).isNotEmpty;
        },
      ),
      ShapeProviderValidator(
        providerName: 'Football-Data',
        supportsConnection: (connection) {
          final url = connection.baseUrl.toLowerCase();
          return url.contains('football-data.org') || url.contains('football-data');
        },
        testEndpointFor: (_) => '/v2/competitions',
        requiredHeadersFor: (_) => const ['x-auth-token'],
        bodyRecognizer: (body) {
          final map = JsonGuard.asMap(body);
          if (map == null) return false;
          return map.containsKey('competitions') || map.containsKey('count');
        },
      ),
    ];
