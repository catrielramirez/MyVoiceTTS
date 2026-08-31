import 'package:flutter/material.dart';

class FancyTextInput extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback onClear;
  final VoidCallback? onCancel;
  final bool isProcessing;
  final String hintText;

  const FancyTextInput({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    this.onCancel,
    this.isProcessing = false,
    this.hintText = 'Escribe una frase...',
  });

  @override
  State<FancyTextInput> createState() => _FancyTextInputState();
}

class _FancyTextInputState extends State<FancyTextInput> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() => _isFocused = _focusNode.hasFocus);

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: _isFocused ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(32.0),
        border: Border.all(
          color: widget.isProcessing
              ? Colors.orangeAccent
              : (_isFocused ? primaryColor : primaryColor.withOpacity(0.3)),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isFocused ? 0.12 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 12.0, right: 6.0),
      child: Row(
        children: [
          Icon(
            widget.isProcessing ? Icons.auto_awesome : Icons.keyboard_outlined,
            color: widget.isProcessing
                ? Colors.orangeAccent
                : (_isFocused ? primaryColor : Colors.grey.shade400),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              onSubmitted: (_) =>
                  widget.isProcessing ? null : widget.onSubmitted(),
              textInputAction: TextInputAction.send,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
              decoration: InputDecoration(
                hintText:
                    widget.isProcessing ? 'Procesando...' : widget.hintText,
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey.shade400),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          _buildActionGroup(primaryColor),
        ],
      ),
    );
  }

  Widget _buildActionGroup(Color primaryColor) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, child) {
        final bool hasText = value.text.isNotEmpty;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasText && !widget.isProcessing)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.cancel, color: Colors.grey.shade400, size: 20),
                onPressed: widget.onClear,
              ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: widget.isProcessing
                  ? IconButton(
                      key: const ValueKey('cancel'),
                      icon: const Icon(Icons.stop_circle,
                          color: Colors.redAccent, size: 32),
                      onPressed: widget.onCancel,
                    )
                  : Padding(
                      key: const ValueKey('send'),
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        // Tamaño del círculo reducido
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: hasText ? primaryColor : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          // Padding en cero para que el icono se centre en el círculo pequeño
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: hasText ? widget.onSubmitted : null,
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
