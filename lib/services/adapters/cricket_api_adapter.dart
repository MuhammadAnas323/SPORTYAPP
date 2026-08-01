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

/// Cricket adapter — maps the raw JSON of whichever cricket API the user
/// connected into normalized [MatchSummary] / [MatchDetail] models.
///
/// It understands the two most common cricket API conventions (CricAPI-style
/// `team-1`/`team-2` maps and cricketdata.org-style `teamInfo` + `score`
/// arrays) and degrades gracefully to `null` fields for anything else.
class CricketApiAdapter extends BaseApiAdapter {
  CricketApiAdapter() : super(SportType.cricket, 'Cricket adapter');

  static const List<String> _feedPaths = [
    '/matches',
    '/cricket',
    '/current',
    '/live',
    '/upcoming',
    '/v1/matches',
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

    if (sawHealthyResponse) {
      // Host is reachable and answered 2xx but returned no recognizable
      // matches — a legitimate (empty) feed.
      return const [];
    }
    throw UnexpectedResponseException(
      firstError ??
          'No recognized match data at ${connection.baseUrl}. '
          'Check that the base URL points at a cricket API.',
    );
  }

  MatchSummary? _parseMatch(Map<String, dynamic> item) {
    final providerId = JsonGuard.asString(
      JsonGuard.pick(item, ['id', 'matchId', 'match_id', 'unique_id', 'slug']),
    );
    if (providerId == null) return null;

    final statusText = JsonGuard.asString(
      JsonGuard.pick(item, [
        'status',
        'statusText',
        'matchStatus',
        'state',
        'matchState',
        'detail',
      ]),
    );

    // ---- Teams -------------------------------------------------------------
    Team? home;
    Team? away;

    final teamInfo = JsonGuard.asList(JsonGuard.pick(item, ['teamInfo', 'teams']));
    if (teamInfo.isNotEmpty && teamInfo.every((e) => JsonGuard.asMap(e) != null)) {
      final maps = teamInfo.map(JsonGuard.asMap).whereType<Map<String, dynamic>>().toList();
      if (maps.isNotEmpty) home = buildTeam(maps[0]);
      if (maps.length >= 2) away = buildTeam(maps[1]);
    } else if (item['team-1'] != null && item['team-2'] != null) {
      final t1 = JsonGuard.asMap(item['team-1']);
      final t2 = JsonGuard.asMap(item['team-2']);
      home = t1 != null ? buildTeam(t1) : null;
      away = t2 != null ? buildTeam(t2) : null;
    } else if (item['homeTeam'] != null && item['awayTeam'] != null) {
      home = buildTeam(JsonGuard.asMap(item['homeTeam']) ?? {});
      away = buildTeam(JsonGuard.asMap(item['awayTeam']) ?? {});
    }

    final teamsList = JsonGuard.asList(JsonGuard.pick(item, ['teams', 'teamNames']));
    if (teamsList.isNotEmpty && (home == null || away == null)) {
      if (home == null && teamsList.isNotEmpty) {
        final raw = teamsList[0];
        home = raw is String ? Team(name: raw) : buildTeam(JsonGuard.asMap(raw) ?? {});
      }
      if (away == null && teamsList.length >= 2) {
        final raw = teamsList[1];
        away = raw is String ? Team(name: raw) : buildTeam(JsonGuard.asMap(raw) ?? {});
      }
    }

    home ??= Team(name: 'Home');
    away ??= Team(name: 'Away');

    // ---- Scores --------------------------------------------------------------
    TeamScore? homeScore;
    TeamScore? awayScore;

    final scoreList = JsonGuard.asList(JsonGuard.pick(item, ['score', 'scoreboard']));
    final inningsList = scoreList.map(JsonGuard.asMap).whereType<Map<String, dynamic>>().toList();
    if (inningsList.isNotEmpty) {
      for (final inn in inningsList) {
        final battingTeam = JsonGuard.asString(
          JsonGuard.pick(inn, ['battingTeam', 'teamName', 'team', 'team_name']),
        );
        final score = TeamScore(
          team: Team(name: battingTeam ?? ''),
          runs: JsonGuard.asInt(JsonGuard.pick(inn, ['r', 'runs', 'score'])),
          wickets: JsonGuard.asInt(JsonGuard.pick(inn, ['w', 'wickets', 'out'])),
          overs: JsonGuard.asDouble(JsonGuard.pick(inn, ['o', 'overs', 'over'])),
        );
        final teamName = battingTeam ?? '';
        final matchesHome = homeScore == null &&
            (teamName == home.name ||
                teamName == home.shortName ||
                teamName == home.code);
        final matchesAway = awayScore == null &&
            (teamName == away.name ||
                teamName == away.shortName ||
                teamName == away.code);
        if (matchesHome) {
          homeScore = score;
        } else if (matchesAway) {
          awayScore = score;
        } else if (homeScore == null && awayScore == null) {
          // Unmatched innings: attribute by position — first to home, then away.
          homeScore = score;
        } else {
          awayScore ??= score;
        }
      }
    } else if (item['team-1'] != null && item['team-2'] != null) {
      final t1 = JsonGuard.asMap(item['team-1']);
      final t2 = JsonGuard.asMap(item['team-2']);
      if (t1 != null) {
        homeScore = buildCricketScore(
          team: home,
          scoreText: JsonGuard.asString(JsonGuard.pick(t1, ['score', 'scoreline'])),
          runs: JsonGuard.asInt(JsonGuard.pick(t1, ['runs', 'score'])),
          wickets: JsonGuard.asInt(JsonGuard.pick(t1, ['wickets', 'out'])),
          overs: JsonGuard.asDouble(JsonGuard.pick(t1, ['overs', 'over'])),
          rawScore: JsonGuard.asString(t1['score']),
        );
      }
      if (t2 != null) {
        awayScore = buildCricketScore(
          team: away,
          scoreText: JsonGuard.asString(JsonGuard.pick(t2, ['score', 'scoreline'])),
          runs: JsonGuard.asInt(JsonGuard.pick(t2, ['runs', 'score'])),
          wickets: JsonGuard.asInt(JsonGuard.pick(t2, ['wickets', 'out'])),
          overs: JsonGuard.asDouble(JsonGuard.pick(t2, ['overs', 'over'])),
          rawScore: JsonGuard.asString(t2['score']),
        );
      }
    } else {
      // Some providers put the whole score as a string on the match object.
      final whole = JsonGuard.asString(JsonGuard.pick(item, ['score', 'scoreline']));
      if (whole != null && whole.isNotEmpty) {
        final parts = whole.split(RegExp(r'\s+(?=[A-Za-z]{2,})'));
        if (parts.length >= 2) {
          homeScore = buildCricketScore(team: home, rawScore: parts[0]);
          awayScore = buildCricketScore(team: away, rawScore: parts[1]);
        }
      }
    }

    final name = JsonGuard.asString(JsonGuard.pick(item, ['name', 'title', 'matchName']));
    final result = JsonGuard.asString(
          JsonGuard.pick(item, ['result', 'winningSummary']),
        ) ??
        (statusText != null && statusText.toLowerCase().contains('won')
            ? statusText
            : null);

    return MatchSummary(
      providerId: providerId,
      connectionId: '',
      connectionLabel: '',
      sportType: sportType,
      status: _statusFor(item, statusText),
      home: home,
      away: away,
      name: name,
      seriesName: JsonGuard.asString(
        JsonGuard.pick(item, ['seriesName', 'series', 'tournament', 'league']),
      ),
      venue: JsonGuard.asString(
        JsonGuard.pick(item, ['venue', 'ground', 'matchVenue', 'city']),
      ),
      startTime: parseDate(
        JsonGuard.pick(item, [
          'dateTimeGMT',
          'startTime',
          'date',
          'startDate',
          'matchDate',
          'matchTime',
          'dateTime',
        ]),
      ),
      statusText: statusText,
      result: result,
      homeScore: homeScore,
      awayScore: awayScore,
      coverUrl: JsonGuard.asString(
        JsonGuard.pick(item, ['coverUrl', 'image', 'thumbnail']),
      ),
      videoUrl: readVideoUrl(item),
    );
  }

