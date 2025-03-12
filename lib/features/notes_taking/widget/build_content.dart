import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

Widget buildContent(String content, ThemeData theme) {
  try {
    final jsonResult = jsonDecode(content);
    if (jsonResult is List) {
      final document = Document.fromJson(jsonResult);
      return AbsorbPointer(
        child: QuillEditor.basic(
          configurations: QuillEditorConfigurations(
            controller: QuillController(
              document: document,
              selection: const TextSelection.collapsed(offset: 0),
            ),
            sharedConfigurations: const QuillSharedConfigurations(),
          ),
        ),
      );
    } else {
      return Text(
        content,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      );
    }
  } catch (e) {
    return Text(
      content,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.primary,
      ),
    );
  }
}
