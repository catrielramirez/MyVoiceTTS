class AppLimits {
  static const int maxTextLength = 200;
  static const int maxSuggestions = 1;
  static const int debounceDurationMs = 300;

  static const int maxCacheSizeBytes = 50 * 1024 * 1024;
  static const int maxCacheAgeDays = 30;

  static const Duration retryDelay = Duration(seconds: 2);
  static const int maxRetryAttempts = 3;

  // Base de datos
  static const String dbName = 'tts_database.db';
  static const int dbVersion = 1;

  // Directorios
  static const String audioCacheDir = 'audio_cache';
}
