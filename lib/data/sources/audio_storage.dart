import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

class AudioStorage {
  final Logger _logger = Logger('AudioStorage');
  final Map<String, Uint8List> _inMemoryCache = {};
  String? _audioDirectory;

  /// Garantiza que el directorio exista antes de operar
  Future<void> _ensureInitialized() async {
    if (_audioDirectory != null) return;

    final dir = await getApplicationDocumentsDirectory();
    _audioDirectory = p.join(dir.path, 'audio_cache');
    final directory = Directory(_audioDirectory!);

    if (!await directory.exists()) {
      await directory.create(recursive: true);
      _logger.info('Directorio de audio creado en: $_audioDirectory');
    }
  }

  /// Verifica si el archivo de audio existe físicamente en el disco.
  /// Requerido por PhraseAudioService.
  Future<bool> audioExists(String hash) async {
    await _ensureInitialized();
    final path = p.join(_audioDirectory!, '$hash.mp3');
    return await File(path).exists();
  }

  /// Guarda los bytes en disco y en memoria
  Future<String> saveAudio(String hash, Uint8List bytes) async {
    await _ensureInitialized();

    final path = p.join(_audioDirectory!, '$hash.mp3');
    final file = File(path);

    await file.writeAsBytes(bytes);
    _inMemoryCache[hash] = bytes;

    _logger.fine('Archivo guardado exitosamente: $path');
    return path;
  }

  /// Recupera los bytes primero desde memoria, luego desde disco
  Future<Uint8List?> getAudio(String hash) async {
    if (_inMemoryCache.containsKey(hash)) {
      return _inMemoryCache[hash];
    }

    await _ensureInitialized();
    final path = p.join(_audioDirectory!, '$hash.mp3');
    final file = File(path);

    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      _inMemoryCache[hash] = bytes;
      return bytes;
    }

    return null;
  }

  /// NUEVO: Elimina un audio específico de memoria y disco
  Future<bool> deleteAudio(String hash) async {
    try {
      // Eliminar de caché en memoria
      _inMemoryCache.remove(hash);

      // Eliminar archivo físico
      await _ensureInitialized();
      final path = p.join(_audioDirectory!, '$hash.mp3');
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
        _logger.info('Audio eliminado: $hash.mp3');
        return true;
      }

      _logger.warning('Audio no encontrado para eliminar: $hash.mp3');
      return false;
    } catch (e, stack) {
      _logger.severe('Error eliminando audio: $hash', e, stack);
      return false;
    }
  }

  /// Borra la caché de memoria.
  void clearMemoryCache() => _inMemoryCache.clear();

  /// Borra TODO: memoria y archivos físicos en disco.
  /// Requerido por PhraseAudioService.
  Future<void> clearAll() async {
    _inMemoryCache.clear();
    await _ensureInitialized();

    final directory = Directory(_audioDirectory!);
    if (await directory.exists()) {
      // Borra la carpeta y todo su contenido
      await directory.delete(recursive: true);
      // La recreamos vacía para futuras operaciones
      await directory.create(recursive: true);
      _logger
          .warning('Toda la caché de audio física y memoria ha sido borrada.');
    }
  }
}
