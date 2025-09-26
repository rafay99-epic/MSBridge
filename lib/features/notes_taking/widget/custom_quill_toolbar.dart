import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:msbridge/features/notes_taking/widget/note_link_toolbar_button.dart';

class CustomQuillToolbar extends StatelessWidget {
  const CustomQuillToolbar({
    super.key,
    required this.controller,
    required this.onInsertLink,
  });

  final QuillController controller;
  final Function(String linkText) onInsertLink;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Bold, Italic, Underline
            _buildToolbarButton(
              context,
              icon: Icons.format_bold,
              tooltip: 'Bold',
              onPressed: () => controller.formatSelection(Attribute.bold),
            ),
            _buildToolbarButton(
              context,
              icon: Icons.format_italic,
              tooltip: 'Italic',
              onPressed: () => controller.formatSelection(Attribute.italic),
            ),
            _buildToolbarButton(
              context,
              icon: Icons.format_underlined,
              tooltip: 'Underline',
              onPressed: () => controller.formatSelection(Attribute.underline),
            ),

            // Divider
            Container(
              width: 1,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),

            // Headers
            _buildToolbarButton(
              context,
              icon: Icons.title,
              tooltip: 'Header',
              onPressed: () => controller.formatSelection(Attribute.h1),
            ),

            // Divider
            Container(
              width: 1,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),

            // Lists
            _buildToolbarButton(
              context,
              icon: Icons.format_list_bulleted,
              tooltip: 'Bullet List',
              onPressed: () => controller.formatSelection(Attribute.ul),
            ),
            _buildToolbarButton(
              context,
              icon: Icons.format_list_numbered,
              tooltip: 'Numbered List',
              onPressed: () => controller.formatSelection(Attribute.ol),
            ),

            // Divider
            Container(
              width: 1,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),

            // Note Link Button
            NoteLinkToolbarButton(
              controller: controller,
              onInsertLink: onInsertLink,
            ),

            // Regular Link Button - temporarily disabled due to API changes
            // _buildToolbarButton(
            //   context,
            //   icon: Icons.link,
            //   tooltip: 'Web Link',
            //   onPressed: () => _showLinkDialog(context),
            // ),

            // Divider
            Container(
              width: 1,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),

            // Code
            _buildToolbarButton(
              context,
              icon: Icons.code,
              tooltip: 'Code',
              onPressed: () => controller.formatSelection(Attribute.codeBlock),
            ),
            _buildToolbarButton(
              context,
              icon: Icons.format_quote,
              tooltip: 'Quote',
              onPressed: () => controller.formatSelection(Attribute.blockQuote),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon),
        iconSize: 20,
        onPressed: onPressed,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(8),
          minimumSize: const Size(32, 32),
        ),
      ),
    );
  }

  // Temporarily disabled due to Quill API changes
  // void _showLinkDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       final linkController = TextEditingController();
  //       return AlertDialog(
  //         backgroundColor: Theme.of(context).colorScheme.surface,
  //         title: Text(
  //           'Insert Link',
  //           style: TextStyle(
  //             color: Theme.of(context).colorScheme.onSurface,
  //             fontWeight: FontWeight.w600,
  //           ),
  //         ),
  //         content: TextField(
  //           controller: linkController,
  //           decoration: InputDecoration(
  //             hintText: 'Enter URL',
  //             hintStyle: TextStyle(
  //               color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
  //             ),
  //             border: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(8),
  //               borderSide: BorderSide(
  //                 color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
  //               ),
  //             ),
  //           ),
  //           style: TextStyle(
  //             color: Theme.of(context).colorScheme.onSurface,
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: Text(
  //               'Cancel',
  //               style: TextStyle(
  //                 color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
  //               ),
  //             ),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //               final url = linkController.text.trim();
  //               if (url.isNotEmpty) {
  //                 controller.formatSelection(Attribute.link.withValue(url));
  //                 Navigator.pop(context);
  //               }
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Theme.of(context).colorScheme.primary,
  //               foregroundColor: Theme.of(context).colorScheme.onPrimary,
  //             ),
  //             child: Text(
  //               'Insert',
  //               style: TextStyle(
  //                 color: Theme.of(context).colorScheme.onPrimary,
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
}