  MatchStatus _statusFor(Map<String, dynamic> item, String? text) {
    final parsed = statusFromText(text, sport: 'cricket');
    if (parsed != MatchStatus.scheduled) return parsed;
    final started = JsonGuard.asBool(
      JsonGuard.pick(item, ['matchStarted', 'started', 'isStarted']),
      fallback: false,
    );
    final ended = JsonGuard.asBool(
      JsonGuard.pick(item, ['matchEnded', 'ended', 'isEnded', 'finished']),
      fallback: false,
    );
    if (ended) return MatchStatus.completed;
    if (started) return MatchStatus.live;
    return parsed;
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

    final innings = _findInnings(map, match);
    final commentary = _findCommentary(map);

    return MatchDetail(
      summary: match,
      innings: innings,
      commentary: commentary,
    );
  }

  List<InningsCard> _findInnings(Map<String, dynamic> root, MatchSummary match) {
    final raw = JsonGuard.pick(root, ['innings', 'scorecard', 'scoreCards']);
    if (raw == null) return const [];

    List<dynamic> list;
    final asList = JsonGuard.asList(raw);
    if (asList.isNotEmpty) {
      list = asList;
    } else {
      list = JsonGuard.asList(JsonGuard.pick(root, ['data', 'innings']));
      if (list.isEmpty) return const [];
    }

    final result = <InningsCard>[];
    var index = 0;
    for (final entry in list) {
      final inn = JsonGuard.asMap(entry);
      if (inn == null) continue;

      final teamName = JsonGuard.asString(
        JsonGuard.pick(inn, ['teamName', 'team', 'battingTeam', 'name']),
      );
      final isHome =
          teamName != null && (teamName == match.home.name || teamName == match.home.shortName);
      final team = isHome
          ? match.home
          : (teamName == match.away.name || teamName == match.away.shortName
              ? match.away
              : Team(name: teamName ?? (index.isEven ? match.home.name : match.away.name)));

      final battingRaw = JsonGuard.asList(
        JsonGuard.pick(inn, ['batting', 'batters', 'battingCard', 'batsmen']),
      );
      final bowlingRaw = JsonGuard.asList(
        JsonGuard.pick(inn, ['bowling', 'bowlers', 'bowlingCard']),
      );

      result.add(
        InningsCard(
          team: team,
          total: JsonGuard.asInt(JsonGuard.pick(inn, ['total', 'runs', 'r'])),
          wickets: JsonGuard.asInt(JsonGuard.pick(inn, ['wickets', 'w', 'out'])),
          overs: JsonGuard.asDouble(JsonGuard.pick(inn, ['overs', 'o'])),
          extras: JsonGuard.asString(JsonGuard.pick(inn, ['extras', 'extra'])),
          batting: battingRaw
              .map(JsonGuard.asMap)
              .whereType<Map<String, dynamic>>()
              .map(_parseBattingRecord)
              .toList(growable: false),
          bowling: bowlingRaw
              .map(JsonGuard.asMap)
              .whereType<Map<String, dynamic>>()
              .map(_parseBowlingRecord)
              .toList(growable: false),
          notes: JsonGuard.asString(
            JsonGuard.pick(inn, ['notes', 'yetToBat', 'commentary']),
          ),
        ),
      );
      index++;
    }
    return result;
  }

