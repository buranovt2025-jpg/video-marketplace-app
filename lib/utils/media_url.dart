/// Helpers for validating media URLs (especially on Flutter Web).
///
/// In production we've seen cases when `video_url` points to the app itself
/// (returns `index.html`), not to an actual media file. That can never play in
/// `video_player` and should be surfaced as a user-friendly error.
library;

const String kFallbackDemoMp4Url =
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

/// Feature flag: allows turning off the fallback without code changes.
/// Build with: `--dart-define=ENABLE_VIDEO_FALLBACK=false`
const bool kEnableVideoFallback =
    bool.fromEnvironment('ENABLE_VIDEO_FALLBACK', defaultValue: true);

bool looksLikeAbsoluteHttpUrl(String? url) {
  final u = url?.trim();
  if (u == null || u.isEmpty) return false;
  final uri = Uri.tryParse(u);
  if (uri == null) return false;
  if (!uri.hasScheme) return false;
  return uri.scheme == 'http' || uri.scheme == 'https';
}

bool isBlockedVideoHost(String? url) {
  final u = url?.trim();
  if (u == null || u.isEmpty) return false;
  final uri = Uri.tryParse(u);
  final host = uri?.host.toLowerCase();
  if (host == null || host.isEmpty) return false;

  // These demo hosts often fail in browsers (hotlink protection / missing
  // headers / inconsistent availability) and cause MEDIA_ERR_SRC_NOT_SUPPORTED.
  const blocked = <String>{
    'sample-videos.com',
    'www.sample-videos.com',
  };
  return blocked.contains(host);
}

String effectiveVideoUrlForPlayback(String url, {String fallback = kFallbackDemoMp4Url}) {
  // If the host is known to break playback, use a known-good demo mp4 so the
  // viewer UX can be verified. Backend should eventually store real video URLs.
  if (kEnableVideoFallback && isBlockedVideoHost(url)) return fallback;
  return url.trim();
}

bool looksLikeVideoUrl(String? url) {
  final u = url?.trim();
  if (u == null || u.isEmpty) return false;

  if (!looksLikeAbsoluteHttpUrl(u)) return false;
  final uri = Uri.tryParse(u);
  final path = (uri?.path ?? '').toLowerCase();

  // Obvious "this is the web app itself" patterns.
  if (path.isEmpty || path == '/' || path.endsWith('/index.html')) return false;
  if (path.endsWith('/main.dart.js')) return false;

  // Most common direct video file / stream extensions.
  const videoExts = <String>{
    '.mp4',
    '.webm',
    '.mov',
    '.m4v',
    '.mkv',
    '.m3u8',
  };
  for (final ext in videoExts) {
    if (path.endsWith(ext)) return true;
  }

  // Some CDNs use extension-less URLs. Allow if path contains typical hints.
  final hints = <String>['/video', 'videoplayback', 'stream'];
  for (final h in hints) {
    if (path.contains(h)) return true;
  }

  return false;
}

