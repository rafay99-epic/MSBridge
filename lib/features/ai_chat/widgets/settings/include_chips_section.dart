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

        Color getChipLabelColor(bool chipSelected, bool isEnabled) => isEnabled
            ? (chipSelected
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.7))
            : colorScheme.onSurface.withValues(alpha: 0.4);

        Color getChipBorderColor(bool chipSelected, bool isEnabled) => isEnabled
            ? (chipSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3))
            : colorScheme.onSurface.withValues(alpha: 0.2);

        Widget buildIncludeChip(
          String label,
          bool selected,
          ValueChanged<bool>? onSelected,
        ) {
          return FilterChip(
            label: Text(label),
            selected: selected,
            onSelected: isGlobalConsentEnabled ? onSelected : null,
            selectedColor: isGlobalConsentEnabled && selected
                ? colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            checkmarkColor: isGlobalConsentEnabled && selected
                ? colorScheme.primary
                : Colors.transparent,
            labelStyle: TextStyle(
              color: getChipLabelColor(selected, isGlobalConsentEnabled),
              fontWeight: selected && isGlobalConsentEnabled
                  ? FontWeight.w600
                  : FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: getChipBorderColor(selected, isGlobalConsentEnabled),
              ),
            ),
          );
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
                buildIncludeChip(
                  'Personal Notes',
                  includePersonal,
                  onIncludePersonalChanged,
                ),
                buildIncludeChip(
                  'MS Notes',
                  includeMsNotes,
                  onIncludeMsNotesChanged,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
