import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_tutorial/utils/media_url.dart';

void main() {
  group('media_url', () {
    test('looksLikeVideoUrl rejects obvious non-video urls', () {
      expect(looksLikeVideoUrl(null), isFalse);
      expect(looksLikeVideoUrl(''), isFalse);
      expect(looksLikeVideoUrl('https://example.com/'), isFalse);
      expect(looksLikeVideoUrl('https://example.com/index.html'), isFalse);
      expect(looksLikeVideoUrl('https://example.com/main.dart.js'), isFalse);
      expect(looksLikeVideoUrl('ftp://example.com/video.mp4'), isFalse);
    });

    test('looksLikeVideoUrl accepts typical video urls', () {
      expect(looksLikeVideoUrl('https://cdn.example.com/video.mp4'), isTrue);
      expect(looksLikeVideoUrl('https://cdn.example.com/a/b/c.m3u8'), isTrue);
      expect(looksLikeVideoUrl('https://example.com/stream/videoplayback?id=123'), isTrue);
    });

    test('effectiveVideoUrlForPlayback falls back for blocked hosts (when enabled)', () {
      const blocked = 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_2mb.mp4';
      final effective = effectiveVideoUrlForPlayback(blocked, fallback: 'https://example.com/fallback.mp4');
      if (kEnableVideoFallback) {
        expect(effective, 'https://example.com/fallback.mp4');
      } else {
        expect(effective, blocked);
      }
    });
  });
}

