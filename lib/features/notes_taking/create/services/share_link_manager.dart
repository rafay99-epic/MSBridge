// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:line_icons/line_icons.dart';
import 'package:share_plus/share_plus.dart';

// Project imports:
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/repo/share_repo.dart';
import 'package:msbridge/widgets/snakbar.dart';

class ShareLinkManager {
  static Future<void> openShareSheet(
    BuildContext context,
    NoteTakingModel note,
    ValueNotifier<bool> isShareOperationInProgress,
  ) async {
    final theme = Theme.of(context);
    final status = await DynamicLink.getShareStatus(note.noteId!);
    String? currentUrl = status.shareUrl.isNotEmpty ? status.shareUrl : null;
    bool enabled = status.enabled;

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateSheet) {
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
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title
                    Text(
                      'Share via Link',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Share toggle card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              LineIcons.shareSquare,
                              size: 24,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Share Link',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  enabled
                                      ? 'Link is active and shareable'
                                      : 'Enable to generate a view-only link',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isShareOperationInProgress.value) ...[
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ] else ...[
                            Switch(
                              value: enabled,
                              onChanged: (value) async {
                                if (isShareOperationInProgress.value) return;

                                isShareOperationInProgress.value = true;
                                setStateSheet(() {});

                                try {
                                  if (value) {
                                    final url =
                                        await DynamicLink.enableShare(note);
                                    setStateSheet(() {
                                      enabled = true;
                                      currentUrl = url;
                                    });
                                    if (context.mounted) {
                                      CustomSnackBar.show(
                                          context, 'Share link enabled',
                                          isSuccess: true);
                                    }
                                  } else {
                                    await DynamicLink.disableShare(note);
                                    setStateSheet(() {
                                      enabled = false;
                                      currentUrl = null;
                                    });
                                    if (context.mounted) {
                                      CustomSnackBar.show(
                                          context, 'Share link disabled',
                                          isSuccess: false);
                                    }
                                  }
                                } catch (e) {
                                  FlutterBugfender.sendCrash(
                                      'Failed to enable/disable share: $e',
                                      StackTrace.current.toString());
                                  FlutterBugfender.error(
                                      'Failed to enable/disable share: $e');
                                  if (context.mounted) {
                                    CustomSnackBar.show(context, e.toString(),
                                        isSuccess: false);
                                  }
                                } finally {
                                  isShareOperationInProgress.value = false;
                                  setStateSheet(() {});
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (currentUrl != null) ...[
                      const SizedBox(height: 16),
                      // URL display card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.surface.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shareable Link',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              currentUrl!,
                              style: TextStyle(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await Clipboard.setData(
                                    ClipboardData(text: currentUrl!));
                                if (context.mounted) {
                                  CustomSnackBar.show(context, 'Link copied',
                                      isSuccess: true);
                                }
                              },
                              icon: const Icon(LineIcons.copy, size: 18),
                              label: const Text('Copy Link'),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  await SharePlus.instance.share(
                                    ShareParams(
                                      text: currentUrl!,
                                      subject: 'Here is the link to the note',
                                      title: 'Shared Note by MSBridge',
                                    ),
                                  );
                                } catch (e) {
                                  FlutterBugfender.sendCrash(
                                    'Failed to share link: $e',
                                    StackTrace.current.toString(),
                                  );
                                  if (context.mounted) {
                                    CustomSnackBar.show(
                                      context,
                                      'Failed to share link: $e',
                                      isSuccess: false,
                                    );
                                  }
                                }
                              },
                              icon: const Icon(LineIcons.share, size: 18),
                              label: const Text('Share'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }
}
