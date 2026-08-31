import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static const String _keyHits = 'tts_cache_hits';
  static const String _keyMisses = 'tts_api_calls';
  static const String _keyApiTime = 'tts_total_api_time';
  static const String _keyCacheTime = 'tts_total_cache_time';
  static const String _keyStartDate = 'tts_analytics_start_date';
  static const String _keyCreditsSaved = 'tts_credits_saved';
  static const String _keyCreditsSpent = 'tts_credits_spent';

  // Estimación técnica: 15 caracteres por segundo de habla (promedio humano).
  // 1 Crédito = 60 segundos de audio.
  // Fórmula: Créditos = (Caracteres / 15) / 60
  double _calculateCredits(int textLength) {
    if (textLength <= 0) return 0.0;
    return (textLength / 15) / 60;
  }

  Future<void> recordEvent(
      {required bool isCache, required int ms, required String text}) async {
    final prefs = await SharedPreferences.getInstance();
    final double credits = _calculateCredits(text.length);

    if (isCache) {
      await prefs.setInt(_keyHits, (prefs.getInt(_keyHits) ?? 0) + 1);
      await prefs.setInt(
          _keyCacheTime, (prefs.getInt(_keyCacheTime) ?? 0) + ms);
      await prefs.setDouble(_keyCreditsSaved,
          (prefs.getDouble(_keyCreditsSaved) ?? 0.0) + credits);
    } else {
      await prefs.setInt(_keyMisses, (prefs.getInt(_keyMisses) ?? 0) + 1);
      await prefs.setInt(_keyApiTime, (prefs.getInt(_keyApiTime) ?? 0) + ms);
      await prefs.setDouble(_keyCreditsSpent,
          (prefs.getDouble(_keyCreditsSpent) ?? 0.0) + credits);
    }

    if (prefs.getString(_keyStartDate) == null) {
      await prefs.setString(_keyStartDate, DateTime.now().toIso8601String());
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    int hits = prefs.getInt(_keyHits) ?? 0;
    int misses = prefs.getInt(_keyMisses) ?? 0;

    return {
      'hits': hits,
      'misses': misses,
      'apiTimeAvg':
          misses == 0 ? 0.0 : (prefs.getInt(_keyApiTime) ?? 0) / misses,
      'cacheTimeAvg':
          hits == 0 ? 0.0 : (prefs.getInt(_keyCacheTime) ?? 0) / hits,
      'creditsSaved': prefs.getDouble(_keyCreditsSaved) ?? 0.0,
      'creditsSpent': prefs.getDouble(_keyCreditsSpent) ?? 0.0,
      'startDate': DateTime.tryParse(prefs.getString(_keyStartDate) ?? '') ??
          DateTime.now(),
    };
  }

  Future<void> resetMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHits);
    await prefs.remove(_keyMisses);
    await prefs.remove(_keyApiTime);
    await prefs.remove(_keyCacheTime);
    await prefs.remove(_keyStartDate);
    await prefs.remove(_keyCreditsSaved);
    await prefs.remove(_keyCreditsSpent);
  }
}
