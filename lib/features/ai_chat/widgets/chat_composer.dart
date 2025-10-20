// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:image_picker/image_picker.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

// Project imports:
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
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attach Image Button
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.03),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: IconButton(
                onPressed:
                    widget.isSending ? null : () => _attachImage(context),
                icon: Icon(
                  LineIcons.image,
                  color: widget.isSending
                      ? colorScheme.onSurface.withValues(alpha: 0.4)
                      : colorScheme.primary,
                  size: 20,
                ),
                tooltip: 'Attach Image',
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                  minimumSize: const Size(44, 44),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Input Field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: widget.controller,
                      maxLines: null,
                      enabled: !widget.isSending,
                      textInputAction: TextInputAction.send,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.isSending
                            ? 'Waiting for AI response…'
                            : 'Ask AI anything…',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      onSubmitted:
                          widget.isSending ? null : (_) => widget.onSend(),
                    ),
                    // Queue indicator
                    Consumer<ChatProvider>(
                      builder: (context, chat, _) {
                        if (chat.queueLength == 0) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          margin: const EdgeInsets.only(right: 12, bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Queued: ${chat.queueLength}',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Send/Cancel Button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.isSending
                          ? [
                              colorScheme.primary.withValues(alpha: 0.6),
                              colorScheme.primary.withValues(alpha: 0.4),
                            ]
                          : [
                              colorScheme.primary,
                              colorScheme.primary.withValues(alpha: 0.8),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: widget.isSending
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Icon(
                            LineIcons.paperPlane,
                            color: colorScheme.onPrimary,
                            size: 20,
                          ),
                    onPressed: widget.isSending ? null : widget.onSend,
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      minimumSize: const Size(44, 44),
                    ),
                  ),
                ),
                // Cancel button (appears when sending)
                if (widget.isSending) ...[
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.error.withValues(alpha: 0.08),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        LineIcons.stopCircle,
                        color: colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      tooltip: 'Cancel',
                      onPressed: () {
                        final chat =
                            Provider.of<ChatProvider>(context, listen: false);
                        chat.cancelCurrentRequest();
                      },
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                        minimumSize: const Size(44, 44),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
