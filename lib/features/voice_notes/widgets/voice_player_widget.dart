import 'package:flutter/material.dart';
import 'package:voice_note_kit/voice_note_kit.dart';
import 'package:msbridge/core/database/voice_notes/voice_note_model.dart';
import 'package:msbridge/core/services/voice_note_service.dart';
import 'package:msbridge/widgets/custom_snackbar.dart';

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
class VoiceNoteCard extends StatelessWidget {
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
            onTap: onTap,
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
                      onPressed: onTap,
                    ),
                  ),

                  const SizedBox(width: 16.0),

                  // Voice note info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voiceNote.voiceNoteTitle,
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
                              voiceNote.formattedDuration,
                              theme,
                            ),
                            const SizedBox(width: 8.0),
                            _buildInfoChip(
                              Icons.calendar_today_outlined,
                              _formatDate(voiceNote.createdAt),
                              theme,
                            ),
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
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
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
