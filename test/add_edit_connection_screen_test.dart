import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sportsync/features/profile/api_integrations/views/add_edit_connection_screen.dart';
import 'package:sportsync/features/profile/api_integrations/viewmodels/connection_form_view_model.dart';
import 'package:sportsync/models/api_connection.dart';
import 'package:sportsync/models/auth_style.dart';
import 'package:sportsync/models/sport_type.dart';
import 'package:sportsync/repositories/providers.dart';

void main() {
  Widget harness({List<ApiConnection> connections = const []}) {
    return ProviderScope(
      overrides: [
        connectionsProvider.overrideWith(
          () => _FakeConnectionsNotifier(connections),
        ),
      ],
      child: MaterialApp(
        home: AddEditConnectionScreen(initialSportType: SportType.football),
      ),
    );
  }

  // Regression: the form used to reset ConnectionFormViewModel.state
  // synchronously in initState, which threw "Tried to modify a provider while
  // the widget tree was building" when entering from the Cricket/Football
  // picker in the Profile screen.
  testWidgets('Add form pre-selects the tapped sport without provider errors',
      (tester) async {
    await tester.pumpWidget(harness());

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('Football API'), findsWidgets);
  });

  testWidgets('Save and Connected APIs buttons sit at the top of the form',
      (tester) async {
    await tester.pumpWidget(harness());

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('Save channel'), findsOneWidget);
    expect(find.text('Connected APIs'), findsOneWidget);

    final saveY = tester.getTopLeft(find.text('Save channel')).dy;
    final labelY = tester.getTopLeft(find.text('API name')).dy;
    expect(saveY, lessThan(labelY));
  });

  testWidgets('API name field accepts and keeps typed text', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final field = find.byType(TextFormField).first;
    await tester.enterText(field, 'My cricket API');
    await tester.pump();

    // The typed text survives the rebuild triggered by the state update
    // (regression: a controller recreated on every build dropped keystrokes).
    expect(tester.takeException(), isNull);
    expect(find.text('My cricket API'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AddEditConnectionScreen)),
    );
    expect(container.read(connectionFormViewModelProvider).label,
        'My cricket API');
  });

  testWidgets('Connected APIs sheet lists every connection with edit/delete',
      (tester) async {
    final cricket = ApiConnection.draft(
      label: 'My Cric API',
      sportType: SportType.cricket,
      baseUrl: 'https://cric.example.com',
      apiKey: 'a',
      authStyle: AuthStyle.bearer,
    );
    final football = ApiConnection.draft(
      label: 'My Foot API',
      sportType: SportType.football,
      baseUrl: 'https://foot.example.com',
      apiKey: 'b',
      authStyle: AuthStyle.bearer,
    );

    await tester.pumpWidget(harness(connections: [cricket, football]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Connected APIs'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('My Cric API'), findsOneWidget);
    expect(find.text('My Foot API'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
    expect(find.byIcon(Icons.delete_outline_rounded), findsNWidgets(2));
  });
}

class _FakeConnectionsNotifier extends ConnectionsNotifier {
  _FakeConnectionsNotifier(this.items);

  final List<ApiConnection> items;

  @override
  Future<List<ApiConnection>> build() async => items;
}
