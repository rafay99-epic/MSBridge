import 'package:flutter/material.dart';
import 'package:msbridge/core/provider/ai_consent_provider.dart';

class IncludeChipsSection extends StatelessWidget {
  const IncludeChipsSection({
    super.key,
    required this.aiConsentProvider,
    required this.includePersonal,
    required this.includeMsNotes,
    required this.onIncludePersonalChanged,
    required this.onIncludeMsNotesChanged,
  });

  final AiConsentProvider aiConsentProvider;
  final bool includePersonal;
  final bool includeMsNotes;
  final ValueChanged<bool> onIncludePersonalChanged;
  final ValueChanged<bool> onIncludeMsNotesChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: aiConsentProvider,
      builder: (context, _) {
        final bool isGlobalConsentEnabled = aiConsentProvider.enabled;

        Color getChipLabelColor(bool chipSelected, bool isEnabled) {
          if (isEnabled) {
            return chipSelected
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.7);
          } else {
            return colorScheme.onSurface.withValues(alpha: 0.4);
          }
        }

        Color getChipBorderColor(bool chipSelected, bool isEnabled) {
          if (isEnabled) {
            return chipSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3);
          } else {
            return colorScheme.onSurface.withValues(alpha: 0.2);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Include in AI responses:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Personal Notes'),
                  selected: includePersonal,
                  onSelected:
                      isGlobalConsentEnabled ? onIncludePersonalChanged : null,
                  selectedColor: isGlobalConsentEnabled && includePersonal
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  checkmarkColor: isGlobalConsentEnabled && includePersonal
                      ? colorScheme.primary
                      : Colors.transparent,
                  labelStyle: TextStyle(
                    color: getChipLabelColor(
                        includePersonal, isGlobalConsentEnabled),
                    fontWeight: includePersonal && isGlobalConsentEnabled
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: getChipBorderColor(
                          includePersonal, isGlobalConsentEnabled),
                    ),
                  ),
                ),
                FilterChip(
                  label: const Text('MS Notes'),
                  selected: includeMsNotes,
                  onSelected:
                      isGlobalConsentEnabled ? onIncludeMsNotesChanged : null,
                  selectedColor: isGlobalConsentEnabled && includeMsNotes
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  checkmarkColor: isGlobalConsentEnabled && includeMsNotes
                      ? colorScheme.primary
                      : Colors.transparent,
                  labelStyle: TextStyle(
                    color: getChipLabelColor(
                        includeMsNotes, isGlobalConsentEnabled),
                    fontWeight: includeMsNotes && isGlobalConsentEnabled
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: getChipBorderColor(
                          includeMsNotes, isGlobalConsentEnabled),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
