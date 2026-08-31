import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:my_voice/data/models/frase.dart';

class AppDatabase {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tts_database.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE frases (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            texto TEXT NOT NULL,
            hash TEXT NOT NULL UNIQUE,
            path_audio TEXT,
            uso_count INTEGER NOT NULL DEFAULT 0,
            last_used INTEGER
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_frases_texto ON frases(texto)',
        );

        await db.execute(
          'CREATE INDEX idx_frases_last_used ON frases(last_used)',
        );

        await db.execute(
          'CREATE INDEX idx_frases_hash ON frases(hash)',
        );
      },
    );
  }

  Future<int> insertarNuevaFrase(Frase frase) async {
    final db = await database;
    return db.insert(
      'frases',
      frase.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<Frase?> getFrasePorHash(String hash) async {
    final db = await database;
    final result = await db.query(
      'frases',
      where: 'hash = ?',
      whereArgs: [hash],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Frase.fromMap(result.first);
    }
    return null;
  }

  Future<List<Frase>> buscarFrasesQueEmpiezanCon(String inicio) async {
    final db = await database;

    // Esta variable limpia los acentos de la columna 'texto' en la base de datos
    const sqlTextoSinAcentos = '''
    LOWER(
      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(texto, 
        'á', 'a'), 'é', 'e'), 'í', 'i'), 'ó', 'o'), 'ú', 'u')
    )
  ''';

    final result = await db.query(
      'frases',
      where: '$sqlTextoSinAcentos LIKE ?',
      // IMPORTANTE: .toLowerCase() aquí para que coincida con la DB
      whereArgs: ['${inicio.toLowerCase()}%'],
      orderBy: 'uso_count DESC, last_used DESC',
      limit: 20,
    );

    return result.map((json) => Frase.fromMap(json)).toList();
  }

  /// Trae todas las frases registradas, las más recientes primero.
  /// Útil para la pantalla de historial y el panel de inicio.
  Future<List<Frase>> getAllPhrasesByLastUsed() async {
    final db = await database;
    final result = await db.query(
      'frases',
      orderBy: 'last_used DESC',
    );
    return result.map(Frase.fromMap).toList();
  }

  /// Busca frases que no se han usado desde [thresholdMillis] y que tienen audio físico.
  Future<List<Frase>> getFrasesAntiguas(int thresholdMillis) async {
    final db = await database;
    final result = await db.query(
      'frases',
      where: 'last_used < ? AND path_audio IS NOT NULL',
      whereArgs: [thresholdMillis],
    );
    return result.map(Frase.fromMap).toList();
  }

  /// Actualiza la ruta del audio. Acepta [null] para marcar que el archivo fue borrado.
  Future<void> actualizarAudioPathPorHash(
    String hash,
    String? newPath,
  ) async {
    final db = await database;
    await db.update(
      'frases',
      {
        'path_audio': newPath,
        'last_used': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'hash = ?',
      whereArgs: [hash],
    );
  }

  Future<void> actualizarUsoPorHash(
    String hash,
    int timestamp,
  ) async {
    final db = await database;

    await db.rawUpdate('''
      UPDATE frases
      SET uso_count = uso_count + 1,
          last_used = ?
      WHERE hash = ?
    ''', [timestamp, hash]);
  }

  /// Elimina por completo el registro de una frase de la base de datos.
  Future<int> eliminarFrasePorHash(String hash) async {
    final db = await database;
    return await db.delete(
      'frases',
      where: 'hash = ?',
      whereArgs: [hash],
    );
  }
}
