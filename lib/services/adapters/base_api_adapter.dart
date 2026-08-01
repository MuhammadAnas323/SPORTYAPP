import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_strings.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/video_url.dart';
import '../../models/api_connection.dart';
import '../../models/auth_style.dart';
import '../../models/commentary_item.dart';
import '../../models/match_detail.dart';
import '../../models/match_status.dart';
import '../../models/match_summary.dart';
import '../../models/sport_type.dart';
import '../../models/team.dart';
import 'adapter_test_result.dart';
import 'auth_dio.dart';
import 'json_guard.dart';
import 'provider_validators.dart';
import 'provider_validator.dart';
import 'sports_api_adapter.dart';

/// Shared plumbing for all sport adapters.
///
/// Provides the generic connection-test implementation (probes a small set of
/// common root endpoints with the user's key attached) plus tolerant parsing
/// helpers every sport mapping shares. Concrete sports only implement
/// `fetchFeed` and `fetchMatchDetail`.
abstract class BaseApiAdapter implements SportsApiAdapter {
  BaseApiAdapter(this.sportType, this.displayName);

  @override
  final SportType sportType;

  @override
  final String displayName;

  static const Duration _testTimeout = Duration(seconds: 15);

  @override
  Future<AdapterTestResult> testConnection(ApiConnection connection) async {
    final cancelToken = CancelToken();
    final validator = _validatorFor(connection);
    if (validator == null) {
      return AdapterTestResult.failure(
        message:
            'No provider validator is available for this connection. Check the base URL and auth settings.',
      );
    }

    final missingHeaderMessage = _missingRequiredHeaderMessage(connection, validator);
    if (missingHeaderMessage != null) {
      return AdapterTestResult.failure(message: missingHeaderMessage);
    }

    try {
      return await _runTestConnection(connection, validator, cancelToken)
          .timeout(_testTimeout, onTimeout: () {
        cancelToken.cancel('API test timed out after ${_testTimeout.inSeconds}s');
        throw TimeoutException('Connection timed out after ${_testTimeout.inSeconds}s');
      });
    } on TimeoutException {
      return AdapterTestResult.failure(message: AppStrings.connectionTimedOut);
    }
  }

  ProviderValidator? _validatorFor(ApiConnection connection) {
    for (final validator in defaultProviderValidators()) {
      if (validator.supports(connection)) return validator;
    }
    return null;
  }

  String? _missingRequiredHeaderMessage(
    ApiConnection connection,
    ProviderValidator validator,
  ) {
    if (connection.authStyle == AuthStyle.customHeader &&
        (connection.headerName == null || connection.headerName!.trim().isEmpty)) {
      return AppStrings.missingRequiredHeader;
    }
    if (connection.authStyle == AuthStyle.queryParam &&
        (connection.headerName == null || connection.headerName!.trim().isEmpty)) {
      return AppStrings.missingRequiredHeader;
    }

    final requiredHeaders = validator.requiredHeaders(connection);
    final configuredHeaders = {
      for (final key in connection.extraHeaders.keys)
        key.trim().toLowerCase()
    };
    if (connection.authStyle == AuthStyle.customHeader &&
        connection.headerName != null) {
      configuredHeaders.add(connection.headerName!.trim().toLowerCase());
    }
    if (connection.authStyle == AuthStyle.bearer) {
      configuredHeaders.add('authorization');
    }

    for (final requiredHeader in requiredHeaders) {
      if (!configuredHeaders.contains(requiredHeader.toLowerCase())) {
        return AppStrings.missingRequiredHeader;
      }
    }

    final requiredQueryParameters = validator.requiredQueryParameters(connection);
    final configuredQueryParams = <String>{};
    if (connection.authStyle == AuthStyle.queryParam &&
        connection.headerName != null) {
      configuredQueryParams.add(connection.headerName!.trim().toLowerCase());
    }
    for (final requiredQuery in requiredQueryParameters) {
      if (!configuredQueryParams.contains(requiredQuery.toLowerCase())) {
        return AppStrings.missingRequiredHeader;
      }
    }

    return null;
  }

  static List<String> _stringValuesFrom(dynamic body) {
    if (body is String) return [body];
    if (body is Map) {
      return body.values
          .expand(_stringValuesFrom)
          .toList(growable: false);
    }
    if (body is Iterable) {
      return body
          .expand(_stringValuesFrom)
          .toList(growable: false);
    }
    return const [];
  }

