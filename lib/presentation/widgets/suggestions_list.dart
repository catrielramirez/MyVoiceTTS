import 'package:flutter/material.dart';
import 'package:my_voice/data/models/frase.dart';

/// Lista vertical de sugerencias basadas en la base de datos.
/// Optimizada para pocas sugerencias y texto largo.
class SuggestionsList extends StatelessWidget {
  /// Lista de frases obtenidas por el servicio de búsqueda.
  final List<Frase> suggestions;

  /// Callback cuando el usuario toca una sugerencia.
  final ValueChanged<Frase> onTap;

  const SuggestionsList({
    super.key,
    required this.suggestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Limitamos visualmente la altura para no tapar el input
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 180, // ~3-4 sugerencias cómodas
      ),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final frase = suggestions[index];
          return _SuggestionTile(frase: frase, onTap: () => onTap(frase));
        },
      ),
    );
  }
}

/// Widget individual de sugerencia (vertical, multilinea)
class _SuggestionTile extends StatelessWidget {
  final Frase frase;
  final VoidCallback onTap;

  const _SuggestionTile({required this.frase, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.secondaryContainer.withOpacity(0.75),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            frase.texto,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
