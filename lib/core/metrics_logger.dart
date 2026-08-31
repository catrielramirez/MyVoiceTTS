import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:logging/logging.dart';
import 'package:my_voice/core/utils.dart';

/// Clase especializada en medir el rendimiento del sistema de voz.
/// Ayuda a optimizar la latencia y el uso de la caché.
class MetricsLogger {
  // Usamos un logger específico para métricas para poder filtrarlo fácilmente
  static final Logger _logger = Logger('Metrics');
  static final Utils _utils = Utils();

  /// Crea el paquete de datos (payload) para el evento.
  static Map<String, dynamic> _buildPayload({
    required String event,
    String? text,
    int? cacheSizeBytes,
    int? responseTimeMs,
    String? hash,
  }) {
    return {
      'event': event,
      'timestamp': DateTime.now().toIso8601String(),
      // En debug vemos el texto, en producción solo el hash por privacidad
      if (text != null) 'text': kDebugMode ? text : 'REDACTED',
      'hash': hash ??
          (text != null
              ? _utils.generateHash(_utils.normalizeText(text))
              : null),
      if (cacheSizeBytes != null)
        'cache_size_mb': (cacheSizeBytes / (1024 * 1024)).toStringAsFixed(2),
      if (responseTimeMs != null) 'latency_ms': responseTimeMs,
    };
  }

  /// Registra cuánto tardó una operación (ej. llamada a supabase).
  static void logLatency(String operation, Duration duration) {
    final payload = _buildPayload(
      event: 'latency',
      text: operation,
      responseTimeMs: duration.inMilliseconds,
    );
    _logger.info(jsonEncode(payload));
  }

  /// Registra cuando una frase se recuperó con éxito de la memoria o disco.
  static void logCacheHit(String text) {
    final payload = _buildPayload(
      event: 'cache_hit',
      text: text,
    );
    _logger.fine(jsonEncode(payload));
  }

  /// Registra cuando hubo que acudir a la API porque no estaba en caché.
  static void logCacheMiss(String text) {
    final payload = _buildPayload(
      event: 'cache_miss',
      text: text,
    );
    _logger
        .warning(jsonEncode(payload)); // Warning porque el miss genera latencia
  }

  /// Registra un error crítico en la generación de audio.
  static void logGenerationError(String text, String error) {
    final payload = _buildPayload(
      event: 'generation_error',
      text: text,
    )..['error'] = error;
    _logger.severe(jsonEncode(payload));
  }
}
