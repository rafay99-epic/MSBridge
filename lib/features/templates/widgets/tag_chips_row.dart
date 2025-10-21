// Flutter imports:
import 'package:flutter/material.dart';

class TagChipsRow extends StatelessWidget {
  const TagChipsRow({super.key, required this.tags, required this.onRemove});
  final List<String> tags;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (tags.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 30,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tags.length,
        itemBuilder: (context, index) {
          final tag = tags[index];
          return Container(
            margin: const EdgeInsets.only(right: 6),
            child: Chip(
              label: Text(
                tag,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.primary.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              deleteIcon: Icon(
                Icons.close,
                size: 18,
                color: theme.colorScheme.primary.withValues(alpha: 0.75),
              ),
              onDeleted: () => onRemove(tag),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: StadiumBorder(
                side: BorderSide(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
