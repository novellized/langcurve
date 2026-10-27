import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart';
import '../models/bbc_video_item.dart';

class BbcVideoSyncService {
  final http.Client _client;
  SharedPreferences? _prefs;

  static const String rssUrl =
      'https://www.youtube.com/feeds/videos.xml?playlist_id=UULFHaHD477h-FeBbVh9Sh7syA';

  static const String _prefCacheKey = 'bbc_videos_cache_json';
  static const String _prefSyncTimeKey = 'bbc_videos_last_sync_time';
  static const Duration syncInterval = Duration(hours: 1);

  static final List<BbcVideoItem> fallbackVideos = [
    BbcVideoItem(
      id: 'ut3b9qDHvEQ',
      title: 'Children in war zones ⏲️ 6 Minute English - BBC Learning English',
      desc: 'Khoa học từ vựng và chủ đề thời sự qua góc nhìn báo chí từ chương trình 6 Minute English của BBC.',
    ),
    BbcVideoItem(
      id: 'qRsLwL9lJQg',
      title: 'Social Media & News - BBC Learning English from the News',
      desc: 'Bản tin tiếng Anh phân tích xu hướng truyền thông với từ vựng chuẩn khung tham chiếu Châu Âu CEFR.',
    ),
    BbcVideoItem(
      id: 'wDFV1sZo1gY',
      title: 'Beating Speaking Anxiety - BBC Learning English Class',
      desc: 'Phương pháp vượt qua tâm lý e ngại khi giao tiếp tiếng Anh trực tiếp với giáo viên bản ngữ BBC.',
    ),
  ];

  BbcVideoSyncService({http.Client? client, SharedPreferences? prefs})
      : _client = client ?? http.Client(),
        _prefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Fetches BBC Learning English videos with a 1-hour cache policy.
  /// Automatically re-syncs every 1 hour (or when [forceRefresh] is true).
  Future<List<BbcVideoItem>> fetchVideos({bool forceRefresh = false}) async {
    final prefs = await _getPrefs();

    final lastSyncEpoch = prefs.getInt(_prefSyncTimeKey) ?? 0;
    final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncEpoch);
    final now = DateTime.now();

    final isCacheValid = !forceRefresh &&
        lastSyncEpoch > 0 &&
        now.difference(lastSyncTime) < syncInterval;

    if (isCacheValid) {
      final cachedJson = prefs.getString(_prefCacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final List decoded = jsonDecode(cachedJson);
          final cachedList =
              decoded.map((e) => BbcVideoItem.fromMap(e as Map<String, dynamic>)).toList();
          if (cachedList.isNotEmpty) {
            return cachedList;
          }
        } catch (_) {}
      }
    }

    // Fetch fresh RSS feed from YouTube
    try {
      final response = await _client.get(Uri.parse(rssUrl)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final entries = document.findAllElements('entry');

        final List<BbcVideoItem> fetchedList = [];
        for (final entry in entries.take(6)) {
          final videoIdElem = entry.findElements('yt:videoId');
          final titleElem = entry.findElements('title');
          final mediaGroup = entry.findElements('media:group');

          if (videoIdElem.isNotEmpty && titleElem.isNotEmpty) {
            final id = videoIdElem.first.innerText.trim();
            final rawTitle = titleElem.first.innerText.trim();
            final title = _unescapeXml(rawTitle);

            String desc = '';
            if (mediaGroup.isNotEmpty) {
              final descElem = mediaGroup.first.findElements('media:description');
              if (descElem.isNotEmpty) {
                desc = descElem.first.innerText.trim();
              }
            }

            final cleanDesc = desc
                .split('\n')
                .first
                .replaceAll(RegExp(r'http\S+'), '')
                .trim();

            fetchedList.add(BbcVideoItem(
              id: id,
              title: title,
              desc: cleanDesc.isNotEmpty
                  ? (cleanDesc.length > 130 ? '${cleanDesc.substring(0, 130)}...' : cleanDesc)
                  : 'Video bài học tiếng Anh từ kênh BBC Learning English.',
              publishedAt: entry.findElements('published').isNotEmpty
                  ? entry.findElements('published').first.innerText
                  : null,
            ));
          }
        }

        if (fetchedList.isNotEmpty) {
          // Update cache & sync timestamp
          final encoded = jsonEncode(fetchedList.map((e) => e.toMap()).toList());
          await prefs.setString(_prefCacheKey, encoded);
          await prefs.setInt(_prefSyncTimeKey, now.millisecondsSinceEpoch);
          return fetchedList;
        }
      }
    } catch (_) {
      // Fall through
    }

    // Fallback if network failed: try returning old cache if present
    final cachedJson = prefs.getString(_prefCacheKey);
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        final List decoded = jsonDecode(cachedJson);
        final cachedList =
            decoded.map((e) => BbcVideoItem.fromMap(e as Map<String, dynamic>)).toList();
        if (cachedList.isNotEmpty) {
          return cachedList;
        }
      } catch (_) {}
    }

    return fallbackVideos;
  }

  /// Opens video in YouTube App if available, or falls back to Web Browser (e.g. Waydroid browser)
  static Future<bool> openVideo(String videoId) async {
    final cleanId = videoId.trim();
    if (cleanId.isEmpty) return false;

    final appUri = Uri.parse('vnd.youtube:$cleanId');
    final webUri = Uri.parse('https://www.youtube.com/watch?v=$cleanId');

    // 1. Try YouTube app scheme first
    try {
      if (await canLaunchUrl(appUri)) {
        final launchedApp = await launchUrl(
          appUri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
        if (launchedApp) return true;
      }
    } catch (_) {}

    // 2. Fallback to default external browser (e.g. Waydroid / Chrome browser)
    try {
      final launchedWeb = await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
      if (launchedWeb) return true;
    } catch (_) {
      return await launchUrl(webUri, mode: LaunchMode.platformDefault);
    }

    return false;
  }

  String _unescapeXml(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'")
        .replaceAll('&quot;', '"');
  }
}
