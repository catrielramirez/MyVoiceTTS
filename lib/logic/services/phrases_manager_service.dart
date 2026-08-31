import 'package:logging/logging.dart';
import 'package:my_voice/data/sources/database.dart';
import 'package:my_voice/data/sources/audio_storage.dart';
import 'package:my_voice/data/models/frase.dart';

/// Servicio para gestionar listado, ordenamiento y eliminación de frases
class PhrasesManagerService {
  final Logger _logger = Logger('PhrasesManagerService');
  final AppDatabase _database;
  final AudioStorage _storage;

  PhrasesManagerService({
    required AppDatabase database,
    required AudioStorage storage,
  })  : _database = database,
        _storage = storage;

  /// Obtiene solo una cantidad limitada de frases (ej: las últimas 5)
  Future<List<Frase>> getLastPhrases(int limit) async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'frases',
        orderBy: 'last_used DESC, uso_count DESC',
        limit: limit, // Limitamos la cantidad
      );

      return result.map(Frase.fromMap).toList();
    } catch (e, stack) {
      _logger.severe('Error obteniendo ultimas frases', e, stack);
      return [];
    }
  }

  /// Obtiene TODAS las frases ordenadas (Para el Historial)
  Future<List<Frase>> getAllPhrasesByLastUsed() async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'frases',
        orderBy: 'last_used DESC, uso_count DESC',
      );

      return result.map(Frase.fromMap).toList();
    } catch (e, stack) {
      _logger.severe('Error obteniendo frases ordenadas', e, stack);
      return [];
    }
  }

  /// Actualiza la fecha de último uso para el reordenamiento
  Future<void> updatePhraseUsage(String text) async {
    try {
      final db = await _database.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.rawUpdate('''
        UPDATE frases 
        SET last_used = ?, uso_count = uso_count + 1 
        WHERE texto = ?
      ''', [now, text]);

      _logger.info('Uso actualizado para frase: "$text"');
    } catch (e, stack) {
      _logger.warning('Error actualizando uso de frase', e, stack);
    }
  }

  /// Elimina una frase completamente: archivo físico + BD
  Future<bool> deletePhrase(Frase frase) async {
    try {
      _logger.info('Eliminando frase: ${frase.hash}');

      await _storage.deleteAudio(frase.hash);

      final db = await _database.database;
      final deletedRows = await db.delete(
        'frases',
        where: 'hash = ?',
        whereArgs: [frase.hash],
      );

      if (deletedRows == 0) {
        _logger.warning('No se encontró la frase en BD: ${frase.hash}');
        return false;
      }

      _logger.info('Frase eliminada correctamente: ${frase.hash}');
      return true;
    } catch (e, stack) {
      _logger.severe('Error eliminando frase: ${frase.hash}', e, stack);
      return false;
    }
  }

  /// Elimina múltiples frases en batch
  Future<Map<String, int>> deleteMultiplePhrases(List<Frase> phrases) async {
    int successful = 0;
    int failed = 0;

    for (final phrase in phrases) {
      final deleted = await deletePhrase(phrase);
      if (deleted) {
        successful++;
      } else {
        failed++;
      }
    }
    return {'successful': successful, 'failed': failed};
  }

  Future<int> getTotalPhrasesCount() async {
    try {
      final db = await _database.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM frases');
      return (result.first['count'] as int?) ?? 0;
    } catch (e, stack) {
      _logger.warning('Error obteniendo conteo de frases', e, stack);
      return 0;
    }
  }
}