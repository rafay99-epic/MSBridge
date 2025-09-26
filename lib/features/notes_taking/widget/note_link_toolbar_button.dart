import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:msbridge/core/services/note_linking/note_link_service.dart';

class NoteLinkToolbarButton extends StatelessWidget {
  const NoteLinkToolbarButton({
    super.key,
    required this.controller,
    required this.onInsertLink,
  });

  final QuillController controller;
  final Function(String linkText) onInsertLink;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Link to Note',
      child: IconButton(
        icon: const Icon(Icons.link_off),
        iconSize: 20,
        onPressed: () => _showLinkDialog(context),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(8),
          minimumSize: const Size(32, 32),
        ),
      ),
    );
  }

  void _showLinkDialog(BuildContext context) {
    NoteLinkService.showNotePicker(
      context,
      (noteId, noteTitle) {
        NoteLinkService.insertLinkInEditor(
          context,
          noteId,
          noteTitle,
          onInsertLink,
        );
      },
    );
  }
}
