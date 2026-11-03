import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:langcurve/modules/videos/services/bbc_video_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BbcVideoSyncService Caching & Sync Tests', () {
    test('Returns empty list if network fails and no cache exists', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final service = BbcVideoSyncService(client: mockClient);
      final videos = await service.fetchVideos();

      expect(videos.isEmpty, isTrue);
    });

    test('Caches fetched videos for 1 hour', () async {
      int apiCallCount = 0;
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('noembed.com')) {
          return http.Response('{"title": "Test Title"}', 200);
        }
        apiCallCount++;
        const mockHtml = '''
          <html lang="en">
            <body>
              "videoId":"LMtpF7ZQqGA"
            </body>
          </html>
        ''';
        return http.Response(mockHtml, 200);
      });

      final prefs = await SharedPreferences.getInstance();
      final service = BbcVideoSyncService(client: mockClient, prefs: prefs);

      // First fetch -> calls channel page
      final list1 = await service.fetchVideos();
      expect(apiCallCount, equals(1));
      expect(list1.first.id, equals('LMtpF7ZQqGA'));

      // Second fetch within 1 hour -> uses cached data (0 extra channel page calls)
      final list2 = await service.fetchVideos();
      expect(apiCallCount, equals(1)); // Still 1 call!
      expect(list2.first.id, equals('LMtpF7ZQqGA'));

      // Force refresh -> bypasses 1-hour cache
      final list3 = await service.fetchVideos(forceRefresh: true);
      expect(apiCallCount, equals(2));
      expect(list3.first.id, equals('LMtpF7ZQqGA'));
    });
  });
}
