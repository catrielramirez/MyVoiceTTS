import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart'; 
import 'package:my_voice/data/models/frase.dart';
import 'package:my_voice/logic/services/phrases_manager_service.dart';

class HistoryScreen extends StatefulWidget {
  final PhrasesManagerService phrasesManagerService;
  final Function(Frase) onPhraseSelected;

  const HistoryScreen({
    super.key,
    required this.phrasesManagerService,
    required this.onPhraseSelected,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Frase> _allPhrases = [];
  final Set<String> _selectedHashes = {};
  bool _isEditMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final phrases =
        await widget.phrasesManagerService.getAllPhrasesByLastUsed();
    if (mounted) {
      setState(() {
        _allPhrases = phrases;
        _isLoading = false;
      });
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) _selectedHashes.clear();
    });
  }

  Future<void> _deleteSelected() async {
    final phrasesToDelete =
        _allPhrases.where((p) => _selectedHashes.contains(p.hash)).toList();

    for (final phrase in phrasesToDelete) {
      await widget.phrasesManagerService.deletePhrase(phrase);
    }
    _selectedHashes.clear();
    _isEditMode = false;
    await _loadHistory();
  }

  // --- FUNCIÓN DE COMPARTIR ---
  void _sharePhrase(String text) {
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color.fromARGB(221, 105, 68, 180);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Historial Completo",
          style: TextStyle(
            color: brandColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.shade100,
            height: 1,
          ),
        ),
        actions: [
          if (_allPhrases.isNotEmpty)
            TextButton(
              onPressed: _toggleEditMode,
              child: Text(
                _isEditMode ? 'Listo' : 'Editar',
                style: TextStyle(
                  color: _isEditMode ? brandColor : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (_isEditMode)
            IconButton(
              onPressed: _selectedHashes.isEmpty ? null : _deleteSelected,
              icon: Icon(
                Icons.delete_outline,
                color:
                    _selectedHashes.isEmpty ? Colors.grey.shade300 : Colors.red,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: brandColor),
            )
          : _allPhrases.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history,
                          size: 64, color: Colors.grey.shade200),
                      const SizedBox(height: 16),
                      Text(
                        "No hay historial aún",
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: _allPhrases.length,
                  itemBuilder: (context, index) {
                    final phrase = _allPhrases[index];
                    final isSelected = _selectedHashes.contains(phrase.hash);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.withOpacity(0.08)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue.withOpacity(0.3)
                                : Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.only(
                              left: 16, right: 8, top: 4, bottom: 4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          selected: isSelected,
                          title: Text(
                            phrase.texto,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.3,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? Colors.blue.shade900
                                  : Colors.black87,
                            ),
                          ),
                          leading: _isEditMode
                              ? Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey.shade400,
                                  size: 24,
                                )
                              : Icon(
                                  Icons.history,
                                  size: 20,
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey.shade400,
                                ),
                          // --- BOTÓN DE COMPARTIR A LA DERECHA ---
                          trailing: !_isEditMode 
                            ? IconButton(
                                icon: Icon(Icons.share_rounded, 
                                      color: Colors.grey.shade400, size: 20),
                                onPressed: () => _sharePhrase(phrase.texto),
                              )
                            : null,
                          onTap: () {
                            if (_isEditMode) {
                              setState(() {
                                isSelected
                                    ? _selectedHashes.remove(phrase.hash)
                                    : _selectedHashes.add(phrase.hash);
                              });
                            } else {
                              widget.onPhraseSelected(phrase);
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}