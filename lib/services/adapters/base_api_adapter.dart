import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/utils/video_url.dart';
import '../../models/api_connection.dart';
import '../../models/commentary_item.dart';
import '../../models/match_detail.dart';
import '../../models/match_status.dart';
import '../../models/match_summary.dart';
import '../../models/sport_type.dart';
import '../../models/team.dart';
import 'adapter_test_result.dart';
import 'auth_dio.dart';
import 'json_guard.dart';
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

  /// Endpoints probed in order during a connection test. The first 2xx wins;
  /// 401/403 stops immediately (bad key), other non-2xx moves to the next
  /// candidate because many hosts 404 on `/` while the real API lives under
  /// `/v1` or `/api`.
  static const List<String> _probePaths = [
    '/',
    '/health',
    '/api',
    '/v1',
    '/matches',
    '/fixtures',
    '/v1/matches',
  ];

  @override
  Future<AdapterTestResult> testConnection(ApiConnection connection) async {
    final dio = buildAuthenticatedDio(connection);
    final startedAt = DateTime.now();

    for (final path in _probePaths) {
      try {
        final response = await dio.get<dynamic>(path);
        final latency = DateTime.now().difference(startedAt);
        if (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          return AdapterTestResult.success(latency: latency);
        }
      } on DioException catch (error) {
        final status = error.response?.statusCode;
        if (status == 401 || status == 403) {
          // Key was definitively rejected — no point probing more paths.
          throw readableNetworkError(
            error,
            host: connection.baseUrl,
            keyName: connection.label,
          );
        }
        if (status != null && status < 500) {
          // 4xx on a probe path is likely "wrong path", not "wrong key".
          continue;
        }
        throw readableNetworkError(error, host: connection.baseUrl);
      }
    }

    return const AdapterTestResult.failure(
      message:
          'The host did not answer any common endpoint (/, /health, /api, /v1, '
          '/matches). Verify the base URL includes the right path.',
    );
  }

  /// Navigates to the first list of match objects, tolerant of the many
  /// wrappers providers use: bare arrays, `data`, `response`, `matches`,
  /// `fixtures`, or nested `data.matches`.
  List<Map<String, dynamic>> findMatchList(dynamic body) {
    if (body is List) {
      return _mapsOnly(body);
    }
    final map = JsonGuard.asMap(body);
    if (map == null) return const [];

    const wrappers = [
      'matches',
      'fixtures',
      'events',
      'games',
      'data',
      'response',
      'results',
      'data.matches',
      'data.fixtures',
      'data.data',
      'api.matches',
      'api.fixtures',
    ];
    for (final wrapper in wrappers) {
      if (wrapper.contains('.')) {
        final nested = JsonGuard.pickPath(map, wrapper);
        final list = nested == null ? null : JsonGuard.asList(nested);
        if (list != null && list.isNotEmpty) return _mapsOnly(list);
        continue;
      }
      if (map.containsKey(wrapper)) {
        final list = JsonGuard.asList(map[wrapper]);
        if (list.isNotEmpty) return _mapsOnly(list);
      }
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
