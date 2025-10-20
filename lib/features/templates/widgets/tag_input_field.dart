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

  void _submit(BuildContext context) {
    final String value = controller.text.trim();
    if (value.isEmpty) return;
    onSubmit(value);
    controller.clear();
    FocusScope.of(context).unfocus();
  }

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
              onSubmitted: (raw) => _submit(context),
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
                suffixIcon: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _submit(context),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.add,
                          size: 18,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
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
