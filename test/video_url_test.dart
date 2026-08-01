import 'package:flutter_test/flutter_test.dart';

import 'package:sportsync/core/utils/video_url.dart';
import 'package:sportsync/services/adapters/cricket_api_adapter.dart';

void main() {
  group('MatchVideoUrl.isPlayable', () {
    test('rejects null / empty / non-http', () {
      expect(MatchVideoUrl.isPlayable(null), isFalse);
      expect(MatchVideoUrl.isPlayable(''), isFalse);
      expect(MatchVideoUrl.isPlayable('   '), isFalse);
      expect(MatchVideoUrl.isPlayable('not a url.m3u8'), isFalse);
      expect(MatchVideoUrl.isPlayable('ftp://cdn.example.com/a.m3u8'), isFalse);
      expect(MatchVideoUrl.isPlayable('https://example.com/page'), isFalse);
      expect(MatchVideoUrl.isPlayable('https://example.com/image.jpg'), isFalse);
    });

    test('accepts HLS, MP4 and DASH streams over http(s)', () {
      expect(
        MatchVideoUrl.isPlayable('https://cdn.example.com/live.m3u8'),
        isTrue,
      );
      expect(
        MatchVideoUrl.isPlayable('http://cdn.example.com/video.mp4'),
        isTrue,
      );
      expect(
        MatchVideoUrl.isPlayable('https://cdn.example.com/manifest.mpd'),
        isTrue,
      );
      expect(
        MatchVideoUrl.isPlayable(
          'https://cdn.example.com/live.m3u8?token=abc123',
        ),
        isTrue,
      );
      expect(
        MatchVideoUrl.isPlayable('https://cdn.example.com/LIVE.M3U8'),
        isTrue,
      );
    });
  });

  group('adapter video detection', () {
    final adapter = CricketApiAdapter();

    test('reads a top-level videoUrl', () {
      final url = adapter.readVideoUrl({'videoUrl': 'https://x/live.m3u8'});
      expect(url, 'https://x/live.m3u8');
    });

    test('reads a nested stream object', () {
      final url = adapter.readVideoUrl({
        'stream': {'url': 'https://x/playlist.mpd'},
      });
      expect(url, 'https://x/playlist.mpd');
    });

    test('returns null when no playable stream exists', () {
      expect(adapter.readVideoUrl({'name': 'IND vs AUS'}), isNull);
      expect(
        adapter.readVideoUrl({'videoUrl': 'https://x/page'}), // not a stream
        isNull,
      );
      expect(
        adapter.readVideoUrl({
          'coverUrl': 'https://x/photo.jpg',
          'home': {'name': 'IND'},
        }),
        isNull,
      );
    });
  });
}
