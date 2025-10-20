// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:msbridge/core/provider/ai_consent_provider.dart';

class ConsentToggleRow extends StatelessWidget {
  const ConsentToggleRow({
    super.key,
    required this.aiConsentProvider,
    required this.onConsentToggleChanged,
  });

  final AiConsentProvider aiConsentProvider;
  final ValueChanged<bool> onConsentToggleChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return ChangeNotifierProvider.value(
      value: aiConsentProvider,
      child: Consumer<AiConsentProvider>(
        builder: (context, consent, _) {
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LineIcons.userShield,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI can access your notes for better answers',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Switch(
                value: consent.enabled,
                onChanged: onConsentToggleChanged,
                activeThumbColor: colorScheme.primary,
              ),
            ],
          );
        },
      ),
    );
  }
}
