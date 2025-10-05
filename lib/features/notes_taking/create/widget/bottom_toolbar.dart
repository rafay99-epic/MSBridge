import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BottomToolbar extends StatelessWidget {
  final ThemeData theme;
  final QuillController controller;
  final VoidCallback ensureFocus;
  const BottomToolbar({
    super.key,
    required this.theme,
    required this.controller,
    required this.ensureFocus,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 8,
      right: 8,
      bottom: 8,
      child: SafeArea(
        top: false,
        child: RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Listener(
              onPointerDown: (_) => ensureFocus(),
              child: QuillSimpleToolbar(
                controller: controller,
                config: const QuillSimpleToolbarConfig(
                  multiRowsDisplay: false,
                  toolbarSize: 44,
                  showCodeBlock: true,
                  showQuote: true,
                  showLink: true,
                  showFontSize: true,
                  showFontFamily: true,
                  showIndent: true,
                  showDividers: true,
                  showUnderLineButton: true,
                  showLeftAlignment: true,
                  showCenterAlignment: true,
                  showRightAlignment: true,
                  showJustifyAlignment: true,
                  showHeaderStyle: true,
                  showListNumbers: true,
                  showListBullets: true,
                  showListCheck: true,
                  showStrikeThrough: true,
                  showInlineCode: true,
                  showColorButton: true,
                  showBackgroundColorButton: true,
                  showClearFormat: true,
                  showAlignmentButtons: true,
                  showUndo: true,
                  showRedo: true,
                  showDirection: false,
                  showSearchButton: true,
                  headerStyleType: HeaderStyleType.buttons,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
