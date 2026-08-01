import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../models/api_connection.dart';
import '../../models/commentary_item.dart';
import '../../models/match_detail.dart';
import '../../models/match_status.dart';
import '../../models/match_summary.dart';
import '../../models/player.dart';
import '../../models/sport_type.dart';
import '../../models/team.dart';
import 'auth_dio.dart';
import 'base_api_adapter.dart';
import 'json_guard.dart';

/// Football adapter — maps the raw JSON of whichever football API the user
/// connected into normalized [MatchSummary] / [MatchDetail] models.
///
/// It understands the two dominant conventions (API-Football's nested
/// `fixture`/`teams`/`goals` objects and football-data.org's flat
/// `matches[]` with `homeTeam`/`awayTeam`) plus generic `home`/`away`
/// objects. Unknown shapes degrade to `null` fields, never a crash.
class FootballApiAdapter extends BaseApiAdapter {
  FootballApiAdapter() : super(SportType.football, 'Football adapter');

  static const List<String> _feedPaths = [
    '/matches',
    '/fixtures',
    '/games',
    '/v1/matches',
    '/v2/matches',
    '/api/matches',
    '/',
  ];

  @override
  Future<List<MatchSummary>> fetchFeed(ApiConnection connection) async {
    final dio = buildAuthenticatedDio(connection);
    String? firstError;
    var sawHealthyResponse = false;

    for (final path in _feedPaths) {
      try {
        final response = await dio.get<dynamic>(path);
        if (response.statusCode == null ||
            response.statusCode! < 200 ||
            response.statusCode! >= 300) {
          continue;
        }
        sawHealthyResponse = true;
        final items = findMatchList(response.data);
        if (items.isEmpty) continue;

        return items
            .map(_parseMatch)
            .where((m) => m != null)
            .cast<MatchSummary>()
            .toList(growable: false);
      } on DioException catch (error) {
        firstError ??= readableNetworkError(
          error,
          host: connection.baseUrl,
          keyName: connection.label,
        ).message;
      }
    }

    if (sawHealthyResponse) return const [];
    throw UnexpectedResponseException(
      firstError ??
          'No recognized match data at ${connection.baseUrl}. '
          'Check that the base URL points at a football API.',
    );
  }

  MatchSummary? _parseMatch(Map<String, dynamic> item) {
    final fixture = JsonGuard.asMap(JsonGuard.pick(item, ['fixture', 'game']));

    final providerId = JsonGuard.asString(
      JsonGuard.pick(item, ['id', 'matchId', 'match_id']),
    ) ?? JsonGuard.asString(JsonGuard.pick(fixture ?? const {}, ['id']));
    if (providerId == null) return null;

    // ---- Status -------------------------------------------------------------
    final flatStatus = JsonGuard.asString(
      JsonGuard.pick(item, ['status', 'matchStatus', 'statusText', 'state']),
    );
    final nestedStatus = JsonGuard.asMap(JsonGuard.pick(item, ['status']));
    final statusShort = JsonGuard.asString(
      JsonGuard.pick(nestedStatus ?? const {}, ['short', 'code']),
    );
    final statusLong = JsonGuard.asString(
      JsonGuard.pick(nestedStatus ?? const {}, ['long', 'description']),
    ) ?? JsonGuard.asString(JsonGuard.pick(fixture ?? const {}, ['status']));
    final fixtureStatus = JsonGuard.asMap(
      JsonGuard.pick(fixture ?? const {}, ['status']),
    );
    final statusText = statusShort ??
        statusLong ??
        flatStatus ??
        JsonGuard.asString(
          JsonGuard.pick(fixtureStatus ?? const {}, ['short', 'long']),
        );
    final minute = JsonGuard.asInt(JsonGuard.pick(item, ['minute', 'elapsed']));
    final matchMinute = minute ??
        JsonGuard.asInt(
          JsonGuard.pick(fixtureStatus ?? const {}, ['elapsed', 'minute']),
        );

    // ---- Teams --------------------------------------------------------------
    Team? home;
    Team? away;
    final teamsMap = JsonGuard.asMap(JsonGuard.pick(item, ['teams']));
    if (teamsMap != null) {
      home = buildTeam(JsonGuard.asMap(teamsMap['home']) ?? {}, fallbackName: 'Home');
      away = buildTeam(JsonGuard.asMap(teamsMap['away']) ?? {}, fallbackName: 'Away');
    } else if (item['homeTeam'] != null || item['awayTeam'] != null) {
      home = buildTeam(JsonGuard.asMap(item['homeTeam']) ?? {}, fallbackName: 'Home');
      away = buildTeam(JsonGuard.asMap(item['awayTeam']) ?? {}, fallbackName: 'Away');
    } else if (item['home'] != null || item['away'] != null) {
      home = buildTeam(JsonGuard.asMap(item['home']) ?? {}, fallbackName: 'Home');
      away = buildTeam(JsonGuard.asMap(item['away']) ?? {}, fallbackName: 'Away');
    }
    home ??= Team(name: 'Home');
    away ??= Team(name: 'Away');

    // ---- Goals ----------------------------------------------------------------
    int? homeGoals;
    int? awayGoals;
    final goalsMap = JsonGuard.asMap(JsonGuard.pick(item, ['goals']));
    if (goalsMap != null) {
      homeGoals = JsonGuard.asInt(goalsMap['home']);
      awayGoals = JsonGuard.asInt(goalsMap['away']);
    }
    if (homeGoals == null) {
      final scoreMap = JsonGuard.asMap(JsonGuard.pick(item, ['score']));
      final fullTime = scoreMap == null
          ? null
          : JsonGuard.asMap(JsonGuard.pick(scoreMap, ['fulltime', 'fullTime']));
      homeGoals = JsonGuard.asInt(
        JsonGuard.pick(item, ['homeScore', 'goalsHome']),
      ) ?? JsonGuard.asInt(fullTime?['home']);
      awayGoals = JsonGuard.asInt(
        JsonGuard.pick(item, ['awayScore', 'goalsAway']),
      ) ?? JsonGuard.asInt(fullTime?['away']);
    }

    final result = JsonGuard.asString(
      JsonGuard.pick(item, ['result', 'winner', 'winningSummary']),
    );

    final league = JsonGuard.asMap(JsonGuard.pick(item, ['league']));
    final competition = JsonGuard.asMap(JsonGuard.pick(item, ['competition']));
    final venueMap = JsonGuard.asMap(JsonGuard.pick(fixture ?? const {}, ['venue']));

    return MatchSummary(
      providerId: providerId,
      connectionId: '',
      connectionLabel: '',
      sportType: sportType,
      status: _statusFor(statusText, matchMinute),
      home: home,
      away: away,
      name: JsonGuard.asString(JsonGuard.pick(item, ['name', 'title', 'matchName'])),
      seriesName: JsonGuard.asString(
        JsonGuard.pick(item, ['league', 'seriesName', 'tournament']),
      ) ?? JsonGuard.asString(
        JsonGuard.pick(league ?? competition ?? const {}, ['name', 'long_name']),
      ),
      venue: JsonGuard.asString(
        JsonGuard.pick(item, ['venue', 'stadium', 'ground']),
      ) ?? JsonGuard.asString(
        JsonGuard.pick(venueMap ?? const {}, ['name', 'city']),
      ),
      startTime: parseDate(
        JsonGuard.pick(item, [
          'utcDate',
          'date',
          'dateTime',
          'kickoff',
          'startTime',
        ]),
      ) ?? parseDate(JsonGuard.pick(fixture ?? const {}, ['date', 'dateTime'])),
      statusText: statusText ??
          (matchMinute != null ? "$matchMinute'" : null),
      result: result,
      homeScore: TeamScore(team: home, goals: homeGoals),
      awayScore: TeamScore(team: away, goals: awayGoals),
      videoUrl: readVideoUrl(item),
    );
  }

