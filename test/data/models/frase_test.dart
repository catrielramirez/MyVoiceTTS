import 'package:flutter_test/flutter_test.dart';
import 'package:my_voice/data/models/frase.dart';

void main() {
  group('Frase Model Tests', () {
    final int now = DateTime(2023, 10, 25, 12, 0, 0).millisecondsSinceEpoch;
    
    test('toMap() returns a valid map for SQLite', () {
      final frase = Frase(
        id: 1,
        texto: 'Hola mundo',
        pathAudio: '/path/to/audio.mp3',
        hash: 'abc123hash',
        usoCount: 5,
        lastUsed: now,
      );
      
      final map = frase.toMap();
      
      expect(map['id'], 1);
      expect(map['texto'], 'Hola mundo');
      expect(map['path_audio'], '/path/to/audio.mp3');
      expect(map['hash'], 'abc123hash');
      expect(map['uso_count'], 5);
      expect(map['last_used'], now);
    });

    test('fromMap() creates a valid Frase object from a map', () {
      final map = {
        'id': 2,
        'texto': 'Prueba',
        'path_audio': null,
        'hash': 'def456hash',
        'uso_count': 2,
        'last_used': now,
      };
      
      final frase = Frase.fromMap(map);
      
      expect(frase.id, 2);
      expect(frase.texto, 'Prueba');
      expect(frase.pathAudio, isNull);
      expect(frase.hash, 'def456hash');
      expect(frase.usoCount, 2);
      expect(frase.lastUsed, now);
    });

    test('copyWith() returns a new Frase with updated values', () {
      final original = Frase(
        id: 1,
        texto: 'Original',
        pathAudio: null,
        hash: 'hash',
        lastUsed: now,
      );
      
      final copied = original.copyWith(
        texto: 'Modificado',
        pathAudio: '/nuevo/path.mp3',
        usoCount: 10,
      );
      
      expect(copied.id, original.id);
      expect(copied.texto, 'Modificado');
      expect(copied.pathAudio, '/nuevo/path.mp3');
      expect(copied.hash, original.hash);
      expect(copied.usoCount, 10);
      expect(copied.lastUsed, original.lastUsed);
    });
  });
}
