import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:my_voice/core/app_limits.dart';

class Utils {
  final Logger _logger;

  Utils({Logger? logger}) : _logger = logger ?? Logger('Utils');

  /// Normaliza texto para uso interno (hash, búsqueda, cache).
  /// No lanza excepciones.
  String normalizeText(String text) {
    if (text.isEmpty) return '';

    try {
      final allowedCharsRegex = RegExp(r'[^a-zA-Z0-9\sáéíóúÁÉÍÓÚñÑüÜ.,!?¿¡-]');

      return text
          .trim()

          /// Elmina espacios al principio y al final
          .replaceAll(RegExp(r'\s+'), ' ')

          /// uno o mas espacios, tab, saltos de linea se reemplazan un solo espacio
          .replaceAll(allowedCharsRegex, '')

          /// reemplaza los caracteres no permitidos por vacio
          .toLowerCase(); // normaliza mayusculas
    } catch (e, stack) {
      _logger.warning('Error normalizando texto', e, stack);
      return text.trim().toLowerCase();
    }
  }

  /// Genera un hash SHA256 del texto NORMALIZADO.
  /// SHA-256 transforma datos arbitrarios en una huella digital fija, segura y no reversible
  /// Contrato: siempre llama internamente a normalizeText.
  String generateHash(String text) {
    try {
      final normalizedText = normalizeText(text);
      final bytes = utf8.encode(normalizedText);
      return sha256.convert(bytes).toString();
    } catch (e, stack) {
      _logger.severe('Error generando hash', e, stack);
      return '';
    }
  }

  /// Debounce por clave lógica
  final Map<String, Timer> _debounceTimers = {};

  void debounce({
    required String key,
    required VoidCallback action,
    required Duration duration,
  }) {
    _debounceTimers[key]?.cancel();

    _debounceTimers[key] = Timer(duration, () {
      try {
        action();
      } catch (e, stack) {
        _logger.severe('Error ejecutando debounce [$key]', e, stack);
      } finally {
        _debounceTimers.remove(key);
      }
    });
  }

  /// Verifica si el texto está dentro del límite permitido.
  bool isTextWithinLimit(String text) {
    try {
      return text.length <= AppLimits.maxTextLength;
    } catch (e, stack) {
      _logger.severe('Error validando límite de texto', e, stack);
      return false;
    }
  }
}