  MatchStatus _statusFor(String? text, int? minute) {
    final t = (text ?? '').trim().toLowerCase();
    if (t.isEmpty) {
      // A numeric minute with no status text usually means "in play".
      return minute != null && minute > 0 ? MatchStatus.live : MatchStatus.scheduled;
    }
    return statusFromText(t, sport: 'football');
  }

  @override
  Future<MatchDetail> fetchMatchDetail(
    ApiConnection connection,
    MatchSummary match,
  ) async {
    return bestEffortDetail(connection, match, (body) => _parseDetail(body, match));
  }

  MatchDetail _parseDetail(dynamic body, MatchSummary match) {
    final map = JsonGuard.asMap(body);
    if (map == null) return MatchDetail(summary: match);

    return MatchDetail(
      summary: match,
      matchStats: _findStats(map),
      commentary: _findEvents(map),
      lineups: _findLineups(map),
    );
  }

  List<MatchStatLine> _findStats(Map<String, dynamic> root) {
    final raw = JsonGuard.pick(root, ['statistics', 'matchStats', 'stats', 'statisticsResponse']);
    if (raw == null) return const [];

    final list = JsonGuard.asList(raw);
    final result = <MatchStatLine>[];
    for (final entry in list) {
      final map = JsonGuard.asMap(entry);
      if (map == null) continue;
      final label = JsonGuard.asString(
        JsonGuard.pick(map, ['type', 'label', 'name', 'stat', 'title']),
      );
      if (label == null) continue;
      // Some providers nest home/away under `value`, others as `home`/`away`.
      final home = JsonGuard.asString(JsonGuard.pick(map, ['home', 'homeValue']));
      final away = JsonGuard.asString(JsonGuard.pick(map, ['away', 'awayValue']));
      final value = JsonGuard.asString(JsonGuard.pick(map, ['value']));
      if (value != null) {
        // {type, value} shape — value is often "x - y".
        final parts = value.split('-');
        result.add(
          MatchStatLine(
            label: label,
            home: parts.isNotEmpty ? parts[0].trim() : null,
            away: parts.length >= 2 ? parts[1].trim() : null,
          ),
        );
      } else {
        result.add(MatchStatLine(label: label, home: home, away: away));
      }
    }
    return result;
  }

  List<CommentaryItem> _findEvents(Map<String, dynamic> root) {
    final raw = JsonGuard.pick(root, ['events', 'commentary', 'incidents']);
    if (raw == null) return const [];
    return mapCommentary(JsonGuard.asList(raw), cricket: false);
  }

  List<Player> _findLineups(Map<String, dynamic> root) {
    final raw = JsonGuard.pick(root, ['lineups']);
    if (raw == null) return const [];

    final result = <Player>[];
    for (final teamEntry in JsonGuard.asList(raw)) {
      final teamMap = JsonGuard.asMap(teamEntry);
      if (teamMap == null) continue;
      for (final playerEntry in JsonGuard.asList(
        JsonGuard.pick(teamMap, ['players', 'startXI']),
      )) {
        final playerMap = JsonGuard.asMap(playerEntry);
        if (playerMap == null) continue;
        final name = JsonGuard.asString(
          JsonGuard.pick(playerMap, ['name', 'player']),
        );
        if (name == null) continue;
        result.add(
          Player(
            name: name,
            role: JsonGuard.asString(
              JsonGuard.pick(playerMap, ['position', 'role']),
            ),
          ),
        );
      }
    }
    return result;
  }
}
