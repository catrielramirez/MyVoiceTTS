/// Excepción de dominio para errores relacionados con Text-to-Speech.
///
/// No representa errores técnicos específicos (HTTP, Socket, etc),
/// sino fallos funcionales en la generación de audio.
class TtsApiException implements Exception {
  final String message;

  const TtsApiException(this.message);

  @override
  String toString() => 'TtsApiException: $message';
}
