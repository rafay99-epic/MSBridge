import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:voice_note_kit/voice_note_kit.dart';
import 'package:msbridge/core/database/voice_notes/voice_note_model.dart';
import 'package:msbridge/core/services/voice_note_service.dart';
import 'package:msbridge/widgets/custom_snackbar.dart';
import 'package:msbridge/core/repo/voice_note_share_repo.dart';
import 'package:line_icons/line_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class VoicePlayerWidget extends StatefulWidget {
  final VoiceNoteModel voiceNote;
  final bool showTitle;
  final bool showMetadata;
  final bool compact;
  final Function(VoiceNoteModel)? onPlay;
  final Function(VoiceNoteModel)? onPause;
  final Function(VoiceNoteModel)? onError;

  const VoicePlayerWidget({
    super.key,
    required this.voiceNote,
    this.showTitle = true,
    this.showMetadata = true,
    this.compact = false,
    this.onPlay,
    this.onPause,
    this.onError,
  });

  @override
  State<VoicePlayerWidget> createState() => _VoicePlayerWidgetState();
}

class _VoicePlayerWidgetState extends State<VoicePlayerWidget> {
  final VoiceNoteService _voiceNoteService = VoiceNoteService();
  bool _isFileExists = true;
  bool _isCheckingFile = true;

  @override
  void initState() {
    super.initState();
    _checkFileExists();
  }

