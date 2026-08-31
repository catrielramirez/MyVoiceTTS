import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_voice/logic/services/analytics_service.dart';

void main() {
  group('AnalyticsService Tests', () {
    late AnalyticsService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = AnalyticsService();
    });

    test('recordEvent() cache hit updates correct keys', () async {
      await service.recordEvent(isCache: true, ms: 50, text: 'Hola');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('tts_cache_hits'), 1);
      expect(prefs.getInt('tts_total_cache_time'), 50);
      expect(prefs.getDouble('tts_credits_saved'), greaterThan(0));
      expect(prefs.getInt('tts_api_calls'), isNull);
    });

    test('recordEvent() api call updates correct keys', () async {
      await service.recordEvent(isCache: false, ms: 500, text: 'Hola');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('tts_api_calls'), 1);
      expect(prefs.getInt('tts_total_api_time'), 500);
      expect(prefs.getDouble('tts_credits_spent'), greaterThan(0));
      expect(prefs.getInt('tts_cache_hits'), isNull);
    });

    test('getStats() returns defaults when empty', () async {
      final stats = await service.getStats();

      expect(stats['hits'], 0);
      expect(stats['misses'], 0);
      expect(stats['apiTimeAvg'], 0.0);
      expect(stats['cacheTimeAvg'], 0.0);
      expect(stats['creditsSaved'], 0.0);
      expect(stats['creditsSpent'], 0.0);
    });

    test('getStats() returns calculated averages correctly', () async {
      await service.recordEvent(isCache: true, ms: 50, text: 'abc');
      await service.recordEvent(isCache: true, ms: 150, text: 'abc');
      await service.recordEvent(isCache: false, ms: 400, text: 'abc');
      await service.recordEvent(isCache: false, ms: 600, text: 'abc');

      final stats = await service.getStats();

      expect(stats['hits'], 2);
      expect(stats['cacheTimeAvg'], 100.0); // (50+150)/2
      expect(stats['misses'], 2);
      expect(stats['apiTimeAvg'], 500.0); // (400+600)/2
    });

    test('resetMetrics() clears all values', () async {
      await service.recordEvent(isCache: true, ms: 50, text: 'Hola');
      
      final prefs1 = await SharedPreferences.getInstance();
      expect(prefs1.getInt('tts_cache_hits'), 1);

      await service.resetMetrics();
      
      final prefs2 = await SharedPreferences.getInstance();
      expect(prefs2.getInt('tts_cache_hits'), isNull);
    });
  });
}
