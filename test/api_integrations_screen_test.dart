import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sportsync/features/auth/data/firebase_auth_repository.dart';
import 'package:sportsync/features/auth/viewmodels/auth_view_model.dart';
import 'package:sportsync/features/profile/api_integrations/views/api_integrations_screen.dart';
import 'package:sportsync/features/profile/api_integrations/viewmodels/api_integrations_view_model.dart';
import 'package:sportsync/models/api_connection.dart';
import 'package:sportsync/models/auth_style.dart';
import 'package:sportsync/models/sport_type.dart';
import 'package:sportsync/repositories/providers.dart';

void main() {
  testWidgets('API screen groups channels by sport in horizontal rows',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();

    final cricketA = ApiConnection.draft(
      label: 'Cric Live',
      sportType: SportType.cricket,
      baseUrl: 'https://cric.example.com',
      apiKey: 'a',
      authStyle: AuthStyle.bearer,
    );
    final cricketB = ApiConnection.draft(
      label: 'Cric Series',
      sportType: SportType.cricket,
      baseUrl: 'https://cric2.example.com',
      apiKey: 'b',
      authStyle: AuthStyle.queryParam,
      headerName: 'key',
    );
    final football = ApiConnection.draft(
      label: 'Foot Live',
      sportType: SportType.football,
      baseUrl: 'https://foot.example.com',
      apiKey: 'c',
      authStyle: AuthStyle.bearer,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(() => _FakeAuthNotifier()),
          connectionsProvider.overrideWith(
            () => _FakeConnectionsNotifier([cricketA, cricketB, football]),
          ),
          apiIntegrationsViewModelProvider.overrideWith(
            () => _FakeApiIntegrationsNotifier([cricketA, cricketB, football]),
          ),
        ],
        child: const MaterialApp(home: ApiIntegrationsScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('Cricket channels'), findsOneWidget);
    expect(find.text('Football channels'), findsOneWidget);
    expect(find.text('Cric Live'), findsOneWidget);
    expect(find.text('Cric Series'), findsOneWidget);
    expect(find.text('Foot Live'), findsOneWidget);
  });
}

class _FakeAuthNotifier extends AuthViewModel {
  @override
  Future<LocalUser?> build() async =>
      const LocalUser(uid: 'u1', name: 'Tester', email: 't@example.com');
}

class _FakeConnectionsNotifier extends ConnectionsNotifier {
  _FakeConnectionsNotifier(this.items);

  final List<ApiConnection> items;

  @override
  Future<List<ApiConnection>> build() async => items;
}

class _FakeApiIntegrationsNotifier extends ApiIntegrationsViewModel {
  _FakeApiIntegrationsNotifier(this.items);

  final List<ApiConnection> items;

  @override
  ApiIntegrationsState build() => ApiIntegrationsState(
        connections: items,
        liveByConnection: const {},
      );
}
