import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

class AutoSaveBubble extends StatelessWidget {
  final ThemeData theme;
  final ValueNotifier<bool> isSavingListenable;
  final ValueNotifier<bool> showCheckmarkListenable;

  const AutoSaveBubble({
    super.key,
    required this.theme,
    required this.isSavingListenable,
    required this.showCheckmarkListenable,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 64,
      child: SafeArea(
        top: false,
        child: ValueListenableBuilder<bool>(
          valueListenable: isSavingListenable,
          builder: (context, isSaving, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: showCheckmarkListenable,
              builder: (context, showCheckmark, __) {
                if (!isSaving && !showCheckmark) {
                  return const SizedBox.shrink();
                }
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: isSaving
                        ? theme.colorScheme.secondary.withValues(alpha: 0.95)
                        : Colors.green.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSaving)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        else
                          const Icon(LineIcons.checkCircleAlt,
                              size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        const Text(
                          'Saved',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}