  static Duration? _parseDurationFromText(String text) {
    final lower = text.toLowerCase();
    final durationRegexp = RegExp(r'(\d+)\s*(seconds?|secs?|minutes?|mins?|hours?|hrs?)');
    final match = durationRegexp.firstMatch(lower);
    if (match != null) {
      final value = int.tryParse(match.group(1) ?? '');
      if (value != null) {
        final unit = match.group(2);
        if (unit != null) {
          if (unit.startsWith('hour') || unit.startsWith('hr')) {
            return Duration(hours: value);
          }
          if (unit.startsWith('minute') || unit.startsWith('min')) {
            return Duration(minutes: value);
          }
          return Duration(seconds: value);
        }
      }
    }
    return null;
  }

  static Duration? _parseRetryAfter(dynamic value) {
    if (value == null) return null;
    if (value is int) return Duration(seconds: value);
    if (value is double) return Duration(seconds: value.toInt());
    if (value is String) {
      final intSeconds = int.tryParse(value);
      if (intSeconds != null) return Duration(seconds: intSeconds);
      final parsed = _parseDurationFromText(value);
      if (parsed != null) return parsed;
      final dateTime = DateTime.tryParse(value);
      if (dateTime != null) {
        return dateTime.difference(DateTime.now());
      }
    }
    return null;
  }

  static Duration? _retryAfterFromResponse(Response<dynamic> response) {
    final headerValue = response.headers.value('retry-after');
    final fromHeader = _parseRetryAfter(headerValue);
    if (fromHeader != null) return fromHeader;

    final body = response.data;
    final map = JsonGuard.asMap(body);
    if (map != null) {
      final candidate = JsonGuard.pick(map, [
        'retryAfter',
        'retry_after',
        'retry-after',
        'retryIn',
        'retry_in',
      ]);
      final parsed = _parseRetryAfter(candidate);
      if (parsed != null) return parsed;
    }

    final strings = _stringValuesFrom(body);
    for (final value in strings) {
      final parsed = _parseDurationFromText(value);
      if (parsed != null) return parsed;
    }

    return null;
  }

  static String _blockedMessage(Duration? retryAfter) {
    final durationText = retryAfter != null
        ? _humanReadableDuration(retryAfter)
        : 'a few minutes';
    return 'The API provider has temporarily blocked requests. Please wait $durationText before testing again.';
  }

  static String _humanReadableDuration(Duration duration) {
    if (duration.inHours >= 1) {
      final hours = duration.inHours;
      return '$hours hour${hours == 1 ? '' : 's'}';
    }
    if (duration.inMinutes >= 1) {
      final minutes = duration.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'}';
    }
    return '${duration.inSeconds} second${duration.inSeconds == 1 ? '' : 's'}';
  }

  static String? _canonicalBlockMessage(dynamic data, Duration? retryAfter) {
    final strings = _stringValuesFrom(data);
    for (final raw in strings) {
      final lower = raw.toLowerCase();
      if (lower.contains('subscription required')) {
        return AppStrings.subscriptionRequired;
      }
      if (lower.contains('access denied')) {
        return AppStrings.accessDenied;
      }
      if (lower.contains('blocked for') ||
          lower.contains('rate limit exceeded') ||
          lower.contains('too many requests')) {
        return _blockedMessage(retryAfter);
      }
    }
    return null;
  }

