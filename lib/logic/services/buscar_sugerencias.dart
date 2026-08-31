import 'package:logging/logging.dart';
import 'package:my_voice/data/sources/database.dart';
import 'package:my_voice/data/models/frase.dart';
import 'package:my_voice/core/utils.dart';

/// Capa lógica para manejar la búsqueda predictiva en la UI.
class BuscarSugerencias {
  final Logger _logger = Logger('BuscarSugerencias');
  final AppDatabase _database;
  final Utils _utils;

  // Declaramos los patrones aquí arriba como final, se crean una sola vez.
  final _acentosA = RegExp(r'[áàäâ]');
  final _acentosE = RegExp(r'[éèëê]');
  final _acentosI = RegExp(r'[íìïî]');
  final _acentosO = RegExp(r'[óòöô]');
  final _acentosU = RegExp(r'[úùüû]');
  final _puntuacion = RegExp(r'''[.,; :?¿!¡"'\-\(\)]''');
  final _espacios = RegExp(r'\s+');

  BuscarSugerencias({
    AppDatabase? database,
    Utils? utils,
  })  : _database = database ?? AppDatabase(),
        _utils = utils ?? Utils();

  /// Obtiene sugerencias ignorando puntuación (comas, signos, acentos)
  Future<List<Frase>> getSugerencias(String textoInicio) async {
    if (textoInicio.trim().isEmpty) return [];

    try {
      // 1. Limpiamos lo que escribió el usuario (ej: de "Mí" a "mi")
      final palabras = textoInicio.trim().split(' ');
      final primeraPalabraRaw =
          palabras.isNotEmpty ? palabras.first : textoInicio;
      final primeraPalabraLimpia = _normalizarParaBusqueda(primeraPalabraRaw);

      // 2. Pedimos candidatos a la base de datos
      final candidatos =
          await _database.buscarFrasesQueEmpiezanCon(primeraPalabraLimpia);

      // 3. Filtramos los resultados finales
      final textoUsuarioLimpio = _normalizarParaBusqueda(textoInicio);

      final sugerenciasFiltradas = candidatos.where((frase) {
        final fraseLimpia = _normalizarParaBusqueda(frase.texto);
        return fraseLimpia.startsWith(textoUsuarioLimpio);
      }).toList();

      return sugerenciasFiltradas.take(5).toList();
    } catch (e) {
      return [];
    }
  }

// FUNCIÓN DE LIMPIEZA 
  String _normalizarParaBusqueda(String texto) {
    String s = texto.toLowerCase();

    // samos las variables de arriba sin 'const'
    s = s
        .replaceAll(_acentosA, 'a')
        .replaceAll(_acentosE, 'e')
        .replaceAll(_acentosI, 'i')
        .replaceAll(_acentosO, 'o')
        .replaceAll(_acentosU, 'u');

    s = s.replaceAll(_puntuacion, '');
    s = s.replaceAll(_espacios, ' ');

    return s.trim();
  }

  /// Verifica si el texto actual ya ha sido generado y guardado antes.
  Future<bool> hasExactMatch(String texto) async {
    if (texto.isEmpty) return false;

    final normalizedText = _utils.normalizeText(texto);
    final hash = _utils.generateHash(normalizedText);

    // Buscamos por hash para exactitud técnica (audio existente)
    final frase = await _database.getFrasePorHash(hash);
    return frase != null;
  }

  /// Registra manualmente el uso de una frase
  Future<void> registrarUso(String texto) async {
    if (texto.isEmpty) return;

    final normalizedText = _utils.normalizeText(texto);
    final hash = _utils.generateHash(normalizedText);
    final now = DateTime.now().millisecondsSinceEpoch;

    await _database.actualizarUsoPorHash(hash, now);
    _logger.info('Uso actualizado manualmente para la frase: $hash');
  }
}
