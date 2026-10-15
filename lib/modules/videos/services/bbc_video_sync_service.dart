import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/bbc_video_item.dart';

class BbcVideoSyncService {
  final http.Client _client;
  static const String rssUrl =
      'https://www.youtube.com/feeds/videos.xml?playlist_id=UULFHaHD477h-FeBbVh9Sh7syA';

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

  BbcVideoSyncService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches latest BBC Learning English videos from YouTube RSS
  Future<List<BbcVideoItem>> fetchVideos() async {
    try {
      final response = await _client.get(Uri.parse(rssUrl)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final entries = document.findAllElements('entry');

        final List<BbcVideoItem> result = [];
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

            result.add(BbcVideoItem(
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

        if (result.isNotEmpty) {
          return result;
        }
      }
    } catch (_) {
      // Fall through to fallback videos
    }

    return fallbackVideos;
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
