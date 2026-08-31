import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:my_voice/data/sources/database.dart';
import 'package:my_voice/data/models/frase.dart';
import 'package:my_voice/core/utils.dart';

class SeedData {
  static final Logger _logger = Logger('SeedData');
  static final AppDatabase _db = AppDatabase();
  static final Utils _utils = Utils();

  static Future<void> insertSampleData() async {
    if (!kDebugMode) return;

    _logger.info('Preparando datos de prueba...');

    final now = DateTime.now();

    final frasesData = [
      {'t': 'Hola, ¿cómo estás?', 'c': 15, 'd': 2},
      {'t': 'Buenos días', 'c': 8, 'd': 10},
      {'t': 'Gracias por tu ayuda', 'c': 3, 'd': 60},
      {'t': 'Hasta luego', 'c': 20, 'd': 5},
    ];

    try {
      for (final data in frasesData) {
        final frase = _buildFrase(
          texto: data['t'] as String,
          usoCount: data['c'] as int,
          lastUsed: now.subtract(Duration(minutes: data['d'] as int)),
        );
        await _db.insertarNuevaFrase(frase);
      }
      _logger.info('Seed finalizado: Frases de prueba listas.');
    } catch (e) {
      _logger.severe('Error al insertar datos de prueba: $e');
    }
  }

  static Frase _buildFrase({
    required String texto,
    int usoCount = 0,
    required DateTime lastUsed,
  }) {
    final normalizedText = _utils.normalizeText(texto);
    final hash = _utils.generateHash(normalizedText);

    return Frase(
      texto: normalizedText,
      hash: hash,
      pathAudio: null,
      usoCount: usoCount,
      lastUsed: lastUsed.millisecondsSinceEpoch,
    );
  }

  static Future<void> clearAllData() async {
    if (!kDebugMode) return;
    final db = await _db.database;
    await db.delete('frases');
    _logger.warning('Base de datos de frases vaciada');
  }
}
