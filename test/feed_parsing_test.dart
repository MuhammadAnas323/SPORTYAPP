import 'package:flutter_test/flutter_test.dart';

import 'package:sportsync/services/adapters/base_api_adapter.dart';
import 'package:sportsync/services/adapters/cricket_api_adapter.dart';

void main() {
  final adapter = CricketApiAdapter();

  group('findMatchList', () {
    test('finds CricAPI-style data array', () {
      final items = adapter.findMatchList({
        'status': 'success',
        'data': [
          {'id': 'abc', 'name': 'Match 1'},
          {'id': 'def', 'name': 'Match 2'},
        ],
      });
      expect(items, hasLength(2));
    });

    test('matches wrapper keys case-insensitively', () {
      final items = adapter.findMatchList({
        'Data': [
          {'id': 'x'},
        ],
      });
      expect(items, hasLength(1));
    });

    test('finds nested data.matches', () {
      final items = adapter.findMatchList({
        'data': {
          'matches': [
            {'id': 'x'},
          ],
        },
      });
      expect(items, hasLength(1));
    });

    test('returns empty for a bare error envelope', () {
      expect(adapter.findMatchList({'status': 'failure'}), isEmpty);
    });
  });

  group('apiErrorInBody', () {
    test('detects CricAPI failure envelope with reason', () {
      final message = BaseApiAdapter.apiErrorInBody({
        'status': 'failure',
        'reason': 'Invalid key or access restricted!',
      });
      expect(message, contains('Invalid key'));
    });

    test('detects success:false envelope', () {
      final message = BaseApiAdapter.apiErrorInBody({
        'success': false,
        'message': 'Quota exceeded',
      });
      expect(message, contains('Quota exceeded'));
    });

    test('returns null for a success envelope', () {
      expect(
        BaseApiAdapter.apiErrorInBody({
          'status': 'success',
          'data': [],
        }),
        isNull,
      );
    });

    test('returns null for a non-map body', () {
      expect(BaseApiAdapter.apiErrorInBody('plain text'), isNull);
    });
  });
}
