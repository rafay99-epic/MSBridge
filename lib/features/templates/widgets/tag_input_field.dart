// Flutter imports:
import 'package:flutter/material.dart';

class TagInputField extends StatelessWidget {
  const TagInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.done,
              onSubmitted: (raw) {
                final value = raw.trim();
                if (value.isEmpty) return;
                onSubmit(value);
                controller.clear();
                FocusScope.of(context).unfocus();
              },
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add tag and press +',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(
                  Icons.tag,
                  size: 16,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.add,
                      size: 18,
                      color: theme.colorScheme.primary.withValues(alpha: 0.8)),
                  tooltip: 'Add tag',
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isEmpty) return;
                    onSubmit(value);
                    controller.clear();
                    FocusScope.of(context).unfocus();
                  },
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.15),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.15),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide:
                      BorderSide(color: theme.colorScheme.primary, width: 1.0),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
