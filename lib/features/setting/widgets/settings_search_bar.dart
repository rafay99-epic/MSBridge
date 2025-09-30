import 'package:flutter/material.dart';

class SettingsSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback? onTap;

  const SettingsSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: cs.primary.withValues(alpha: 0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(Icons.search,
                size: 20, color: cs.primary.withValues(alpha: 0.6)),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                onTap: onTap,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search settings...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, __) => value.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close, size: 18, color: cs.primary),
                      tooltip: 'Clear',
                      onPressed: onClear,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
