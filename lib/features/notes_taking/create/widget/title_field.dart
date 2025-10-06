import 'package:flutter/material.dart';

class TitleField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  const TitleField(
      {super.key, required this.controller, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        contextMenuBuilder:
            (BuildContext context, EditableTextState editableTextState) =>
                AdaptiveTextSelectionToolbar.editableText(
          editableTextState: editableTextState,
        ),
        decoration: const InputDecoration(
          hintText: 'Title',
          hintStyle: TextStyle(
            color: Colors.grey,
          ),
          border: InputBorder.none,
        ),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class TagsSection extends StatelessWidget {
  final ThemeData theme;
  final ValueNotifier<List<String>> tagsNotifier;
  final TextEditingController tagInputController;
  final FocusNode tagFocusNode;
  final void Function(String tag) onAddTag;
  final VoidCallback onAutoSave;
  const TagsSection({
    super.key,
    required this.theme,
    required this.tagsNotifier,
    required this.tagInputController,
    required this.tagFocusNode,
    required this.onAddTag,
    required this.onAutoSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<List<String>>(
            valueListenable: tagsNotifier,
            builder: (context, tags, _) {
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
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        deleteIcon: Icon(
                          Icons.close,
                          size: 18,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.75),
                        ),
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.15),
                          ),
                        ),
                        onDeleted: () {
                          final next = List<String>.from(tags)..remove(tag);
                          tagsNotifier.value = next;
                          onAutoSave();
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          SizedBox(
            height: 40,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tagInputController,
                    focusNode: tagFocusNode,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (raw) {
                      final v = raw.trim();
                      if (v.isEmpty) return;
                      onAddTag(v);
                      tagInputController.clear();
                      FocusScope.of(context).unfocus();
                    },
                    contextMenuBuilder: (BuildContext context,
                            EditableTextState editableTextState) =>
                        AdaptiveTextSelectionToolbar.editableText(
                      editableTextState: editableTextState,
                    ),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Add tag...',
                      hintStyle: TextStyle(
                          fontSize: 12,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.5)),
                      prefixIcon: Icon(Icons.tag,
                          size: 16,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.7)),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.add,
                            size: 18,
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.8)),
                        tooltip: 'Add tag',
                        onPressed: () {
                          final v = tagInputController.text.trim();
                          if (v.isEmpty) return;
                          onAddTag(v);
                          tagInputController.clear();
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
                                .withValues(alpha: 0.15)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                            color: theme.colorScheme.primary, width: 1.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
