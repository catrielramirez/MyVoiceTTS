import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:my_voice/core/tts_exception.dart';
import 'package:my_voice/data/sources/tts_service.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeUri extends Fake implements Uri {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  group('TtsService Tests', () {
    late TtsService ttsService;
    late MockHttpClient mockHttpClient;

    const String baseUrl = 'https://mock.supabase.co';
    const String anonKey = 'mock-anon-key';

    setUp(() {
      mockHttpClient = MockHttpClient();
      ttsService = TtsService(
        baseUrl: baseUrl,
        anonKey: anonKey,
        httpClient: mockHttpClient,
      );
    });

    test('generateAudio() throws Exception on empty text', () async {
      expect(
        () => ttsService.generateAudio(''),
        throwsA(isA<TtsApiException>()),
      );
    });

    test('generateAudio() returns audio bytes on success (200 OK)', () async {
      final mockResponseBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response.bytes(mockResponseBytes, 200));

      final result = await ttsService.generateAudio('Hola mundo');

      expect(result, equals(mockResponseBytes));
      verify(() => mockHttpClient.post(
            Uri.parse('$baseUrl/functions/v1/text-to-speech'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $anonKey',
            },
            body: jsonEncode({'text': 'Hola mundo'}),
          )).called(1);
    });

    test('generateAudio() throws TtsApiException on server error (500)', () async {
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Internal Server Error', 500));

      expect(
        () => ttsService.generateAudio('Hola mundo'),
        throwsA(isA<TtsApiException>()),
      );
    });

    test('generateAudio() throws TtsApiException on ClientException', () async {
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenThrow(http.ClientException('Error de red'));

      expect(
        () => ttsService.generateAudio('Hola mundo'),
        throwsA(isA<TtsApiException>()),
      );
    });
  });
}
