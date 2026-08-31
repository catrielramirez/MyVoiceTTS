import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:my_voice/data/sources/database.dart';
import 'package:my_voice/data/sources/audio_storage.dart';
import 'package:my_voice/logic/services/audio_player_manager.dart';
import 'package:my_voice/logic/services/phrase_audio_service.dart';
import 'package:my_voice/logic/services/phrases_manager_service.dart';
import 'package:my_voice/logic/services/buscar_sugerencias.dart';
import 'package:my_voice/data/sources/tts_service.dart';
import 'package:my_voice/core/app_config.dart';
import 'package:my_voice/presentation/screens/home_screen.dart';

void main() async {
  // Asegurar la comunicación con el motor de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Configuración de Logs para depuración
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint(
      '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
    );
  });

  // Carga de variables de entorno (.env)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("⚠️ ERROR: No se pudo cargar el archivo .env: $e");
  }

  // Inicialización de la configuración y servicios core
  final config = AppConfig.fromEnv();
  final database = AppDatabase();
  final audioStorage = AudioStorage();
  final audioManager = AudioPlayerManager();

  // Inicialización de servicios de lógica de negocio
  final ttsService = TtsService(
    baseUrl: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
  );

  final phraseAudioService = PhraseAudioService(
    database: database,
    storage: audioStorage,
    ttsService: ttsService,
  );

  final phrasesManagerService = PhrasesManagerService(
    database: database,
    storage: audioStorage,
  );

  final buscarSugerencias = BuscarSugerencias(database: database);

  // Mantenimiento automático de archivos de audio (segundo plano)
  // Elimina audios que no se han usado en más de 30 días para ahorrar espacio
  phraseAudioService.performMaintenance(daysThreshold: 30);

  runApp(MyApp(
    buscarSugerencias: buscarSugerencias,
    phraseAudioService: phraseAudioService,
    audioManager: audioManager,
    phrasesManagerService: phrasesManagerService,
  ));
}

class MyApp extends StatelessWidget {
  final BuscarSugerencias buscarSugerencias;
  final PhraseAudioService phraseAudioService;
  final AudioPlayerManager audioManager;
  final PhrasesManagerService phrasesManagerService;

  const MyApp({
    super.key,
    required this.buscarSugerencias,
    required this.phraseAudioService,
    required this.audioManager,
    required this.phrasesManagerService,
  });

  @override
  Widget build(BuildContext context) {
    // Definimos el color violeta como marca principal para toda la app
    const brandColor = Color(0xFF6744B4);

    return MaterialApp(
      title: 'My Voice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // ColorScheme basado en el violeta de tus métricas e historial
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandColor,
          primary: brandColor,
        ),
        useMaterial3: true,
        // Configuración global para que los diálogos y botones se vean consistentes
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: HomeScreen(
        buscarSugerencias: buscarSugerencias,
        phraseAudioService: phraseAudioService,
        audioPlayerManager: audioManager,
        phrasesManagerService: phrasesManagerService,
      ),
    );
  }
}