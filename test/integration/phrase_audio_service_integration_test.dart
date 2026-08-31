import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:my_voice/data/sources/database.dart';
import 'package:my_voice/logic/services/phrase_audio_service.dart';
import 'package:my_voice/core/utils.dart';

import '../mock_classes.dart';

void main() {
  group('PhraseAudioService Integration Tests', () {
    late PhraseAudioService service;
    late AppDatabase realDatabase;
    late MockAudioStorage mockStorage;
    late MockTtsServiceInterface mockTtsService;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      
      final dbPath = await getDatabasesPath();
      final path = '$dbPath/tts_database.db';
      await deleteDatabase(path);

      realDatabase = AppDatabase();
      mockStorage = MockAudioStorage();
      mockTtsService = MockTtsServiceInterface();

      service = PhraseAudioService(
        database: realDatabase,
        storage: mockStorage,
        ttsService: mockTtsService,
        utils: Utils(), // Use real Utils
      );
    });

    test('First request generates TTS, saves to DB and storage', () async {
      final text = 'Prueba de integracion';
      final mockBytes = Uint8List.fromList([1, 2, 3]);

      when(() => mockTtsService.generateAudio(any())).thenAnswer((_) async => mockBytes);
      when(() => mockStorage.saveAudio(any(), any())).thenAnswer((_) async => '/fake/path.mp3');

      final path = await service.getAudioPathForText(text);

      expect(path, '/fake/path.mp3');
      
      // Verification
      verify(() => mockTtsService.generateAudio('Prueba de integracion')).called(1);
      verify(() => mockStorage.saveAudio(any(), mockBytes)).called(1);

      // Verify it was actually saved in the real database
      final hash = Utils().generateHash('Prueba de integracion');
      final savedFrase = await realDatabase.getFrasePorHash(hash);
      
      expect(savedFrase, isNotNull);
      expect(savedFrase!.texto, 'Prueba de integracion');
      expect(savedFrase.vecesUsada, 1);
    });

    test('Second request uses cache if audio exists', () async {
      final text = 'Prueba cache';
      final hash = Utils().generateHash('Prueba cache');
      final mockBytes = Uint8List.fromList([1, 2, 3]);

      // 1. First request
      when(() => mockTtsService.generateAudio(any())).thenAnswer((_) async => mockBytes);
      when(() => mockStorage.saveAudio(any(), any())).thenAnswer((_) async => '/fake/path.mp3');
      
      await service.getAudioPathForText(text);

      // 2. Second request
      when(() => mockStorage.audioExists(hash)).thenAnswer((_) async => true);

      final path2 = await service.getAudioPathForText(text);
      expect(path2, '/fake/path.mp3');

      // TTS should still only be called ONCE
      verify(() => mockTtsService.generateAudio(any())).called(1);
      
      // Usage should be 2
      final savedFrase = await realDatabase.getFrasePorHash(hash);
      expect(savedFrase!.vecesUsada, 2);
    });
  });
}
