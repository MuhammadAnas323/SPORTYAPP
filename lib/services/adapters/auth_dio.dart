import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../models/api_connection.dart';
import '../../models/auth_style.dart';

/// Builds a [Dio] client wired for one user-supplied connection.
///
/// The interceptor attaches the key exactly once, per the connection's
/// [AuthStyle], so adapters can call plain `dio.get(path)` and the right
/// header/query is already in place. Keys are **never** logged.
Dio buildAuthenticatedDio(ApiConnection connection, {String? baseUrl}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? connection.baseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
      followRedirects: true,
      maxRedirects: 3,
      headers: {
        'Accept': 'application/json',
        ...connection.extraHeaders,
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        switch (connection.authStyle) {
          case AuthStyle.bearer:
            options.headers['Authorization'] = 'Bearer ${connection.apiKey}';
          case AuthStyle.customHeader:
            options.headers[connection.headerName ?? 'X-Api-Key'] =
                connection.apiKey;
          case AuthStyle.queryParam:
            options.queryParameters[connection.headerName ?? 'api_key'] =
                connection.apiKey;
        }
        handler.next(options);
      },
      onError: (e, handler) {
        // Never surface the key in an error path.
        handler.next(e);
      },
    ),
  );

  return dio;
}

/// Maps a [DioException] to a readable [AppException] for the test flow.
AppException readableNetworkError(
  DioException e, {
  required String host,
  String? keyName,
}) {
  final status = e.response?.statusCode;
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return InvalidHostException(
      'Request timed out after ${e.requestOptions.connectTimeout?.inSeconds ?? 12}s — '
      'check the base URL and your network.',
      cause: e,
    );
  }
  if (e.type == DioExceptionType.connectionError) {
    return InvalidHostException(
      'Could not reach $host. Check the base URL and your internet connection.',
      cause: e,
    );
  }
  if (status == 401 || status == 403) {
    return UnauthorizedException(
      'The host rejected ${keyName ?? 'your key'} (HTTP $status). '
      'Double-check the key and auth style.',
      cause: e,
    );
  }
  if (status != null) {
    if (status == 404) {
      return InvalidHostException(
        'The host returned 404 at the base URL. You may be missing a path.',
        cause: e,
      );
    }
    return AdapterException(
      'The host responded with HTTP $status.',
      cause: e,
    );
  }
  return AdapterException('Network error: ${e.message ?? e.type.name}.',
      cause: e);
}