  BattingRecord _parseBattingRecord(Map<String, dynamic> map) {
    final runs = JsonGuard.asInt(JsonGuard.pick(map, ['r', 'runs', 'score']));
    final balls = JsonGuard.asInt(JsonGuard.pick(map, ['b', 'balls']));
    final outRaw = JsonGuard.asBool(
      JsonGuard.pick(map, ['isOut', 'out', 'dismissed']),
      fallback: runs != null,
    );
    return BattingRecord(
      runs: runs,
      balls: balls,
      fours: JsonGuard.asInt(JsonGuard.pick(map, ['4s', 'fours'])),
      sixes: JsonGuard.asInt(JsonGuard.pick(map, ['6s', 'sixes'])),
      strikeRate: JsonGuard.asDouble(
        JsonGuard.pick(map, ['sr', 'strikeRate', 'strike_rate']),
      ),
      out: outRaw,
      dismissal: JsonGuard.asString(
        JsonGuard.pick(map, ['dismissal', 'howOut', 'outType']),
      ),
    );
  }

  BowlingRecord _parseBowlingRecord(Map<String, dynamic> map) {
    return BowlingRecord(
      overs: JsonGuard.asDouble(JsonGuard.pick(map, ['o', 'overs'])),
      maidens: JsonGuard.asInt(JsonGuard.pick(map, ['m', 'maidens'])),
      runsConceded: JsonGuard.asInt(JsonGuard.pick(map, ['r', 'runs'])),
      wickets: JsonGuard.asInt(JsonGuard.pick(map, ['w', 'wickets'])),
      economy: JsonGuard.asDouble(
        JsonGuard.pick(map, ['econ', 'economy', 'economyRate']),
      ),
    );
  }

  List<CommentaryItem> _findCommentary(Map<String, dynamic> root) {
    final raw = JsonGuard.pick(root, ['commentary', 'commentaries', 'liveCommentary']);
    if (raw == null) return const [];
    return mapCommentary(JsonGuard.asList(raw), cricket: true);
  }
}
