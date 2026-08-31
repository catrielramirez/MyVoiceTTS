import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_voice/data/models/frase.dart';
import 'package:my_voice/logic/services/phrases_manager_service.dart';

import '../../mock_classes.dart';

void main() {
  setUpAll(() {
    registerTestFallbacks();
  });

  group('PhrasesManagerService Tests', () {
    late PhrasesManagerService service;
    late MockAppDatabase mockDatabase;
    late MockAudioStorage mockStorage;
    late MockDatabase mockDbInstance;

    setUp(() {
      mockDatabase = MockAppDatabase();
      mockStorage = MockAudioStorage();
      mockDbInstance = MockDatabase();

      when(() => mockDatabase.database).thenAnswer((_) async => mockDbInstance);

      service = PhrasesManagerService(
        database: mockDatabase,
        storage: mockStorage,
      );
    });

    final testFrase = Frase(
      id: 1,
      texto: 'Hola',
      hash: 'hash_hola',
      pathAudio: '/path/hola.mp3',
      lastUsed: DateTime.now().millisecondsSinceEpoch,
    );

    test('deletePhrase() returns true when audio is deleted and DB row is removed', () async {
      when(() => mockStorage.deleteAudio(any())).thenAnswer((_) async => true);
      when(() => mockDbInstance.delete(
            'frases',
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          )).thenAnswer((_) async => 1); // 1 row deleted

      final result = await service.deletePhrase(testFrase);

      expect(result, isTrue);
      verify(() => mockStorage.deleteAudio('hash_hola')).called(1);
      verify(() => mockDbInstance.delete(
            'frases',
            where: 'hash = ?',
            whereArgs: ['hash_hola'],
          )).called(1);
    });

    test('deletePhrase() returns false if DB row was not found', () async {
      when(() => mockStorage.deleteAudio(any())).thenAnswer((_) async => true);
      when(() => mockDbInstance.delete(
            'frases',
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          )).thenAnswer((_) async => 0); // 0 rows deleted

      final result = await service.deletePhrase(testFrase);

      expect(result, isFalse);
    });

    test('deleteMultiplePhrases() counts successful and failed deletions', () async {
      final frase2 = testFrase.copyWith(id: 2, hash: 'hash_adios');

      when(() => mockStorage.deleteAudio('hash_hola')).thenAnswer((_) async => true);
      when(() => mockStorage.deleteAudio('hash_adios')).thenAnswer((_) async => true);
      
      when(() => mockDbInstance.delete(
            'frases',
            where: 'hash = ?',
            whereArgs: ['hash_hola'],
          )).thenAnswer((_) async => 1); // success
      
      when(() => mockDbInstance.delete(
            'frases',
            where: 'hash = ?',
            whereArgs: ['hash_adios'],
          )).thenAnswer((_) async => 0); // fail

      final result = await service.deleteMultiplePhrases([testFrase, frase2]);

      expect(result['successful'], 1);
      expect(result['failed'], 1);
    });

    test('getTotalPhrasesCount() returns correct count', () async {
      when(() => mockDbInstance.rawQuery(any())).thenAnswer((_) async => [
            {'count': 42}
          ]);

      final result = await service.getTotalPhrasesCount();
      expect(result, 42);
    });
  });
}
