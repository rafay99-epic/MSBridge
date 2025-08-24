import 'dart:convert';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

Widget buildContent(String content, ThemeData theme) {
  try {
    final jsonResult = jsonDecode(content);
    if (jsonResult is List) {
      final document = Document.fromJson(jsonResult);
      return AbsorbPointer(
        child: QuillEditor.basic(
          controller: QuillController(
            document: document,
            selection: const TextSelection.collapsed(offset: 0),
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
    FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
        reason:
            'Error building content $content , with $theme and expection is $e');
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
