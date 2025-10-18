// Flutter imports:
import 'package:flutter/material.dart';

class TemplatesSearchField extends StatelessWidget {
  const TemplatesSearchField({super.key, required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        style: TextStyle(color: theme.colorScheme.primary),
        decoration: InputDecoration(
          hintText: 'Search templates...',
          hintStyle: TextStyle(
              color: theme.colorScheme.primary.withValues(alpha: 0.6)),
          prefixIcon: Icon(Icons.search,
              color: theme.colorScheme.primary.withValues(alpha: 0.8)),
          filled: true,
          fillColor: theme.colorScheme.surface.withValues(alpha: 0.9),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: theme.colorScheme.primary, width: 1.0),
          ),
        ),
        onChanged: (v) => onChanged(v.trim()),
      ),
    );
  }
}
