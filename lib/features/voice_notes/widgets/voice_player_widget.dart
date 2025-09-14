import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:voice_note_kit/voice_note_kit.dart';
import 'package:msbridge/core/database/voice_notes/voice_note_model.dart';
import 'package:msbridge/core/services/voice_note_service.dart';
import 'package:msbridge/widgets/custom_snackbar.dart';
import 'package:msbridge/core/repo/voice_note_share_repo.dart';
import 'package:line_icons/line_icons.dart';

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

  @override
  void initState() {
    super.initState();
    _loadShareStatus();
  }

  Future<void> _loadShareStatus() async {
    final id = widget.voiceNote.voiceNoteId;
    if (id == null) {
      // Set safe default when voiceNoteId is null
      if (mounted) {
        setState(() {
          _isShared = false;
        });
      }
      return;
    }

    try {
      final shareStatus = await VoiceNoteShareRepository.getShareStatus(id);
      if (mounted) {
        setState(() {
          _isShared = shareStatus.enabled;
        });
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to load share status: $e', StackTrace.current.toString());
    }
  }

  Widget _buildEnhancedInfoChip(IconData icon, String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surfaceVariant.withOpacity(0.4),
            theme.colorScheme.surfaceVariant.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 6.0),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
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
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onTap,
                          borderRadius: BorderRadius.circular(16),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            size: 28,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16.0),

                    // Title and metadata
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.voiceNote.voiceNoteTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                              fontFamily: 'Poppins',
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              _buildEnhancedInfoChip(
                                LineIcons.clock,
                                widget.voiceNote.formattedDuration,
                                theme,
                              ),
                              const SizedBox(width: 12.0),
                              _buildEnhancedInfoChip(
                                LineIcons.calendar,
                                _formatDate(widget.voiceNote.createdAt),
                                theme,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Share status indicator
                    if (_isShared)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withOpacity(0.1),
                              theme.colorScheme.primary.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LineIcons.share,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Shared',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Description preview (if available)
                if (widget.voiceNote.description != null &&
                    widget.voiceNote.description!.isNotEmpty) ...[
                  const SizedBox(height: 16.0),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.voiceNote.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                        fontFamily: 'Poppins',
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                // Bottom row with file size and settings icon
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // File size
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.surfaceVariant.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.storage_outlined,
                            size: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.voiceNote.formattedFileSize,
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tap to view details hint
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LineIcons.chevronRight,
                            size: 12,
                            color: theme.colorScheme.primary.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to view',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.primary.withOpacity(0.7),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
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
