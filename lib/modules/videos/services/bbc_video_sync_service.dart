import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/bbc_video_item.dart';

class BbcVideoSyncService {
  final http.Client _client;
  SharedPreferences? _prefs;

  static const String _channelPageUrl = 'https://www.youtube.com/@bbclearningenglish/videos';
  static const String _prefCacheKey = 'bbc_videos_cache_json';
  static const String _prefSyncTimeKey = 'bbc_videos_last_sync_time';
  static const Duration syncInterval = Duration(hours: 1);

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  BbcVideoSyncService({http.Client? client, this._prefs})
      : _client = client ?? http.Client();

  Future<SharedPreferences> _getPrefs() async {
    final currentPrefs = _prefs;
    if (currentPrefs != null) return currentPrefs;
    final instance = await SharedPreferences.getInstance();
    _prefs = instance;
    return instance;
  }

  /// Fetches live BBC Learning English videos dynamically with a 1-hour cache policy.
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

    // Live scrape latest video IDs from BBC channel page
    try {
      final response =
          await _client.get(Uri.parse(_channelPageUrl), headers: _headers).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final html = response.body;
        final reg = RegExp(r'"videoId":"([a-zA-Z0-9_-]{11})"');
        final videoIds = reg.allMatches(html).map((m) => m.group(1)!).toSet().toList();

        final List<BbcVideoItem> fetchedList = [];
        for (final id in videoIds.take(6)) {
          final title = await _fetchVideoTitle(id);
          fetchedList.add(BbcVideoItem(
            id: id,
            title: title ?? 'BBC Learning English - Bài học mới',
            desc: 'Video bài học tiếng Anh truyền thông từ BBC Learning English.',
          ));
        }

        if (fetchedList.isNotEmpty) {
          final encoded = jsonEncode(fetchedList.map((e) => e.toMap()).toList());
          await prefs.setString(_prefCacheKey, encoded);
          await prefs.setInt(_prefSyncTimeKey, now.millisecondsSinceEpoch);
          return fetchedList;
        }
      }
    } catch (_) {
      // Fall through
    }

    // Return cached list if available
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

    return [];
  }

  Future<String?> _fetchVideoTitle(String videoId) async {
    try {
      final url = Uri.parse('https://noembed.com/embed?url=https://www.youtube.com/watch?v=$videoId');
      final res = await _client.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['title'] != null) {
          return data['title'].toString();
        }
      }
    } catch (_) {}
    return null;
  }

  /// Opens video in YouTube App if available, or falls back to Web Browser
  static Future<bool> openVideo(String videoId) async {
    final cleanId = videoId.trim();
    if (cleanId.isEmpty) return false;

    final appUri = Uri.parse('vnd.youtube:$cleanId');
    final webUri = Uri.parse('https://www.youtube.com/watch?v=$cleanId');

    try {
      if (await canLaunchUrl(appUri)) {
        final launchedApp = await launchUrl(
          appUri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
        if (launchedApp) return true;
      }
    } catch (_) {}

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
}
