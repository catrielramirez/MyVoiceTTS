import 'dart:typed_data';

// Interfaz abstracta para TtsService
abstract class TtsServiceInterface {
  Future<Uint8List> generateAudio(String text);
}
