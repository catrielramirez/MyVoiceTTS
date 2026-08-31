import 'package:flutter/material.dart';
import 'package:my_voice/data/models/frase.dart';
import 'dart:ui';
import 'package:share_plus/share_plus.dart'; 

class PhrasesPanel extends StatefulWidget {
  final List<Frase> phrases;
  final Function(Frase) onPhraseSelected;
  final Function(Frase) onPhraseDeleted;
  final VoidCallback onRefresh;
  final ScrollController scrollController;

  const PhrasesPanel({
    super.key,
    required this.phrases,
    required this.onPhraseSelected,
    required this.onPhraseDeleted,
    required this.onRefresh,
    required this.scrollController,
  });

  @override
  State<PhrasesPanel> createState() => _PhrasesPanelState();
}

class _PhrasesPanelState extends State<PhrasesPanel> {
  final Set<String> _selectedHashes = {};
  bool _isEditMode = false;

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) _selectedHashes.clear();
    });
  }

  void _handleTap(Frase frase) {
    if (_isEditMode) {
      setState(() {
        _selectedHashes.contains(frase.hash)
            ? _selectedHashes.remove(frase.hash)
            : _selectedHashes.add(frase.hash);
      });
    } else {
      widget.onPhraseSelected(frase);
    }
  }

  void _handleLongPress(Frase frase) {
    if (!_isEditMode) {
      setState(() {
        _isEditMode = true;
        _selectedHashes.add(frase.hash);
      });
    }
  }

  // Compartir Audio ---
  Future<void> _shareAudio(Frase frase) async {
    if (frase.pathAudio == null) return;

    try {
      await Share.shareXFiles(
        [XFile(frase.pathAudio!)],
        text: 'Escucha lo que dije con My Voice: "${frase.texto}"',
      );
    } catch (e) {
      debugPrint("Error al compartir: $e");
      // Opcional: Mostrar un SnackBar indicando que el archivo no se encontró
    }
  }

  Future<void> _deleteSelected() async {
    final phrasesToDelete =
        widget.phrases.where((p) => _selectedHashes.contains(p.hash)).toList();

    for (final phrase in phrasesToDelete) {
      await widget.onPhraseDeleted(phrase);
    }

    setState(() {
      _selectedHashes.clear();
      _isEditMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: CustomScrollView(
            controller: widget.scrollController,
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  minHeight: 90,
                  maxHeight: 90,
                  child: _buildHeaderContent(),
                ),
              ),
              if (widget.phrases.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Text(
                        "No hay frases recientes",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(top: 10, bottom: 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final phrase = widget.phrases[index];
                        final isSelected =
                            _selectedHashes.contains(phrase.hash);

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue.withOpacity(0.1)
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
                              visualDensity: const VisualDensity(vertical: -3),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              selected: isSelected,
                              title: Text(
                                phrase.texto,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
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
                                          : Colors.grey,
                                      size: 22,
                                    )
                                  : Icon(
                                      Icons.history,
                                      size: 18,
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.grey.shade400,
                                    ),
                              // --- BOTÓN DE COMPARTIR A LA DERECHA ---
                              trailing:
                                  (!_isEditMode && phrase.pathAudio != null)
                                      ? IconButton(
                                          icon: Icon(
                                            Icons
                                                .ios_share_rounded, // Icono de compartir
                                            size: 20,
                                            color: Colors.grey.shade600,
                                          ),
                                          onPressed: () => _shareAudio(phrase),
                                          tooltip: 'Compartir audio',
                                        )
                                      : null,
                              onTap: () => _handleTap(phrase),
                              onLongPress: () => _handleLongPress(phrase),
                            ),
                          ),
                        );
                      },
                      childCount: widget.phrases.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mis últimas frases',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(221, 105, 68, 180),
                  ),
                ),
                if (_isEditMode)
                  Row(
                    children: [
                      TextButton(
                        onPressed: _toggleEditMode,
                        child: const Text('Cancelar'),
                      ),
                      IconButton(
                        onPressed:
                            _selectedHashes.isEmpty ? null : _deleteSelected,
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                      ),
                    ],
                  )
                else
                // Botón para entrar en modo edición si hay frases
                if (widget.phrases.isNotEmpty)
                  IconButton(
                    onPressed: _toggleEditMode,
                    icon:
                        const Icon(Icons.edit_note_rounded, color: Colors.grey),
                    tooltip: 'Gestionar frases',
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
