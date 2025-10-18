// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_quill/flutter_quill.dart';
import 'package:line_icons/line_icons.dart';

// Project imports:
import 'package:msbridge/features/notes_taking/create/widget/build_bottom_sheet_action.dart';
import 'package:msbridge/features/notes_taking/export_notes/export_notes.dart';

class ExportManager {
  static void showMoreActionsBottomSheet(
    BuildContext context,
    TextEditingController titleController,
    QuillController controller,
    bool hasShareEnabled,
    VoidCallback onTemplatesTap,
    VoidCallback onShareTap,
  ) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return RepaintBoundary(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    'More Actions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Action buttons
                  buildBottomSheetAction(
                    icon: LineIcons.fileExport,
                    title: 'Export',
                    subtitle: 'Export note to various formats',
                    onTap: () {
                      Navigator.pop(context);
                      showExportOptions(
                        context,
                        theme,
                        titleController,
                        controller,
                      );
                    },
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  buildBottomSheetAction(
                    icon: LineIcons.clone,
                    title: 'Templates',
                    subtitle: 'Use or create note templates',
                    onTap: () {
                      Navigator.pop(context);
                      onTemplatesTap();
                    },
                    theme: theme,
                  ),
                  if (hasShareEnabled) ...[
                    const SizedBox(height: 12),
                    buildBottomSheetAction(
                      icon: LineIcons.shareSquare,
                      title: 'Share Link',
                      subtitle: 'Create a shareable link for this note',
                      onTap: () {
                        Navigator.pop(context);
                        onShareTap();
                      },
                      theme: theme,
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
