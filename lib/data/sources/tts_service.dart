import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:my_voice/logic/interfaces/tts_service_interface.dart';
import 'package:my_voice/core/tts_exception.dart';

/// Implementación del servicio TTS vía Supabase Edge Functions.
class TtsService implements TtsServiceInterface {
  final String _baseUrl;
  final String _anonKey;
  final Logger _logger = Logger('TtsService');
  final http.Client _httpClient;

  // El constructor recibe la URL y la Key desde el main.dart
  TtsService({
    required String baseUrl,
    required String anonKey,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl,
        _anonKey = anonKey,
        _httpClient = httpClient ?? http.Client();

  @override
  Future<Uint8List> generateAudio(String text) async {
    if (text.isEmpty) {
      throw const TtsApiException('Texto vacío para generar audio');
    }

    // Construcción dinámica de la URL de la función
    final String functionUrl = '$_baseUrl/functions/v1/text-to-speech';

    try {
      _logger.info(
          'Solicitando audio al backend para: ${text.substring(0, text.length > 20 ? 20 : text.length)}...');

      final response = await _httpClient.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_anonKey',
        },
        body: jsonEncode({
          'text': text,
        }),
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        _logger.info(
          'Audio recibido del backend (${response.bodyBytes.length} bytes)',
        );
        return response.bodyBytes;
      }

      // Manejo de errores detallado proveniente de la Edge Function
      throw TtsApiException(
        'Error del Backend (${response.statusCode}): ${response.body}',
      );
    } on http.ClientException catch (e) {
      throw TtsApiException('Error de red: ${e.message}');
    } on SocketException {
      throw const TtsApiException('Sin conexión a internet');
    } catch (e) {
      _logger.severe('Error inesperado en TtsService: $e');
      throw TtsApiException('Error inesperado: $e');
    }
  }
}
