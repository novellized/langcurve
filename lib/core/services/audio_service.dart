import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player;

  AudioService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  /// Plays audio for [word] using a resilient multi-source audio candidate chain.
  /// Automatically bypasses broken 502 CDN links and falls back to Google Static Sounds or Youdao TTS.
  Future<void> playWordAudio(
    String? url,
    String word, {
    bool isUk = true,
    double playbackRate = 1.0,
  }) async {
    final cleanWord = word.trim().toLowerCase();
    if (cleanWord.isEmpty) return;

    final candidates = <String>[];

    // Normalize raw URL if provided
    String? primaryUrl = url?.trim();
    if (primaryUrl != null && primaryUrl.startsWith('//')) {
      primaryUrl = 'https:$primaryUrl';
    }

    // 1. Google Static Sounds CDN (extremely fast & reliable 200 OK)
    final gstaticAccent = isUk ? 'gb' : 'us';
    final gstaticUrl =
        'https://ssl.gstatic.com/dictionary/static/sounds/20200429/$cleanWord--_${gstaticAccent}_1.mp3';
    candidates.add(gstaticUrl);

    // 2. Add primary URL if provided and not equal to gstatic
    if (primaryUrl != null &&
        primaryUrl.isNotEmpty &&
        !primaryUrl.contains('api.dictionaryapi.dev/media/pronunciations/')) {
      if (!candidates.contains(primaryUrl)) {
        candidates.insert(0, primaryUrl);
      }
    }

    // 3. Youdao TTS Fallback
    final youdaoType = isUk ? '1' : '2';
    final youdaoUrl =
        'https://dict.youdao.com/dictvoice?audio=${Uri.encodeComponent(cleanWord)}&type=$youdaoType';
    candidates.add(youdaoUrl);

    // 4. Google TTS Fallback
    final googleLang = isUk ? 'en-GB' : 'en-US';
    final googleTtsUrl =
        'https://translate.google.com/translate_tts?ie=UTF-8&tl=$googleLang&client=tw-ob&q=${Uri.encodeComponent(cleanWord)}';
    candidates.add(googleTtsUrl);

    // 5. Raw URL as last resort if not added
    if (primaryUrl != null && primaryUrl.isNotEmpty && !candidates.contains(primaryUrl)) {
      candidates.add(primaryUrl);
    }

    Object? lastException;
    for (final candidateUrl in candidates) {
      try {
        await _player.stop();
        await _player.setPlaybackRate(playbackRate);
        await _player.play(UrlSource(candidateUrl));
        return; // Success!
      } catch (e) {
        lastException = e;
        // Continue trying next candidate in chain
      }
    }

    if (lastException != null) {
      throw lastException;
    }
  }

  /// Returns reliable TTS audio URL for English words
  static String getFallbackTtsUrl(String word, {required bool isUk}) {
    final clean = word.trim().toLowerCase();
    final accent = isUk ? 'gb' : 'us';
    return 'https://ssl.gstatic.com/dictionary/static/sounds/20200429/$clean--_${accent}_1.mp3';
  }

  void dispose() {
    _player.dispose();
  }
}
