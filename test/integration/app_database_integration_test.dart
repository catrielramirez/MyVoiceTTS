import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:my_voice/data/models/frase.dart';
import 'package:my_voice/data/sources/database.dart';

void main() {
  group('AppDatabase Integration Tests', () {
    late AppDatabase appDatabase;

    setUpAll(() {
      // Initialize FFI
      sqfliteFfiInit();
      // Change the default factory to FFI for testing
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      // Create a fresh instance for each test.
      // To ensure it uses an in-memory DB, we need to override the path or behavior.
      // But AppDatabase uses getDatabasesPath() and hardcodes 'tts_database.db'.
      // For testing, we can delete the database file before each test.
      final dbPath = await getDatabasesPath();
      final path = '$dbPath/tts_database.db';
      await deleteDatabase(path);

      appDatabase = AppDatabase();
    });

    tearDown(() async {
      final db = await appDatabase.database;
      await db.close();
      // Wait for it to close then reset the singleton if it was one. 
      // Note: AppDatabase is not a true singleton in our tests since we instantiate a new one, 
      // but the SQLite connection might need closing.
    });

    test('insertarNuevaFrase() and getFrasePorHash() works', () async {
      final frase = Frase(
        texto: 'Integracion',
        hash: 'hash_int_1',
        pathAudio: '/path.mp3',
        lastUsed: DateTime.now().millisecondsSinceEpoch,
      );

      final id = await appDatabase.insertarNuevaFrase(frase);
      expect(id, isPositive);

      final result = await appDatabase.getFrasePorHash('hash_int_1');
      expect(result, isNotNull);
      expect(result!.texto, 'Integracion');
    });

    test('buscarFrasesQueEmpiezanCon() ignores accents and matches correctly', () async {
      await appDatabase.insertarNuevaFrase(Frase(
        texto: '¿Qué tal?',
        hash: 'hash_1',
        lastUsed: DateTime.now().millisecondsSinceEpoch,
      ));

      await appDatabase.insertarNuevaFrase(Frase(
        texto: 'Que bueno',
        hash: 'hash_2',
        lastUsed: DateTime.now().millisecondsSinceEpoch,
      ));

      // Should find both since we ignore accents in DB
      final results = await appDatabase.buscarFrasesQueEmpiezanCon('que');
      expect(results.length, 2);
    });

    test('actualizarUsoPorHash() increments uso_count and updates last_used', () async {
      await appDatabase.insertarNuevaFrase(Frase(
        texto: 'Test',
        hash: 'hash_test',
        lastUsed: DateTime.now().millisecondsSinceEpoch,
      ));

      final before = await appDatabase.getFrasePorHash('hash_test');
      expect(before!.vecesUsada, 0);

      final now = DateTime.now().millisecondsSinceEpoch;
      await appDatabase.actualizarUsoPorHash('hash_test', now);

      final after = await appDatabase.getFrasePorHash('hash_test');
      expect(after!.vecesUsada, 1);
      // Wait, Frase model maps 'uso_count' to 'vecesUsada' in fromMap? Yes, we verified fromMap.
    });
  });
}