  Future<AdapterTestResult> _runTestConnection(
    ApiConnection connection,
    ProviderValidator validator,
    CancelToken cancelToken,
  ) async {
    final dio = buildAuthenticatedDio(connection);
    final startedAt = DateTime.now();
    final path = validator.testEndpoint(connection);
    final uri = Uri.parse(connection.baseUrl).resolve(path);

    debugOnlyLog('API test request: ${uri.toString()}');
    debugOnlyLog('Headers: ${_redactedHeaders(dio.options.headers, connection)}');

    try {
      final response = await dio.get<dynamic>(path, cancelToken: cancelToken);
      debugOnlyLog('API test response status: ${response.statusCode}');
      debugOnlyLog('API test response body: ${response.data}');

      final status = response.statusCode;
      final latency = DateTime.now().difference(startedAt);

      final retryAfter = _retryAfterFromResponse(response);
      if (status != null && status >= 200 && status < 300) {
        final validation = validator.validateResponse(response, connection);
        debugOnlyLog('API test validation result: success=${validation.success} message=${validation.message}');
        if (validation.success) {
          return AdapterTestResult.success(
            latency: latency,
            message: AppStrings.testSuccess,
          );
        }

        final blockedMessage = _canonicalBlockMessage(response.data, retryAfter);
        if (blockedMessage != null) {
          debugOnlyLog('API provider blocked response. retryAfter=$retryAfter body=${response.data}');
          return AdapterTestResult.failure(
            message: blockedMessage,
            latency: latency,
            retryAfter: retryAfter,
          );
        }

        return AdapterTestResult.failure(
          message: validation.message ??
              'The provider response did not validate for the selected API.',
        );
      }

      final errorMessage = validator.parseError(response, connection) ??
          _messageForHttpStatus(status ?? 0);
      final blockedMessage = _canonicalBlockMessage(response.data, retryAfter);
      if (blockedMessage != null) {
        debugOnlyLog('API provider blocked response. retryAfter=$retryAfter body=${response.data}');
        return AdapterTestResult.failure(
          message: blockedMessage,
          latency: latency,
          retryAfter: retryAfter,
        );
      }
      debugOnlyLog('API test failure reason: $errorMessage');

      if (status == 401) {
        return AdapterTestResult.failure(message: AppStrings.invalidApiKey);
      }
      if (status == 403) {
        return AdapterTestResult.failure(message: AppStrings.accessDenied);
      }
      if (status == 402) {
        return AdapterTestResult.failure(message: AppStrings.subscriptionRequired);
      }
      if (status == 429) {
        return AdapterTestResult.failure(message: AppStrings.rateLimited);
      }
      if (status == 404) {
        return AdapterTestResult.failure(message: AppStrings.invalidBaseUrl);
      }

      return AdapterTestResult.failure(message: errorMessage);
    } on DioException catch (error) {
      debugOnlyLog('API test error: ${error.message}');
      debugOnlyLog('API test error response: ${error.response?.data}');

      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        throw readableNetworkError(
          error,
          host: connection.baseUrl,
          keyName: connection.label,
        );
      }
      if (status == 429) {
        final retryAfter = _retryAfterFromResponse(error.response!);
        final blockedMessage = _canonicalBlockMessage(error.response?.data, retryAfter);
        if (blockedMessage != null) {
          debugOnlyLog('API provider blocked response. retryAfter=$retryAfter body=${error.response?.data}');
          return AdapterTestResult.failure(
            message: blockedMessage,
            retryAfter: retryAfter,
          );
        }
        return AdapterTestResult.failure(
          message: AppStrings.rateLimited,
        );
      }
      if (status == 404) {
        return AdapterTestResult.failure(message: AppStrings.invalidBaseUrl);
      }
      if (error.error is FormatException) {
        return AdapterTestResult.failure(message: AppStrings.invalidJsonResponse);
      }
      throw readableNetworkError(error, host: connection.baseUrl);
    }
  }

  @protected
  String? validateProbeResponse(
    ApiConnection connection,
    Response response,
    String path,
  ) {
    final data = response.data;
    if (data == null) {
      return 'Empty response received from $path.';
    }
    if (_looksLikeHtml(data)) {
      return AppStrings.invalidJsonResponse;
    }
    if (data is String) {
      return 'Unexpected text response. Expected JSON.';
    }
    if (data is num || data is bool) {
      return 'Unexpected non-JSON payload. Expected a JSON object or array.';
    }

    if (data is List && data.isEmpty) {
      return 'Empty data returned from $path.';
    }
    if (data is Map && data.isEmpty) {
      return 'Empty JSON object returned from $path.';
    }

    return null;
  }

  static bool _looksLikeHtml(dynamic body) {
    if (body is String) {
      final trimmed = body.trimLeft();
      return trimmed.startsWith('<!DOCTYPE') || trimmed.startsWith('<html');
    }
    return false;
  }

  String _redactedHeaders(
    Map<String, dynamic> headers,
    ApiConnection connection,
  ) {
    final sanitized = Map<String, dynamic>.from(headers);
    sanitized.remove('Authorization');
    if (connection.authStyle == AuthStyle.customHeader &&
        connection.headerName != null) {
      sanitized.remove(connection.headerName!);
    }
    return sanitized.toString();
  }

  String _messageForHttpStatus(int status) {
    if (status == 400) {
      return 'Bad request (HTTP 400). Check the URL and request format.';
    }
    if (status == 401) {
      return AppStrings.invalidApiKey;
    }
    if (status == 403) {
      return AppStrings.accessDenied;
    }
    if (status == 402) {
      return AppStrings.subscriptionRequired;
    }
    if (status == 404) {
      return AppStrings.invalidBaseUrl;
    }
    if (status == 429) {
      return AppStrings.rateLimited;
    }
    if (status >= 500) {
      return 'Server error (HTTP $status). Try again later.';
    }
    return 'The host responded with HTTP $status. Verify the base URL and key.';
  }

  /// Remembered per-host feed path so a refresh re-uses the endpoint that
  /// last returned matches instead of re-probing every candidate (cheap on a
  /// rate-limited key).
  static final Map<String, String> _workingPathByBaseUrl = {};

  /// Returns [candidates] with the last-known-good path for [baseUrl] moved to
  /// the front (when one exists).
  List<String> orderedFeedPaths(String baseUrl, List<String> candidates) {
    final known = _workingPathByBaseUrl[baseUrl];
    if (known == null) return candidates;
    return [known, ...candidates.where((p) => p != known)];
  }

  void rememberWorkingFeedPath(String baseUrl, String path) {
    _workingPathByBaseUrl[baseUrl] = path;
  }

  /// Detects an API-level error hidden inside an HTTP 2xx body.
  ///
  /// Several sport hosts (CricAPI included) answer a rejected key with
  /// **HTTP 200** plus `{"status":"failure","reason":"..."}` (or
  /// `{"success":false,"message":"..."}`), so reachability alone must never
  /// count as a passing test. Returns a readable message when the body is such
  /// an error envelope, else `null`.
  static String? apiErrorInBody(dynamic body) {
    final map = JsonGuard.asMap(body);
    if (map == null) return null;

    final success = JsonGuard.asBool(
      JsonGuard.pick(map, ['success', 'ok']),
      fallback: true,
    );
    final status = JsonGuard.asString(JsonGuard.pick(map, ['status', 'code']));
    final statusLower = (status ?? '').toLowerCase();

    if (!success) {
      return _reasonFrom(map) ?? 'The API rejected the request.';
    }
    if (statusLower == 'failure' ||
        statusLower == 'failed' ||
        statusLower == 'error' ||
        statusLower == 'unauthorized' ||
        statusLower == 'forbidden' ||
        statusLower == 'invalid') {
      return _reasonFrom(map) ?? 'The API rejected the request ($status).';
    }

    final errors = JsonGuard.pick(map, ['errors', 'error']);
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      final message = JsonGuard.asString(first) ?? _reasonFrom(JsonGuard.asMap(first) ?? {});
      return message ?? 'The API returned an error object.';
    }
    if (errors is Map) {
      final typedErrors = JsonGuard.asMap(errors);
      return _reasonFrom(typedErrors ?? {}) ?? 'The API returned an error object.';
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

  /// Navigates to the first list of match objects, tolerant of the many
  /// wrappers providers use: bare arrays, `data`, `response`, `matches`,
  /// `fixtures`, or nested `data.matches`. Direct wrapper keys match
  /// case-insensitively (`Data`, `Matches`, …).
  List<Map<String, dynamic>> findMatchList(dynamic body) {
    if (body is List) {
      return _mapsOnly(body);
    }
    final map = JsonGuard.asMap(body);
    if (map == null) return const [];

    const nestedWrappers = [
      'data.matches',
      'data.fixtures',
      'data.data',
      'data.response',
      'api.matches',
      'api.fixtures',
      'results.matches',
    ];
    const wrappers = [
      'matches',
      'fixtures',
      'events',
      'games',
      'data',
      'response',
      'results',
      'current',
      'currentMatches',
      'upcoming',
      'live',
    ];

    final lowerToKey = {
      for (final key in map.keys) key.toLowerCase(): key,
    };

    // Nested paths first: a `data` object holding `matches` must be read
    // before `data` itself is (mis)taken for a list of values.
    for (final wrapper in nestedWrappers) {
      final nested = JsonGuard.pickValuePath(map, wrapper);
      final list = nested == null ? null : JsonGuard.asList(nested);
      if (list != null && list.isNotEmpty) return _mapsOnly(list);
    }

    for (final wrapper in wrappers) {
      final actualKey = lowerToKey[wrapper.toLowerCase()];
      if (actualKey == null) continue;
      final list = JsonGuard.asList(map[actualKey]);
      if (list.isNotEmpty) return _mapsOnly(list);
    }
    return const [];
  }

  static List<Map<String, dynamic>> _mapsOnly(List<dynamic> list) => list
      .map(JsonGuard.asMap)
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);

  /// Builds a normalized [Team] from the many team shapes seen in the wild.
  Team buildTeam(Map<String, dynamic> map, {String? fallbackName}) {
    final name = JsonGuard.asString(
      JsonGuard.pick(map, ['name', 'teamName', 'fullName', 'long_name', 'title']),
    );
    final short = JsonGuard.asString(
      JsonGuard.pick(map, [
        'shortName',
        'shortname',
        'short_name',
        'code',
        'abbreviation',
        'short',
      ]),
    );
    final logo = JsonGuard.asString(
      JsonGuard.pick(map, ['logo', 'logoUrl', 'image', 'flag', 'icon']),
    );
    final id = JsonGuard.asString(JsonGuard.pick(map, ['id', 'teamId', 'team_id']));

    return Team(
      id: id,
      name: (name ?? fallbackName)?.isNotEmpty == true ? name! : fallbackName ?? 'Unknown',
      shortName: short,
      logoUrl: logo,
    );
  }

  /// Best-effort [TeamScore] from a team map and a score text.
  TeamScore buildCricketScore({
    required Team team,
    String? scoreText,
    int? runs,
    int? wickets,
    double? overs,
    String? rawScore,
  }) {
    final parsed = _parseCricketScore(rawScore);
    return TeamScore(
      team: team,
      runs: runs ?? parsed.$1,
      wickets: wickets ?? parsed.$2,
      overs: overs ?? parsed.$3,
      displayScore: scoreText,
    );
  }

  /// Parses "178/4 (20)", "178/4", "178", "178-4" into (runs, wickets, overs).
  (int?, int?, double?) _parseCricketScore(String? text) {
    if (text == null) return (null, null, null);
    final t = text.trim();
    if (t.isEmpty) return (null, null, null);

    final overMatch = RegExp(r'\((\d{1,3}(?:\.\d)?)\)').firstMatch(t);
    final scoreMatch = RegExp(r'(\d{1,4})\s*(?:[/-]\s*(\d{1,2}))?')
        .firstMatch(t.replaceAll(RegExp(r'\(.*?\)'), ''));

    final runsText = scoreMatch?.group(1);
    final wicketsText = scoreMatch?.group(2);
    final oversText = overMatch?.group(1);

    int? runs = runsText != null ? int.tryParse(runsText) : null;
    int? wickets = wicketsText != null ? int.tryParse(wicketsText) : null;
    double? overs = oversText != null ? double.tryParse(oversText) : null;
    return (runs, wickets, overs);
  }

  /// Maps a raw status phrase to a [MatchStatus], sport-aware.
  MatchStatus statusFromText(String? text, {String sport = 'cricket'}) {
    final t = (text ?? '').trim().toLowerCase();
    if (sport == 'football') {
      if (t.contains('ft') || t.contains('full time') || t.contains('finished') ||
          t.contains('aet') || t.contains('awarded')) {
        return MatchStatus.completed;
      }
      if (t == 'ns' || t.contains('not started') || t.contains('tbd') ||
          t.contains('postponed') || t.contains('scheduled')) {
        return MatchStatus.scheduled;
      }
      if (t == '1h' || t == '2h' || t == 'ht' || t.contains('first half') ||
          t.contains('second half') || t.contains('halftime') ||
          t.contains('in play') || t.contains('live') || t.contains('break') ||
          t.contains('pen')) {
        return MatchStatus.live;
      }
      if (t.contains('cancel')) return MatchStatus.cancelled;
      if (t.contains('abandon') || t.contains('void')) return MatchStatus.abandoned;
      return MatchStatus.scheduled;
    }

    // Cricket.
    if (t.contains('live') || t.contains('innings break') ||
        t.contains('drinks') || t.contains('tea') || t.contains('lunch')) {
      return MatchStatus.live;
    }
    if (t.contains('end') || t.contains('complete') || t.contains('result') ||
        t.contains('all out') || t.contains('won')) {
      return MatchStatus.completed;
    }
    if (t.contains('cancel')) return MatchStatus.cancelled;
    if (t.contains('abandon')) return MatchStatus.abandoned;
    return MatchStatus.scheduled;
  }

  /// A detail request that only fails hard when the whole host is unreachable;
  /// a 404/405 just means "no detail endpoint" and yields an empty detail.
  @protected
  Future<MatchDetail> bestEffortDetail(
    ApiConnection connection,
    MatchSummary match,
    MatchDetail Function(dynamic body) parse,
  ) async {
    final dio = buildAuthenticatedDio(connection);
    final candidates = [
      '/match/${match.providerId}',
      '/matches/${match.providerId}',
      '/${match.providerId}',
      '/match?id=${match.providerId}',
    ];
    for (final path in candidates) {
      try {
        final response = await dio.get<dynamic>(path);
        if (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          return parse(response.data);
        }
      } on DioException catch (error) {
        final status = error.response?.statusCode;
        if (status == 401 || status == 403) continue;
        if (status != null && status < 500) continue;
      }
    }
    // No detail endpoint answered — honest empty detail, tabs will hide.
    return MatchDetail(summary: match);
  }

  /// Safely reads raw commentary-ish items into normalized commentary.
  List<CommentaryItem> mapCommentary(
    List<dynamic> items, {
    bool cricket = true,
  }) {
    final result = <CommentaryItem>[];
    for (final item in items) {
      final map = JsonGuard.asMap(item);
      if (map == null) continue;
      final text = JsonGuard.asString(
        JsonGuard.pick(map, ['text', 'commentary', 'detail', 'event', 'desc', 'description']),
      );
      if (text == null) continue;
      final highlight = JsonGuard.asBool(
        JsonGuard.pick(map, ['isHighlight', 'highlight', 'isWicket', 'isGoal', 'keyEvent', 'isKeyEvent']),
      );
      result.add(
        CommentaryItem(
          id: JsonGuard.asString(JsonGuard.pick(map, ['id', 'commentaryId'])),
          over: cricket
              ? JsonGuard.asString(JsonGuard.pick(map, ['over', 'ball', 'overNumber']))
              : null,
          minute: !cricket
              ? JsonGuard.asString(JsonGuard.pick(map, ['minute', 'time', 'elapsed']))
              : null,
          text: text,
          timestamp: _parseDate(
            JsonGuard.pick(map, ['timestamp', 'time', 'date', 'createdAt']),
          ),
          isHighlight: highlight,
        ),
      );
    }
    return result;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      return value > 1000000000000
          ? DateTime.fromMillisecondsSinceEpoch(value)
          : DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Public access to defensive date parsing for subclasses.
  DateTime? parseDate(dynamic value) => _parseDate(value);

  // ---- Live video stream detection ------------------------------------------

  /// Known JSON keys that may carry a live video stream URL.
  static const List<String> _videoKeys = [
    'videoUrl',
    'video_url',
    'liveUrl',
    'live_url',
    'streamUrl',
    'stream_url',
    'hls',
    'hlsUrl',
    'hls_url',
    'dash',
    'dashUrl',
    'dash_url',
    'playback',
    'playbackUrl',
    'playback_url',
    'video',
    'stream',
    'streams',
    'source',
    'sources',
    'media',
    'url',
  ];

  /// Recursively searches [value] (string, map or list) for the first string
  /// that looks like a playable live-stream URL.
  String? _findVideoUrl(dynamic value) {
    if (value is String) {
      return MatchVideoUrl.isPlayable(value) ? value : null;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        final found = _findVideoUrl(entry.value);
        if (found != null) return found;
      }
      return null;
    }
    if (value is List) {
      for (final item in value) {
        final found = _findVideoUrl(item);
        if (found != null) return found;
      }
      return null;
    }
    return null;
  }

  /// Reads a live video stream URL from a match object by checking the known
  /// video fields (including nested objects/lists) and validating the format.
  /// Returns `null` when the provider offers no playable stream.
  String? readVideoUrl(Map<String, dynamic> item) {
    for (final key in _videoKeys) {
      if (!item.containsKey(key)) continue;
      final found = _findVideoUrl(item[key]);
      if (found != null) return found;
    }
    return null;
  }
}
