import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

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
          hintStyle:
              TextStyle(color: theme.colorScheme.primary.withOpacity(0.6)),
          prefixIcon: Icon(Icons.search,
              color: theme.colorScheme.primary.withOpacity(0.8)),
          filled: true,
          fillColor: theme.colorScheme.surface.withOpacity(0.9),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: theme.colorScheme.primary, width: 1.5),
          ),
        ),
        onChanged: (v) => onChanged(v.trim()),
      ),
    );
  }
}

class TemplateListItem extends StatelessWidget {
  const TemplateListItem({
    super.key,
    required this.title,
    required this.tags,
    required this.onTap,
    this.onLongPress,
    required this.onEdit,
    required this.onDelete,
    this.isSelected = false,
  });
  final String title;
  final List<String> tags;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.secondary.withOpacity(0.08)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.outlineVariant.withOpacity(0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  LineIcons.fileAlt,
                  color: theme.colorScheme.secondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: -6,
                          children:
                              tags.map((t) => _TagChip(label: t)).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        textStyle: theme.textTheme.labelMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        textStyle: theme.textTheme.labelMedium,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary.withOpacity(0.9),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

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
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              deleteIcon: Icon(
                Icons.close,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              onDeleted: () => onRemove(tag),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          );
        },
      ),
    );
  }
}

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
              onSubmitted: onSubmit,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add tag and press +',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                prefixIcon: const Icon(Icons.tag, size: 16),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  tooltip: 'Add tag',
                  onPressed: () => onSubmit(controller.text),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide:
                      BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide:
                      BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide:
                      BorderSide(color: theme.colorScheme.primary, width: 1.5),
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
