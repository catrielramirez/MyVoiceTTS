import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:my_voice/data/sources/database.dart';
import 'package:my_voice/data/sources/audio_storage.dart';
import 'package:my_voice/data/models/frase.dart';
import 'package:my_voice/logic/interfaces/tts_service_interface.dart';
import 'package:my_voice/core/utils.dart';
import 'package:my_voice/logic/services/analytics_service.dart'; 

/// Orquestador principal: Coordina la generación, almacenamiento y registro de voz.
class PhraseAudioService {
  final Logger _logger = Logger('PhraseAudioService');

  final AppDatabase _database;
  final AudioStorage _storage;
  final TtsServiceInterface _ttsService;
  final Utils _utils;
  final AnalyticsService _analytics =
      AnalyticsService(); // Instancia de métricas

  PhraseAudioService({
    AppDatabase? database,
    AudioStorage? storage,
    required TtsServiceInterface ttsService,
    Utils? utils,
  })  : _database = database ?? AppDatabase(),
        _storage = storage ?? AudioStorage(),
        _ttsService = ttsService,
        _utils = utils ?? Utils();

  /// Fast path: si la Frase ya tiene pathAudio y el archivo existe en disco,
  /// lo devuelve directamente sin repetir normalización, hash ni consulta a BD.
  /// Solo cae al pipeline completo si el archivo no existe en disco.
  Future<String?> getAudioPathForFrase(Frase frase) async {
    if (frase.pathAudio != null) {
      final fileExists = await _storage.audioExists(frase.hash);
      if (fileExists) {
        await _database.actualizarUsoPorHash(
            frase.hash, DateTime.now().millisecondsSinceEpoch);
        _logger.info(
            'Fast path: audio servido desde path conocido para: ${frase.hash}');
        return frase.pathAudio;
      }
      // El archivo fue borrado del disco → caída al pipeline completo
      _logger.warning(
          'Fast path falló: archivo no existe en disco para ${frase.hash}, regenerando.');
    }
    // Fallback: sin pathAudio o archivo borrado
    return getAudioPathForText(frase.texto);
  }

  /// El método principal: Obtiene la ruta del audio para un texto.
  Future<String?> getAudioPathForText(String text) async {
    if (text.isEmpty) return null;

    final stopwatch = Stopwatch()
      ..start(); // Iniciamos cronómetro para métricas
    final normalizedText = _utils.normalizeText(text);
    final hash = _utils.generateHash(normalizedText);

    try {
      // 1. Buscar en BD
      final existing = await _database.getFrasePorHash(hash);

      // 2. Si existe en BD y el archivo físico está, lo devolvemos
      if (existing != null && existing.pathAudio != null) {
        final fileExists = await _storage.audioExists(hash);
        if (fileExists) {
          stopwatch.stop();

          // REGISTRO DE MÉTRICA: Hit de Caché
          await _analytics.recordEvent(
            isCache: true,
            ms: stopwatch.elapsedMilliseconds,
            text: normalizedText,
          );

          _logger.info('Audio encontrado en caché local para: $hash');
          await _database.actualizarUsoPorHash(
              hash, DateTime.now().millisecondsSinceEpoch);
          return existing.pathAudio;
        } else {
          _logger.warning(
              'La BD dice que el audio existe, pero el archivo no está en el disco.');
        }
      }

      // 3. Si no existe o falta el archivo, generar vía TTS
      _logger.info('Generando audio nuevo en la nube para: $text');
      final Uint8List audioBytes =
          await _ttsService.generateAudio(normalizedText);

      stopwatch.stop();

      // REGISTRO DE MÉTRICA: Llamada a API (Miss)
      await _analytics.recordEvent(
        isCache: false,
        ms: stopwatch.elapsedMilliseconds,
        text: normalizedText,
      );

      if (audioBytes.isEmpty) {
        throw Exception('El servidor devolvió un archivo de audio vacío.');
      }

      // 4. Guardar archivo físico en el celular
      final String path = await _storage.saveAudio(hash, audioBytes);
      _logger.info('Nuevo audio guardado físicamente en: $path');

      // 5. Actualizar o Insertar en BD
      if (existing == null) {
        await _database.insertarNuevaFrase(Frase(
          texto: normalizedText,
          hash: hash,
          pathAudio: path,
          usoCount: 1,
          lastUsed: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        await _database.actualizarAudioPathPorHash(hash, path);
        await _database.actualizarUsoPorHash(
            hash, DateTime.now().millisecondsSinceEpoch);
      }

      return path;
    } catch (e, stack) {
      _logger.severe('ERROR CRÍTICO procesando frase: $text', e, stack);
      rethrow;
    }
  }

  /// Limpia audios que no se han usado en [daysThreshold] días para ahorrar espacio.
  Future<void> performMaintenance({int daysThreshold = 30}) async {
    try {
      _logger.info(
          'Iniciando mantenimiento de caché (Umbral: $daysThreshold días)...');

      final int thresholdMillis = DateTime.now()
          .subtract(Duration(days: daysThreshold))
          .millisecondsSinceEpoch;

      final frasesAntiguas = await _database.getFrasesAntiguas(thresholdMillis);

      if (frasesAntiguas.isEmpty) {
        _logger.info('No hay audios antiguos para limpiar.');
        return;
      }

      int borrados = 0;
      for (var frase in frasesAntiguas) {
        final exito = await _storage.deleteAudio(frase.hash);
        if (exito) {
          await _database.actualizarAudioPathPorHash(frase.hash, null);
          borrados++;
        }
      }
      _logger.info(
          'Mantenimiento finalizado. Se liberaron $borrados archivos de audio.');
    } catch (e) {
      _logger.warning('Error en el mantenimiento de caché: $e');
    }
  }

  /// Borra TODO el caché de audios generados.
  Future<void> clearAllCache() async {
    await _storage.clearAll();
    _logger.warning('Caché de audio totalmente eliminada.');
  }
}
