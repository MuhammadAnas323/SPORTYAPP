import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sportsync/features/home/views/home_screen.dart';
import 'package:sportsync/models/api_connection.dart';
import 'package:sportsync/models/auth_style.dart';
import 'package:sportsync/models/channel.dart';
import 'package:sportsync/models/match_status.dart';
import 'package:sportsync/models/match_summary.dart';
import 'package:sportsync/models/sport_type.dart';
import 'package:sportsync/models/team.dart';
import 'package:sportsync/services/feed_store.dart';

void main() {
  testWidgets('Home shows matches from the shared feed with filter bar',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();

    final cricket = ApiConnection.draft(
      label: 'My Cric API',
      sportType: SportType.cricket,
      baseUrl: 'https://cric.example.com',
      apiKey: 'a',
      authStyle: AuthStyle.bearer,
    );
    final match = MatchSummary(
      providerId: 'm1',
      connectionId: cricket.id,
      connectionLabel: cricket.label,
      sportType: SportType.cricket,
      status: MatchStatus.scheduled,
      home: const Team(name: 'India', shortName: 'IND'),
      away: const Team(name: 'Australia', shortName: 'AUS'),
      seriesName: 'Test Series',
    );
    final feed = AggregatedFeed(
      channels: [
        ChannelFeed(connection: cricket, items: [match]),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedStoreProvider.overrideWith(() => _FakeFeedStore(feed)),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Cricket'), findsOneWidget);
    expect(find.text('Football'), findsOneWidget);
    expect(find.text('India'), findsOneWidget);
    expect(find.text('Australia'), findsOneWidget);
  });

  testWidgets('Home shows the sport filter bar even when the feed is empty',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedStoreProvider.overrideWith(
            () => _FakeFeedStore(const AggregatedFeed()),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Cricket'), findsOneWidget);
    expect(find.text('Football'), findsOneWidget);
    expect(find.text('No matches yet'), findsOneWidget);
  });
}

class _FakeFeedStore extends FeedStore {
  _FakeFeedStore(this.feed);

  final AggregatedFeed feed;

  @override
  Future<FeedState> build() async => FeedState(feed: feed);
}
