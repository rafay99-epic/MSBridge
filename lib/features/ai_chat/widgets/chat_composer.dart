import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/ai/chat_provider.dart';
import 'package:msbridge/core/provider/uploadthing_provider.dart';
import 'package:msbridge/widgets/snakbar.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.isSending,
    required this.onSend,
    required this.controller,
  });

  final bool isSending;
  final VoidCallback onSend;
  final TextEditingController controller;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  Future<void> _attachImage(BuildContext context) async {
    final prov = Provider.of<UploadThingProvider>(context, listen: false);
    final chat = Provider.of<ChatProvider>(context, listen: false);

    final picker = ImagePicker();
    final x =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x == null) return;

    final placeholder = ChatMessage(true, 'Uploading image...');
    chat.messages.add(placeholder);

    try {
      final url = await prov.uploadImage(File(x.path));
      if (url != null) {
        chat.addPendingImageUrl(url);
        if (context.mounted) {
          CustomSnackBar.show(
              context, 'Image attached. Type your question and send.',
              isSuccess: true);
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.show(context, 'Image upload failed', isSuccess: false);
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(context, 'Image upload failed: $e',
            isSuccess: false);
      }
    } finally {
      if (chat.messages.isNotEmpty &&
          identical(chat.messages.last, placeholder)) {
        chat.messages.removeLast();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: widget.isSending ? null : () => _attachImage(context),
              icon: Icon(LineIcons.image, color: colorScheme.primary),
              tooltip: 'Attach Image',
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.4),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: widget.controller,
                  maxLines: null,
                  enabled: !widget.isSending,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: widget.isSending
                        ? 'Waiting for AI response…'
                        : 'Ask AI anything…',
                    hintStyle: TextStyle(
                      color: colorScheme.primary.withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 16,
                  ),
                  onSubmitted: widget.isSending ? null : (_) => widget.onSend(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: widget.isSending
                    ? colorScheme.primary.withValues(alpha: 0.5)
                    : colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: widget.isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Icon(LineIcons.paperPlane,
                        color: colorScheme.onPrimary, size: 20),
                onPressed: widget.isSending ? null : widget.onSend,
                style: IconButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
