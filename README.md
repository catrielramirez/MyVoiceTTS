1. TtsService
Archivo: logic/tts_service.dart
Responsabilidad:
Comunicación HTTP directa con la API externa de ElevenLabs para generar audio a partir de texto.

Qué hace:

Valida entrada y configuración (texto y API Key).

Construye y ejecuta la request HTTP.

Devuelve bytes de audio (Uint8List) en formato MPEG.

Traduce errores técnicos a excepciones de dominio (TtsApiException).

Dependencias:

http.Client

flutter_dotenv

logging

Métodos públicos:

Future<Uint8List> generateAudio(String text)

Genera audio a partir de texto.

Lanza TtsApiException en caso de error.

Manejo de errores:

Texto vacío

API Key no configurada

Error HTTP (status ≠ 200)

Sin conexión a internet (SocketException)

Error desconocido de la API

2. TtsServiceInterface

Archivo: logic/tts_service_interface.dart
Responsabilidad:
Contrato abstracto para servicios de generación de audio TTS.

Qué hace:

Define el comportamiento esperado de cualquier implementación TTS.

Permite desacoplar la app de proveedores concretos (ElevenLabs, otro futuro).

Métodos:

Future<Uint8List> generateAudio(String text)

3. TtsApiException

Archivo: core/tts_exception.dart
Responsabilidad:
Representar errores de dominio relacionados con TTS.

Qué hace:

Unifica el tipo de error que el resto de la app puede capturar.

Evita propagar excepciones técnicas (SocketException, ClientException, etc.).

4. PhraseAudioService

Archivo: logic/phrase_audio_service.dart
Responsabilidad:
Orquestar el flujo completo de obtención de audio para una frase.

Flujo completo:

DB → Storage → TTS → Storage → DB


Qué hace:

Normaliza el texto.

Genera un hash determinístico.

Busca audio existente en DB y storage.

Genera audio nuevo si no existe.

Persiste audio y metadatos.

Actualiza métricas de uso.

Dependencias (inyectadas):

IFraseRepository

TtsServiceInterface

AudioStorage

Utils

Métodos públicos:

Future<Frase> generateAndStorePhrase(String text)

Devuelve una Frase con audio disponible.

Nunca devuelve null.

Propaga excepciones del TTS.

void clearMemoryCache()

Limpia cache de audio en memoria.

5. IFraseRepository

Archivo: logic/IFraseRepository.dart
Responsabilidad:
Acceso abstracto a persistencia de frases (DB).

Qué hace:

Encapsula operaciones CRUD relacionadas con frases.

Aísla la lógica de negocio del motor de base de datos.

Métodos utilizados:

getFrasePorHash(String hash)

insertFrase(Frase frase)

updateFrasePathAudioPorHash(String hash, String path)

actualizarUsoFrasePorHash(String hash)

6. AudioStorage

Archivo: data/sources/audio_storage.dart
Responsabilidad:
Persistencia física y cacheo de audio.

Qué hace:

Guarda audio en disco.

Recupera audio existente.

Mantiene cache en memoria para acceso rápido.

Métodos utilizados:

Future<Uint8List?> getAudio(String hash)

Future<String> saveAudio(String hash, Uint8List bytes)

void clearCache()

7. Utils

Archivo: core/utils.dart
Responsabilidad:
Funciones utilitarias puras.

Qué hace:

Normalización de texto.

Generación de hashes determinísticos.

Métodos utilizados:

String normalizeText(String text)

String generateHash(String text)

8. Frase

Archivo: data/models/frase.dart
Responsabilidad:
Modelo de dominio de una frase con audio.

Campos relevantes:

id

texto

hash

pathAudio

usoCount

lastUsed

Métodos importantes:

copyWith(...)