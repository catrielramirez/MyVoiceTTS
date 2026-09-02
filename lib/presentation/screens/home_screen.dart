import 'package:flutter/material.dart';
import 'package:my_voice/data/models/frase.dart';
import 'package:my_voice/logic/services/audio_player_manager.dart';
import 'package:my_voice/logic/services/phrase_audio_service.dart';
import 'package:my_voice/logic/services/phrases_manager_service.dart';
import 'package:my_voice/logic/services/buscar_sugerencias.dart';
import 'package:my_voice/logic/services/analytics_service.dart';
import 'package:my_voice/presentation/widgets/audio_control_widget.dart';
import 'package:my_voice/presentation/widgets/fancy_text_input.dart';
import 'package:my_voice/presentation/widgets/suggestions_list.dart';
import 'package:my_voice/presentation/widgets/phrases_panel.dart';
import 'package:my_voice/presentation/screens/history_screen.dart';

class HomeScreen extends StatefulWidget {
  final BuscarSugerencias buscarSugerencias;
  final PhraseAudioService phraseAudioService;
  final AudioPlayerManager audioPlayerManager;
  final PhrasesManagerService phrasesManagerService;

  const HomeScreen({
    super.key,
    required this.buscarSugerencias,
    required this.phraseAudioService,
    required this.audioPlayerManager,
    required this.phrasesManagerService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();

  List<Frase> _currentSuggestions = [];
  List<Frase> _recentPhrases = [];

  bool _isProcessing = false;
  int _suggestionQueryId = 0;
  int _processToken = 0;

  @override
  void initState() {
    super.initState();
    widget.audioPlayerManager.addListener(_onAudioStateChanged);
    _loadRecentPhrases();
  }

  @override
  void dispose() {
    widget.audioPlayerManager.removeListener(_onAudioStateChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onAudioStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadRecentPhrases() async {
    final phrases = await widget.phrasesManagerService.getLastPhrases(3);
    if (mounted) {
      setState(() => _recentPhrases = phrases);
    }
  }

  // --- PANEL DE MÉTRICAS (REINICIO SIN CIERRE) ---
  void _showAnalytics() async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return FutureBuilder<Map<String, dynamic>>(
            future: AnalyticsService().getStats(),
            builder: (context, snapshot) {
              final stats = snapshot.data ?? {
                'hits': 0, 'misses': 0, 'creditsSaved': 0.0, 
                'creditsSpent': 0.0, 'apiTimeAvg': 0.0, 'cacheTimeAvg': 0.0
              };

              final int hits = stats['hits'];
              final int misses = stats['misses'];
              final double creditsSaved = stats['creditsSaved'];
              final double creditsSpent = stats['creditsSpent'];
              final double total = creditsSaved + creditsSpent;
              final double efficiency = total > 0 ? (creditsSaved / total) * 100 : 0.0;
              final double hitRatio = (hits + misses) > 0 ? (hits / (hits + misses)) * 100 : 0.0;

              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                titlePadding: EdgeInsets.zero,
                title: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6744B4), Color(0xFF8E78D1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.analytics_rounded, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text('Dashboard de IA',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22)),
                    ],
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    _buildModernStatCard(
                        'Eficiencia Operativa',
                        '${efficiency.toStringAsFixed(1)}%',
                        Icons.bolt_rounded,
                        Colors.orange),
                    _buildModernStatCard(
                        'Cache Hit Ratio',
                        '${hitRatio.toStringAsFixed(1)}%',
                        Icons.memory_rounded,
                        Colors.blue),
                    const SizedBox(height: 16),
                    const Divider(),
                    _buildMetricRow(
                        'Créditos Ahorrados', creditsSaved.toStringAsFixed(5),
                        isSuccess: true),
                    _buildMetricRow(
                        'Créditos Consumidos', creditsSpent.toStringAsFixed(5)),
                    _buildMetricRow(
                        'Latencia API', '${stats['apiTimeAvg'].toStringAsFixed(0)}ms'),
                    _buildMetricRow('Latencia Local',
                        '${stats['cacheTimeAvg'].toStringAsFixed(0)}ms'),
                    const SizedBox(height: 24),

                    // BOTÓN REINICIAR (Ahora no cierra el diálogo)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          await AnalyticsService().resetMetrics();
                          // Actualizamos el estado interno del diálogo para refrescar los ceros
                          setDialogState(() {});
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Métricas reiniciadas'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 1),
                            ));
                          }
                        },
                        icon: const Icon(Icons.refresh_rounded, color: Colors.redAccent),
                        label: const Text('REINICIAR MÉTRICAS',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1)),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildModernStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {bool isSuccess = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSuccess ? Colors.green.shade700 : Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryScreen(
          phrasesManagerService: widget.phrasesManagerService,
          onPhraseSelected: (frase) => _processFromFrase(frase),
        ),
      ),
    );
    _loadRecentPhrases();
  }

  void _onTextChanged(String value) async {
    final queryId = ++_suggestionQueryId;
    if (value.isEmpty) {
      setState(() => _currentSuggestions = []);
      return;
    }
    final suggestions = await widget.buscarSugerencias.getSugerencias(value);
    if (!mounted || queryId != _suggestionQueryId) return;
    setState(() => _currentSuggestions = suggestions);
  }

  void _onSuggestionTap(Frase frase) {
    _processFromFrase(frase);
    _textController.clear();
    setState(() => _currentSuggestions = []);
  }

  void _onPhrasePanelSelected(Frase frase) => _processFromFrase(frase);

  Future<void> _onPhraseDeleted(Frase frase) async {
    final success = await widget.phrasesManagerService.deletePhrase(frase);
    if (success && mounted) await _loadRecentPhrases();
  }

  void _handleOnSubmitted() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _processText(text);
    _textController.clear();
    setState(() => _currentSuggestions = []);
  }

  Future<void> _processText(String text) async {
    if (_isProcessing) return;
    final token = ++_processToken;
    setState(() => _isProcessing = true);
    try {
      final audioPath =
          await widget.phraseAudioService.getAudioPathForText(text);
      if (!mounted || token != _processToken) return;
      if (audioPath != null) {
        widget.audioPlayerManager.enqueueAudio(audioPath);
        await widget.phrasesManagerService.updatePhraseUsage(text);
        await _loadRecentPhrases();
      }
    } finally {
      if (mounted && token == _processToken) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Fast path para frases que ya existen en la BD.
  /// Evita normalizar, hashear y consultar la BD de nuevo.
  Future<void> _processFromFrase(Frase frase) async {
    if (_isProcessing) return;
    final token = ++_processToken;
    setState(() => _isProcessing = true);
    try {
      final audioPath =
          await widget.phraseAudioService.getAudioPathForFrase(frase);
      if (!mounted || token != _processToken) return;
      if (audioPath != null) {
        widget.audioPlayerManager.enqueueAudio(audioPath);
        await _loadRecentPhrases();
      }
    } finally {
      if (mounted && token == _processToken) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Colors.grey.shade50;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final bool isPlaying =
        widget.audioPlayerManager.state != PlaybackState.stopped &&
            widget.audioPlayerManager.state != PlaybackState.idle;

    return Scaffold(
      backgroundColor: scaffoldBg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.history_edu_rounded,
              color: Color.fromARGB(221, 102, 82, 167)),
          tooltip: 'Historial completo',
          onPressed: _openHistory,
        ),
        title: const Text(
          "My Voice",
          style: TextStyle(
              color: Color.fromARGB(221, 100, 65, 187),
              fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_rounded,
                color: Color.fromARGB(221, 102, 82, 167)),
            tooltip: 'Métricas',
            onPressed: _showAnalytics,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.elasticOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      ),
                      child: isPlaying
                          ? AudioControlWidget(
                              state: widget.audioPlayerManager.state,
                              onStopPressed: () {
                                _processToken++;
                                widget.audioPlayerManager.stopAndClearQueue();
                                setState(() => _isProcessing = false);
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
                if (_currentSuggestions.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: SuggestionsList(
                      suggestions: _currentSuggestions,
                      onTap: _onSuggestionTap,
                    ),
                  ),
                const SizedBox(height: 12),
                Padding(
                  padding:
                      EdgeInsets.fromLTRB(20, 0, 20, isKeyboardOpen ? 12 : 110),
                  child: FancyTextInput(
                    controller: _textController,
                    onChanged: _onTextChanged,
                    onSubmitted: _handleOnSubmitted,
                    isProcessing: _isProcessing,
                    onClear: () {
                      _textController.clear();
                      _onTextChanged('');
                    },
                    onCancel: () {
                      _processToken++;
                      setState(() => _isProcessing = false);
                    },
                  ),
                ),
              ],
            ),
          ),
          if (!isKeyboardOpen)
            DraggableScrollableSheet(
              initialChildSize: 0.08,
              minChildSize: 0.08,
              maxChildSize: 0.40,
              snap: true,
              builder: (context, scrollController) {
                return PhrasesPanel(
                  phrases: _recentPhrases,
                  onPhraseSelected: _onPhrasePanelSelected,
                  onPhraseDeleted: _onPhraseDeleted,
                  onRefresh: _loadRecentPhrases,
                  scrollController: scrollController,
                );
              },
            ),
        ],
      ),
    );
  }
}