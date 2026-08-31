import 'package:my_voice/data/models/frase.dart';

abstract class IFraseRepository {
  /// Inserta una frase ya normalizada y hasheada
  Future<int> insertFrase(Frase frase);

  /// Lookup exacto por hash (clave primaria lógica)
  Future<Frase?> getFrasePorHash(String hash);

  /// Autocomplete por prefijo de texto
  Future<List<Frase>> searchFrases(String query);

  /// Actualiza el path de audio usando hash
  Future<void> updateFrasePathAudioPorHash(
    String hash,
    String path,
  );

  /// Incrementa uso y actualiza lastUsed
  Future<void> actualizarUsoFrasePorHash(String hash);
}
