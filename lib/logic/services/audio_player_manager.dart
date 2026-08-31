import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';

/// Enum que representa los estados del reproductor.
enum PlaybackState { idle, loading, playing, paused, stopped, error }

/// Singleton para la gestión de la reproducción de la voz de forma fluida.
class AudioPlayerManager with ChangeNotifier {
  static final Logger _logger = Logger('AudioPlayerManager');

  // --- Singleton Pattern ---
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  factory AudioPlayerManager() => _instance;

  // Usamos ConcatenatingAudioSource para reproducción fluida (Gapless)
  late ConcatenatingAudioSource _playlist;

  AudioPlayerManager._internal({AudioPlayer? player})
      : _player = player ?? AudioPlayer() {
    _initAudioPlayer();
  }

  // --- Propiedades Internas ---
  final AudioPlayer _player;

  PlaybackState _currentState = PlaybackState.idle;
  PlaybackState get state => _currentState;

  /// Inicializa el reproductor y la lista de reproducción.
  Future<void> _initAudioPlayer() async {
    // Inicializamos la playlist vacía
    _playlist = ConcatenatingAudioSource(
      children: [],
      useLazyPreparation: true,
    );

    // Asignamos la playlist al reproductor una única vez.
    // Esto permite agregar audios dinámicamente sin detener la reproducción.
    try {
      await _player.setAudioSource(_playlist);
    } catch (e) {
      _logger.severe("Error inicializando la fuente de audio: $e");
    }

    // Escuchamos los estados del reproductor
    _player.playerStateStream.listen((playerState) {
      final processingState = playerState.processingState;

      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        _emitState(PlaybackState.loading);
      } else if (playerState.playing &&
          processingState == ProcessingState.ready) {
        _emitState(PlaybackState.playing);
      } else if (processingState == ProcessingState.completed) {
        // Cuando termina TODA la lista de reproducción
        _handlePlaylistCompleted();
      } else if (processingState == ProcessingState.idle) {
        _emitState(PlaybackState.stopped);
      } else {
        // Pausado o listo pero no sonando
        if (_playlist.length > 0 && !playerState.playing) {
          _emitState(PlaybackState.paused);
        } else {
          _emitState(PlaybackState.stopped);
        }
      }
    });
  }

  /// Maneja el fin de la lista de reproducción
  void _handlePlaylistCompleted() {
    _emitState(PlaybackState.stopped);
    // Limpiamos la playlist para que la próxima vez empiece de 0 limpio.
    // Esto actúa como tu antigua lógica de vaciar la cola.
    _playlist.clear();
    _player.stop();
    _player.seek(Duration.zero, index: 0);
  }

  // --- Métodos de Control ---

  /// Encola un audio de forma fluida.
  /// No detiene la reproducción actual.
  Future<void> enqueueAudio(String audioPath) async {
    if (audioPath.isEmpty) return;

    if (!File(audioPath).existsSync()) {
      _logger.warning("El archivo no existe: $audioPath");
      return;
    }

    try {
      // 1. Creamos la fuente de audio
      final audioSource = AudioSource.file(audioPath);

      // 2. Lo agregamos a la playlist "en vivo".
      // just_audio maneja esto internamente sin cortar el audio actual.
      await _playlist.add(audioSource);

      _logger.info('Audio agregado. Total en cola: ${_playlist.length}');

      // 3. Si no está reproduciendo, le damos play.
      if (!_player.playing) {
        // Si el estado anterior era completado, aseguramos reinicio
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero, index: 0);
        }
        _player.play();
      }
    } catch (e) {
      _logger.severe("Error al encolar audio: $e");
      _emitState(PlaybackState.error);
    }
  }

  Future<void> pause() async {
    if (_player.playing) {
      await _player.pause();
    }
  }

  /// Detiene todo y borra la cola (Botón Stop).
  Future<void> stopAndClearQueue() async {
    _logger.info('Deteniendo reproducción y limpiando playlist.');

    // Es importante el orden: primero stop para liberar recursos, luego limpiar
    await _player.stop();
    await _playlist.clear();

    _emitState(PlaybackState.stopped);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // --- Lógica Privada ---

  void _emitState(PlaybackState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      notifyListeners();
    }
  }
}
