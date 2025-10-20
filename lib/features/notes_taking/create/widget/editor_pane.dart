// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_quill/flutter_quill.dart';

class EditorPane extends StatelessWidget {
  final QuillController controller;
  final FocusNode focusNode;
  const EditorPane(
      {super.key, required this.controller, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RepaintBoundary(
        child: QuillEditor.basic(
          controller: controller,
          focusNode: focusNode,
          config: QuillEditorConfig(
            disableClipboard: false,
            autoFocus: true,
            placeholder: 'Note...',
            expands: true,
            onTapUp: (_, __) {
              if (!focusNode.hasFocus) {
                FocusScope.of(context).requestFocus(focusNode);
              }
              return false;
            },
          ),
        ),
      ),
    );
  }
}