  Future<void> _checkFileExists() async {
    final exists =
        await _voiceNoteService.audioFileExists(widget.voiceNote.audioFilePath);
    if (mounted) {
      setState(() {
        _isFileExists = exists;
        _isCheckingFile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isCheckingFile) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      );
    }

    if (!_isFileExists) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                'Audio file not found',
                style: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: widget.compact
          ? const EdgeInsets.all(12.0)
          : const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title and metadata
          if (widget.showTitle || widget.showMetadata) ...[
            Row(
              children: [
                Icon(
                  Icons.mic,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: widget.showTitle
                      ? Text(
                          widget.voiceNote.voiceNoteTitle,
                          style: TextStyle(
                            fontSize: widget.compact ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : const SizedBox.shrink(),
                ),
                if (widget.showMetadata && !widget.compact)
                  Text(
                    widget.voiceNote.formattedDuration,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontFamily: 'Poppins',
                    ),
                  ),
              ],
            ),
            if (widget.showMetadata && !widget.compact) ...[
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    _formatDate(widget.voiceNote.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Icon(
                    Icons.storage,
                    size: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    widget.voiceNote.formattedFileSize,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
            if (widget.voiceNote.description != null &&
                widget.voiceNote.description!.isNotEmpty &&
                !widget.compact) ...[
              const SizedBox(height: 8.0),
              Text(
                widget.voiceNote.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontFamily: 'Poppins',
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16.0),
          ],

          // Audio player
          AudioPlayerWidget(
            audioPath: widget.voiceNote.audioFilePath,
            playerStyle:
                widget.compact ? PlayerStyle.style3 : PlayerStyle.style5,
            size: widget.compact ? 40 : 50,
            width: double.infinity,
            backgroundColor: theme.colorScheme.primary,
            progressBarColor: theme.colorScheme.secondary,
            progressBarBackgroundColor:
                theme.colorScheme.outline.withOpacity(0.3),
            iconColor: theme.colorScheme.onPrimary,
            progressBarHeight: widget.compact ? 3 : 4,
            showProgressBar: true,
            showTimer: true,
            audioSpeeds: const [0.5, 1.0, 1.25, 1.5, 2.0],
            autoPlay: false,
            autoLoad: true,
            onPlay: (isPlaying) {
              if (isPlaying) {
                widget.onPlay?.call(widget.voiceNote);
              } else {
                widget.onPause?.call(widget.voiceNote);
              }
            },
            onError: (message) {
              widget.onError?.call(widget.voiceNote);
              if (mounted) {
                CustomSnackBar.show(
                  context,
                  'Playback error: $message',
                  SnackBarType.error,
                );
              }
            },
            onSpeedChange: (speed) {
              // Optional: Handle speed change
              debugPrint('Playback speed changed to: ${speed}x');
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return '${difference.inHours}h ago';
      }
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Compact voice note card for lists
class VoiceNoteCard extends StatefulWidget {
  final VoiceNoteModel voiceNote;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const VoiceNoteCard({
    super.key,
    required this.voiceNote,
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<VoiceNoteCard> createState() => _VoiceNoteCardState();
}

class _VoiceNoteCardState extends State<VoiceNoteCard> {
  bool _isShared = false;
  String _shareUrl = '';

  @override
  void initState() {
    super.initState();
    _loadShareStatus();
  }

  Future<void> _loadShareStatus() async {
    try {
      final shareStatus = await VoiceNoteShareRepository.getShareStatus(
          widget.voiceNote.voiceNoteId!);
      if (mounted) {
        setState(() {
          _isShared = shareStatus.enabled;
          _shareUrl = shareStatus.shareUrl;
        });
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to load share status: $e', StackTrace.current.toString());
    }
  }

  Widget _buildInfoChip(IconData icon, String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 4.0),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareStatusChip(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LineIcons.share,
            size: 12,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4.0),
          Text(
            'Shared',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.primary,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enableShare() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Creating shareable link...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      );

      final shareUrl =
          await VoiceNoteShareRepository.enableShare(widget.voiceNote);

      // Dismiss loading dialog
      Navigator.of(context).pop();

      // Update local state
      setState(() {
        _isShared = true;
        _shareUrl = shareUrl;
      });

      // Show share options dialog
      _showShareOptionsDialog(shareUrl);
    } catch (e) {
      // Dismiss loading dialog
      Navigator.of(context).pop();

      CustomSnackBar.show(
        context,
        'Failed to create share link: $e',
        SnackBarType.error,
      );
    }
  }

  Future<void> _disableShare() async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Share Link',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: Text(
            'This will delete the share link and make the voice note private again. The shared link will no longer work.',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(
                'Delete Share',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await VoiceNoteShareRepository.disableShare(widget.voiceNote);

        setState(() {
          _isShared = false;
          _shareUrl = '';
        });

        CustomSnackBar.show(
          context,
          'Share link deleted successfully',
          SnackBarType.success,
        );
      }
    } catch (e) {
      CustomSnackBar.show(
        context,
        'Failed to delete share link: $e',
        SnackBarType.error,
      );
    }
  }

  void _showShareLinkDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LineIcons.link,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Share Link',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voice note title
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    LineIcons.microphone,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.voiceNote.voiceNoteTitle,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Share URL section
            Text(
              'Share Link',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),

            // URL container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      _shareUrl,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _shareUrl));
                      if (mounted) {
                        CustomSnackBar.show(
                          context,
                          'Link copied to clipboard!',
                          SnackBarType.success,
                        );
                      }
                    },
                    icon: Icon(
                      LineIcons.copy,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                    tooltip: 'Copy link',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Share options
            Text(
              'Share Options',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),

            // Share buttons
            Row(
              children: [
                Expanded(
                  child: _buildShareButton(
                    context,
                    'Share via App',
                    LineIcons.share,
                    () async {
                      Navigator.of(context).pop();
                      await Share.share(
                        '🎤 Check out my voice note: "${widget.voiceNote.voiceNoteTitle}"\n\n$_shareUrl',
                        subject:
                            'Voice Note: ${widget.voiceNote.voiceNoteTitle}',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildShareButton(
                    context,
                    'Copy Link',
                    LineIcons.copy,
                    () async {
                      await Clipboard.setData(ClipboardData(text: _shareUrl));
                      if (mounted) {
                        Navigator.of(context).pop();
                        CustomSnackBar.show(
                          context,
                          'Link copied to clipboard!',
                          SnackBarType.success,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'Close',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showShareOptionsDialog(String shareUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LineIcons.share,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Share Voice Note',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voice note title
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    LineIcons.microphone,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.voiceNote.voiceNoteTitle,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Share URL section
            Text(
              'Share Link',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),

            // URL container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      shareUrl,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: shareUrl));
                      if (mounted) {
                        CustomSnackBar.show(
                          context,
                          'Link copied to clipboard!',
                          SnackBarType.success,
                        );
                      }
                    },
                    icon: Icon(
                      LineIcons.copy,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                    tooltip: 'Copy link',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Share options
            Text(
              'Share Options',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),

            // Share buttons
            Row(
              children: [
                Expanded(
                  child: _buildShareButton(
                    context,
                    'Share via App',
                    LineIcons.share,
                    () async {
                      Navigator.of(context).pop();
                      await Share.share(
                        '🎤 Check out my voice note: "${widget.voiceNote.voiceNoteTitle}"\n\n$shareUrl',
                        subject:
                            'Voice Note: ${widget.voiceNote.voiceNoteTitle}',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildShareButton(
                    context,
                    'Copy Link',
                    LineIcons.copy,
                    () async {
                      await Clipboard.setData(ClipboardData(text: shareUrl));
                      if (mounted) {
                        Navigator.of(context).pop();
                        CustomSnackBar.show(
                          context,
                          'Link copied to clipboard!',
                          SnackBarType.success,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'Close',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Play button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.play_arrow, size: 24),
                      color: theme.colorScheme.onPrimary,
                      onPressed: widget.onTap,
                    ),
                  ),

                  const SizedBox(width: 16.0),

                  // Voice note info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.voiceNote.voiceNoteTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                            fontFamily: 'Poppins',
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6.0),
                        Row(
                          children: [
                            _buildInfoChip(
                              Icons.schedule_outlined,
                              widget.voiceNote.formattedDuration,
                              theme,
                            ),
                            const SizedBox(width: 8.0),
                            _buildInfoChip(
                              Icons.calendar_today_outlined,
                              _formatDate(widget.voiceNote.createdAt),
                              theme,
                            ),
                            if (_isShared) ...[
                              const SizedBox(width: 8.0),
                              _buildShareStatusChip(theme),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    onSelected: (value) async {
                      switch (value) {
                        case 'share':
                          await _enableShare();
                          break;
                        case 'view_share':
                          _showShareLinkDialog();
                          break;
                        case 'unshare':
                          await _disableShare();
                          break;
                        case 'delete':
                          widget.onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (!_isShared)
                        PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(
                                LineIcons.share,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 12.0),
                              Text(
                                'Share Voice Note',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_isShared) ...[
                        PopupMenuItem(
                          value: 'view_share',
                          child: Row(
                            children: [
                              Icon(
                                LineIcons.link,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 12.0),
                              Text(
                                'View Share Link',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'unshare',
                          child: Row(
                            children: [
                              Icon(
                                LineIcons.unlink,
                                color: theme.colorScheme.error,
                                size: 18,
                              ),
                              const SizedBox(width: 12.0),
                              Text(
                                'Delete Share',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: theme.colorScheme.error,
                              size: 18,
                            ),
                            const SizedBox(width: 12.0),
                            Text(
                              'Delete Voice Note',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return '${difference.inHours}h ago';
      }
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
