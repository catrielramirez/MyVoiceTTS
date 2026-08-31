import 'package:flutter/material.dart';
import 'package:my_voice/logic/services/audio_player_manager.dart';

class AudioControlWidget extends StatefulWidget {
  final PlaybackState state;
  final VoidCallback
      onStopPressed; // Detiene la reproducción o cancela la carga

  const AudioControlWidget({
    super.key,
    required this.state,
    required this.onStopPressed,
  });

  @override
  State<AudioControlWidget> createState() => _AudioControlWidgetState();
}

class _AudioControlWidgetState extends State<AudioControlWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _pressController;
  late Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _pressAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    await _pressController.forward();
    await _pressController.reverse();
    widget.onStopPressed();
  }

  @override
  Widget build(BuildContext context) {
    // Si no está activo, el AnimatedSwitcher del Home se encarga de ocultarlo
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLiquidPill(),
      ],
    );
  }

  Widget _buildLiquidPill() {
    final isPlaying = widget.state == PlaybackState.playing;
    final baseColor =
        isPlaying ? const Color(0xFF007AFF) : const Color(0xFFFF9500);
    final text = isPlaying ? "Reproduciendo" : "Generando...";
    final subText = isPlaying ? "Tocar para detener" : "Tocar para cancelar";

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _pressAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pressAnimation.value,
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withOpacity(0.3),
                    blurRadius: 15 * _pulseAnimation.value,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPlaying)
                    _AnimatedWave(color: Colors.white)
                  else
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  const SizedBox(width: 14),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        subText,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.stop_circle_rounded,
                      color: Colors.white, size: 26),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedWave extends StatefulWidget {
  final Color color;
  const _AnimatedWave({required this.color});

  @override
  State<_AnimatedWave> createState() => _AnimatedWaveState();
}

class _AnimatedWaveState extends State<_AnimatedWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (i) => _bar(i * 0.2)),
      ),
    );
  }

  Widget _bar(double delay) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = (_controller.value + delay) % 1.0;
        final height = 6.0 + (value * 10.0);
        return Container(
          width: 3,
          height: height,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
