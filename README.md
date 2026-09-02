# My Voice TTS

Aplicación móvil desarrollada en Flutter para la conversión de texto a voz (Text-to-Speech) mediante la API avanzada de ElevenLabs, optimizada con una capa de almacenamiento en caché local (SQLite y archivos físicos) para reducir latencias, recursos y costos de API. 

## Arquitectura de la aplicación

El proyecto implementa una **Clean Architecture** dividida en tres capas principales ubicadas en `lib/`:

* **Capa de Presentación (`lib/presentation/`)**: Gestiona la interfaz de usuario mediante `HomeScreen` (entrada de texto, sugerencias y controles de reproducción con panel deslizante `PhrasesPanel`), `HistoryScreen` (visualización y búsqueda de historial) y widgets modulares reutilizables.
* **Capa Lógica / Casos de Uso (`lib/logic/`)**:
  * `PhraseAudioService`: Orquestador principal que gestiona la lógica de hashing SHA-256, verificación de caché (Hit/Miss) y rutinas de mantenimiento.
  * `AudioPlayerManager`: Envoltorio sobre `just_audio` para el manejo de reproducción de archivos físicos y bytes (`ConcatenatingAudioSource` para reproducción gapless).
  * `PhrasesManagerService` y `BuscarSugerencias`: Servicios para la consulta de historiales, ordenamientos y búsqueda rápida predictiva basada en uso.
  * `AnalyticsService`: Registro de métricas locales en `SharedPreferences` (tiempo ahorrado, impactos de caché y créditos ahorrados de ElevenLabs).
* **Capa de Datos (`lib/data/`)**:
  * `AppDatabase`: Gestor SQLite con tablas indexadas y soporte para búsquedas ignorando acentos.
  * `AudioStorage`: Gestión del sistema de archivos local mediante `path_provider` para la persistencia de archivos `.mp3`.
  * `TtsService`: Cliente HTTP para la comunicación con Supabase Edge Functions y ElevenLabs, gestionando la autenticación mediante `.env`.
  * `Frase`: Entidad de modelo que representa los registros con metadatos, rutas de audio, fechas, conteo de usos (`uso_count`, `last_used`) y Hash SHA-256.

## Flujo principal de datos (Generación de audio)
![Diagrama de Flujo de Datos](assets/images/my_voice_diagram.png)

1. **Input**: El usuario introduce texto libre en la interfaz o selecciona una frase existente desde el panel de sugerencias predictivas.
2. **Normalización y Hashing**: 
   * Si se selecciona una **sugerencia existente**, se reutilizan directamente el hash y la ruta guardados sin recalcular, generando un impacto de caché (*Cache HIT*) instantáneo.
   * Si es **texto nuevo**, se normaliza el texto y se calcula un Hash SHA-256 único.
3. **Consulta de Caché**: `PhraseAudioService` verifica en `AppDatabase` la existencia del hash y su ruta de audio.
4. **Bifurcación**:
   * **Cache HIT**: Si el registro y el archivo físico `.mp3` existen localmente, se devuelve la ruta local y se actualizan los metadatos (`uso_count` y `last_used`).
   * **Cache MISS**: Si no existen (o el archivo físico fue borrado del disco), se solicita el audio a `TtsService`, se guarda el archivo en disco con `AudioStorage` y se persiste un nuevo registro en `AppDatabase`.
5. **Reproducción**: `AudioPlayerManager` encola la ruta local en una `ConcatenatingAudioSource` para su reproducción fluida (*gapless*).

## Requisitos y configuración

1. SDK de Flutter instalado.
2. **Cliente (Flutter)**: Crear un archivo `.env` en la raíz basado en el archivo de ejemplo, estableciendo las credenciales públicas de Supabase (`SUPABASE_URL` y `SUPABASE_ANON_KEY`).
3. **Servidor (Supabase Edge Functions)**: Desplegar la función proxy correspondiente y configurar de forma segura la clave secreta `ELEVENLABS_API_KEY` en los secretos del proyecto de Supabase.

## Instalación y ejecución

```bash
# Clonar el repositorio
git clone <url-del-repositorio>

# Instalar dependencias
flutter pub get

# Ejecutar la aplicación
flutter run

``` 
## Funcionalidades y roadmap

### Características de la versión actual
* **Gestión de frases**: Administración y control del historial por parte del usuario.
* **Panel de frases recomendadas**: Sugerencia basada en el historial y acceso rápido a frases frecuentes mientras el usuario escribe.
* **Limpieza automática de caché**: Rutinas de mantenimiento que depuran archivos antiguos cada 30 días para optimizar el almacenamiento.
* **Panel de últimas frases**: Acceso rápido, visualización y eliminación de las frases utilizadas recientemente.

### Futuras mejoras y escalabilidad
* Funcionalidad para compartir archivos de audio.
* Respaldo y sincronización de datos en la nube.
* Ejecución de modelos de síntesis de voz *on-device*.
