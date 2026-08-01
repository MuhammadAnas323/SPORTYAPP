/// Detects whether a provider string is a playable live video stream URL.
///
/// The supported formats mirror what the in-app player can actually play:
/// HLS (`.m3u8`), MP4 (`.mp4`) and DASH (`.mpd`). Anything else — missing,
/// an image, a page URL, a malformed string — is rejected so the UI falls
/// back to the regular data card.
abstract final class MatchVideoUrl {
  MatchVideoUrl._();

  static final RegExp _playableExtension = RegExp(
    r'\.(m3u8|mp4|mpd)([?#]|$)',
    caseSensitive: false,
  );

  /// True when [url] is a non-empty http(s) URL pointing at a supported
  /// video file (`.m3u8`, `.mp4` or `.mpd`).
  static bool isPlayable(String? url) {
    if (url == null) return false;
    final value = url.trim();
    if (value.isEmpty) return false;
    if (!value.toLowerCase().startsWith('http')) return false;
    return _playableExtension.hasMatch(value.toLowerCase());
  }
}
