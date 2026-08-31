import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  final String supabaseUrl;
  final String supabaseAnonKey;

  AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  // Un constructor factory no crea obligatoriamente una nueva instancia
  // puede devolver una existente
  // permite Ejecutar lógica antes de crear el objeto, Llamar a otros constructores
  // Validar datos
  // Constructor normal → solo inicializa campos
  // factory → decide cómo obtener la instancia
  factory AppConfig.fromEnv() {
    return AppConfig(
      supabaseUrl: dotenv.env['SUPABASE_URL'] ?? '',
      supabaseAnonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  }
}
