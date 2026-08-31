import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_voice/data/models/frase.dart';
import 'package:my_voice/logic/services/phrase_audio_service.dart';

import '../../mock_classes.dart';

void main() {
  setUpAll(() {
    registerTestFallbacks();
  });

  group('PhraseAudioService Tests', () {
    late PhraseAudioService service;
    late MockAppDatabase mockDatabase;
    late MockAudioStorage mockStorage;
    late MockTtsServiceInterface mockTtsService;
    late MockUtils mockUtils;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockDatabase = MockAppDatabase();
      mockStorage = MockAudioStorage();
      mockTtsService = MockTtsServiceInterface();
      mockUtils = MockUtils();

      service = PhraseAudioService(
        database: mockDatabase,
        storage: mockStorage,
        ttsService: mockTtsService,
        utils: mockUtils,
      );
    });

    test('getAudioPathForText() returns null if text is empty', () async {
      final path = await service.getAudioPathForText('');
      expect(path, isNull);
    });

    test('getAudioPathForText() uses cache when available', () async {
      when(() => mockUtils.normalizeText('Hola')).thenReturn('Hola');
      when(() => mockUtils.generateHash('Hola')).thenReturn('hash123');
      
      final frase = Frase(
        texto: 'Hola', 
        hash: 'hash123', 
        pathAudio: '/local/audio.mp3',
        lastUsed: DateTime.now().millisecondsSinceEpoch,
      );
      
      when(() => mockDatabase.getFrasePorHash('hash123')).thenAnswer((_) async => frase);
      when(() => mockStorage.audioExists('hash123')).thenAnswer((_) async => true);
      when(() => mockDatabase.actualizarUsoPorHash('hash123', any())).thenAnswer((_) async {});

      final path = await service.getAudioPathForText('Hola');

      expect(path, '/local/audio.mp3');
      verify(() => mockDatabase.getFrasePorHash('hash123')).called(1);
      verify(() => mockStorage.audioExists('hash123')).called(1);
      verify(() => mockDatabase.actualizarUsoPorHash('hash123', any())).called(1);
      verifyNever(() => mockTtsService.generateAudio(any()));
    });

    test('getAudioPathForText() calls TTS when cache misses', () async {
      when(() => mockUtils.normalizeText('Hola')).thenReturn('Hola');
      when(() => mockUtils.generateHash('Hola')).thenReturn('hash123');
      
      when(() => mockDatabase.getFrasePorHash('hash123')).thenAnswer((_) async => null);
      
      final mockAudioBytes = Uint8List.fromList([1, 2, 3]);
      when(() => mockTtsService.generateAudio('Hola')).thenAnswer((_) async => mockAudioBytes);
      when(() => mockStorage.saveAudio('hash123', mockAudioBytes)).thenAnswer((_) async => '/new/audio.mp3');
      when(() => mockDatabase.insertarNuevaFrase(any())).thenAnswer((_) async => 1);

      final path = await service.getAudioPathForText('Hola');

      expect(path, '/new/audio.mp3');
      verify(() => mockTtsService.generateAudio('Hola')).called(1);
      verify(() => mockStorage.saveAudio('hash123', mockAudioBytes)).called(1);
      verify(() => mockDatabase.insertarNuevaFrase(any())).called(1);
    });

    test('performMaintenance() cleans old phrases', () async {
      final oldFrase = Frase(
        texto: 'Viejo',
        hash: 'hash_viejo',
        pathAudio: '/old.mp3',
        lastUsed: DateTime.now().millisecondsSinceEpoch,
      );

      when(() => mockDatabase.getFrasesAntiguas(any())).thenAnswer((_) async => [oldFrase]);
      when(() => mockStorage.deleteAudio('hash_viejo')).thenAnswer((_) async => true);
      when(() => mockDatabase.actualizarAudioPathPorHash('hash_viejo', null)).thenAnswer((_) async {});

      await service.performMaintenance(daysThreshold: 30);

      verify(() => mockDatabase.getFrasesAntiguas(any())).called(1);
      verify(() => mockStorage.deleteAudio('hash_viejo')).called(1);
      verify(() => mockDatabase.actualizarAudioPathPorHash('hash_viejo', null)).called(1);
    });

    test('clearAllCache() clears storage', () async {
      when(() => mockStorage.clearAll()).thenAnswer((_) async {});

      await service.clearAllCache();

      verify(() => mockStorage.clearAll()).called(1);
    });
  });
}
