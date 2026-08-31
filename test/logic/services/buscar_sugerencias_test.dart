import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_voice/data/models/frase.dart';
import 'package:my_voice/logic/services/buscar_sugerencias.dart';

import '../../mock_classes.dart';

void main() {
  group('BuscarSugerencias Tests', () {
    late BuscarSugerencias service;
    late MockIFraseRepository mockRepository;

    setUp(() {
      mockRepository = MockIFraseRepository();
      service = BuscarSugerencias(mockRepository);
    });

    test('buscar() returns empty list if query is less than 2 chars', () async {
      final result1 = await service.buscar('');
      final result2 = await service.buscar('a');

      expect(result1, isEmpty);
      expect(result2, isEmpty);
      verifyNever(() => mockRepository.buscarPorTexto(any()));
    });

    test('buscar() calls repository and maps to Frase objects', () async {
      final frase = Frase(
        id: 1,
        texto: 'Hola mundo',
        hash: 'hash_hola',
        lastUsed: DateTime.now().millisecondsSinceEpoch,
      );

      when(() => mockRepository.buscarPorTexto('hola')).thenAnswer((_) async => [frase]);

      final results = await service.buscar('hola');

      expect(results.length, 1);
      expect(results.first.texto, 'Hola mundo');
      verify(() => mockRepository.buscarPorTexto('hola')).called(1);
    });

    test('obtenerFrecuentes() delegates to repository with default limit', () async {
      when(() => mockRepository.obtenerMasUsadas(limite: 5)).thenAnswer((_) async => []);

      await service.obtenerFrecuentes();

      verify(() => mockRepository.obtenerMasUsadas(limite: 5)).called(1);
    });
  });
}
