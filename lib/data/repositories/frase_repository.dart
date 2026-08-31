import 'package:my_voice/data/sources/database.dart';
import 'package:my_voice/data/models/frase.dart';
import 'package:my_voice/logic/interfaces/IFraseRepository.dart';
import 'package:my_voice/core/utils.dart';

class FraseRepository implements IFraseRepository {
  final AppDatabase _database;
  final Utils _utils;

  FraseRepository({required AppDatabase database, Utils? utils})
      : _database = database,
        _utils = utils ?? Utils();

  @override
  Future<int> insertFrase(Frase frase) async {
    final normalizedText = _utils.normalizeText(frase.texto);
    final hash = _utils.generateHash(normalizedText);
    final now = DateTime.now().millisecondsSinceEpoch;

    final fraseToInsert = frase.copyWith(
      texto: normalizedText,
      hash: hash,
      lastUsed: now,
    );

    return _database.insertarNuevaFrase(fraseToInsert);
  }

  @override
  Future<Frase?> getFrasePorHash(String hash) async {
    return _database.getFrasePorHash(hash);
  }

  @override
  Future<List<Frase>> searchFrases(String query) async {
    // Si el query está vacío, devolvemos lista vacía sin tocar la DB
    if (query.trim().isEmpty) return [];

    final normalizedQuery = _utils.normalizeText(query);
    return _database.buscarFrasesQueEmpiezanCon(normalizedQuery);
  }

  @override
  Future<void> updateFrasePathAudioPorHash(
    String hash,
    String newPathAudio,
  ) async {
    await _database.actualizarAudioPathPorHash(hash, newPathAudio);
  }

  @override
  Future<void> actualizarUsoFrasePorHash(String hash) async {
    await _database.actualizarUsoPorHash(
      hash,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
