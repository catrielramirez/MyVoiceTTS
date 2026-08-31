import 'dart:ui';
import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final bool isLoading;
  final String? message;
  final VoidCallback? onCancel;

  const LoadingWidget({
    super.key, 
    required this.isLoading,
    this.message,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isLoading
          ? Stack(
              children: [
                // Filtro de desenfoque
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                    child: ModalBarrier(
                      dismissible: false,
                      color: Colors.black.withOpacity(0.4),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 20,
                            offset: Offset(0, 10))
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(strokeWidth: 5),
                        if (message != null) ...[
                          const SizedBox(height: 20),
                          Text(
                            message!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (onCancel != null) ...[
                          const SizedBox(height: 24),
                          TextButton.icon(
                            onPressed: onCancel,
                            icon: const Icon(Icons.close,
                                color: Colors.redAccent),
                            label: const Text(
                              "Cancelar",
                              style: TextStyle(color: Colors.redAccent),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              backgroundColor:
                                  Colors.redAccent.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}
