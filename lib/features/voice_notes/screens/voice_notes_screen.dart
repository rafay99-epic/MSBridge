import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/database/voice_notes/voice_note_model.dart';
import 'package:msbridge/core/repo/voice_note_repo.dart';
import 'package:msbridge/core/services/voice_note_service.dart';
import 'package:msbridge/features/voice_notes/widgets/voice_recorder_widget.dart';
import 'package:msbridge/features/voice_notes/widgets/voice_player_widget.dart';
import 'package:msbridge/widgets/custom_snackbar.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:msbridge/core/repo/voice_note_share_repo.dart';
import 'package:share_plus/share_plus.dart';

class VoiceNotesScreen extends StatefulWidget {
  const VoiceNotesScreen({super.key});

  @override
  State<VoiceNotesScreen> createState() => _VoiceNotesScreenState();
}

class _VoiceNotesScreenState extends State<VoiceNotesScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final VoiceNoteService _voiceNoteService = VoiceNoteService();

  List<VoiceNoteModel> _voiceNotes = [];
  List<VoiceNoteModel> _filteredVoiceNotes = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';

  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );

    _loadVoiceNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadVoiceNotes() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final voiceNotes = await VoiceNoteRepo.getAllVoiceNotes();

      if (mounted) {
        setState(() {
          _voiceNotes = voiceNotes;
          _filteredVoiceNotes = voiceNotes;
          _isLoading = false;
        });

        if (_searchQuery.isNotEmpty) {
          _searchVoiceNotes(_searchQuery);
        }

        _fabController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        CustomSnackBar.show(
          context,
          'Error loading voice notes: $e',
          SnackBarType.error,
        );
      }
    }
  }

  void _searchVoiceNotes(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });

    if (query.isEmpty) {
      setState(() {
        _filteredVoiceNotes = _voiceNotes;
      });
    } else {
      // Search in both title and description
      final filtered = _voiceNotes.where((voiceNote) {
        final titleMatch = voiceNote.voiceNoteTitle
            .toLowerCase()
            .contains(query.toLowerCase());
        final descriptionMatch = voiceNote.description != null &&
            voiceNote.description!.toLowerCase().contains(query.toLowerCase());
        return titleMatch || descriptionMatch;
      }).toList();

      setState(() {
        _filteredVoiceNotes = filtered;
      });
    }
  }

  Future<void> _deleteVoiceNote(VoiceNoteModel voiceNote) async {
    try {
      setState(() {
        _voiceNotes
            .removeWhere((note) => note.voiceNoteId == voiceNote.voiceNoteId);
        _filteredVoiceNotes
            .removeWhere((note) => note.voiceNoteId == voiceNote.voiceNoteId);
      });

      await _voiceNoteService.deleteVoiceNote(voiceNote);

      if (mounted) {
        CustomSnackBar.show(
          context,
          'Voice note permanently deleted',
          SnackBarType.success,
        );

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      FlutterBugfender.sendIssue(
        e.toString(),
        StackTrace.current.toString(),
      );
      await _loadVoiceNotes();

      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error deleting voice note: $e',
          SnackBarType.error,
        );
      }
    }
  }

  void _showDeleteConfirmation(VoiceNoteModel voiceNote) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              LineIcons.exclamationTriangle,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Voice Note',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${voiceNote.voiceNoteTitle}"?\n\nThis will delete both the recording file and all metadata. This action cannot be undone.',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteVoiceNote(voiceNote);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              backgroundColor:
                  Theme.of(context).colorScheme.error.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Delete Permanently',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRecordingModal() {
    showMaterialModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: VoiceRecorderWidget(
          onRecordingComplete: (voiceNote) {
            Navigator.of(context).pop();
            _loadVoiceNotes();
          },
          onError: (error) {
            Navigator.of(context).pop();
            CustomSnackBar.show(
              context,
              'Recording error: $error',
              SnackBarType.error,
            );
          },
          onRecordingCancelled: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _showVoiceNoteDetails(VoiceNoteModel voiceNote) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scrollController) => RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.all(Radius.circular(3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Header with title and actions
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              voiceNote.voiceNoteTitle,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontFamily: 'Poppins',
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12.0),
                            _buildMetadataRow(context, voiceNote),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      // Settings button
                      _buildActionButton(
                        context,
                        LineIcons.cog,
                        'Voice Note Settings',
                        () => _showVoiceNoteSettingsBottomSheet(
                            context, voiceNote),
                        isDestructive: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32.0),

                  // Description section
                  if (voiceNote.description != null &&
                      voiceNote.description!.isNotEmpty) ...[
                    _buildSectionCard(
                      context,
                      'Description',
                      Icons.description_outlined,
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceVariant
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          voiceNote.description!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.8),
                            fontFamily: 'Poppins',
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                  ],

                  // Audio player section
                  _buildSectionCard(
                    context,
                    'Audio Player',
                    LineIcons.play,
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: FutureBuilder<bool>(
                        future: _checkAudioFileExists(voiceNote),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return SizedBox(
                              height: 60,
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            );
                          }

                          if (snapshot.data == true) {
                            return VoicePlayerWidget(
                              voiceNote: voiceNote,
                              showTitle: false,
                              showMetadata: false,
                            );
                          } else {
                            return Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .errorContainer
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Theme.of(context).colorScheme.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12.0),
                                  Expanded(
                                    child: Text(
                                      'Audio file not found',
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Additional info section
                  _buildSectionCard(
                    context,
                    'File Information',
                    Icons.info_outline,
                    Column(
                      children: [
                        _buildInfoRow(
                          context,
                          'Duration',
                          voiceNote.formattedDuration,
                          LineIcons.clock,
                        ),
                        const SizedBox(height: 12.0),
                        _buildInfoRow(
                          context,
                          'File Size',
                          voiceNote.formattedFileSize,
                          Icons.storage_outlined,
                        ),
                        const SizedBox(height: 12.0),
                        _buildInfoRow(
                          context,
                          'Created',
                          _formatDetailedDate(voiceNote.createdAt),
                          LineIcons.calendar,
                        ),
                        const SizedBox(height: 12.0),
                        _buildInfoRow(
                          context,
                          'Last Modified',
                          _formatDetailedDate(voiceNote.updatedAt),
                          LineIcons.edit,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _checkAudioFileExists(VoiceNoteModel voiceNote) async {
    try {
      final voiceNoteService = VoiceNoteService();
      return await voiceNoteService.audioFileExists(voiceNote.audioFilePath);
    } catch (e) {
      return false;
    }
  }

  Future<void> _viewShareLink(VoiceNoteModel voiceNote) async {
    try {
      // Get current share status
      final shareStatus =
          await VoiceNoteShareRepository.getShareStatus(voiceNote.voiceNoteId!);

      if (shareStatus.enabled && shareStatus.shareUrl.isNotEmpty) {
        _showShareOptionsDialog(voiceNote, shareStatus.shareUrl);
      } else {
        CustomSnackBar.show(
          context,
          'Share link not found. Please try sharing again.',
          SnackBarType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error accessing share link: $e',
          SnackBarType.error,
        );
      }
    }
  }

  Future<void> _deleteShare(VoiceNoteModel voiceNote) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                LineIcons.exclamationTriangle,
                color: Theme.of(context).colorScheme.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Delete Share Link',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete the share link for "${voiceNote.voiceNoteTitle}"?\n\nThis will make the voice note no longer accessible via the share link. The voice note itself will remain in your collection.',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                backgroundColor:
                    Theme.of(context).colorScheme.error.withOpacity(0.1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Deleting share link...',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );

        // Disable sharing
        await VoiceNoteShareRepository.disableShare(voiceNote);

        // Close loading dialog
        if (mounted) Navigator.of(context).pop();

        if (mounted) {
          CustomSnackBar.show(
            context,
            'Share link deleted successfully',
            SnackBarType.success,
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      FlutterBugfender.sendIssue(
        e.toString(),
        StackTrace.current.toString(),
      );

      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error deleting share link: $e',
          SnackBarType.error,
        );
      }
    }
  }

  Future<void> _shareVoiceNote(VoiceNoteModel voiceNote) async {
    try {
      // Check if voice note is already shared
      final shareStatus =
          await VoiceNoteShareRepository.getShareStatus(voiceNote.voiceNoteId!);

      if (shareStatus.enabled && shareStatus.shareUrl.isNotEmpty) {
        // Voice note is already shared, show existing share options
        _showShareOptionsDialog(voiceNote, shareStatus.shareUrl);
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Preparing voice note for sharing...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      );

      // Enable sharing and get the share URL
      final shareUrl = await VoiceNoteShareRepository.enableShare(voiceNote);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show share options dialog
      if (mounted) {
        _showShareOptionsDialog(voiceNote, shareUrl);
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      FlutterBugfender.sendIssue(
        e.toString(),
        StackTrace.current.toString(),
      );

      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error sharing voice note: $e',
          SnackBarType.error,
        );
      }
    }
  }

  void _showVoiceNoteSettingsBottomSheet(
      BuildContext context, VoiceNoteModel voiceNote) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LineIcons.cog,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Voice Note Settings',
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
            ),
            const SizedBox(height: 24),

            // Settings options based on share status
            FutureBuilder<SharedVoiceNoteStatus>(
              future: VoiceNoteShareRepository.getShareStatus(
                  voiceNote.voiceNoteId!),
              builder: (context, snapshot) {
                final isShared = snapshot.data?.enabled ?? false;

                return Column(
                  children: [
                    if (isShared) ...[
                      // Voice note is shared - show View Share Link and Delete Share
                      _buildSettingsOption(
                        context,
                        LineIcons.eye,
                        'View Share Link',
                        'Open the share link for this voice note',
                        () async {
                          Navigator.of(context).pop();
                          await _viewShareLink(voiceNote);
                        },
                        isDestructive: false,
                      ),

                      _buildSettingsOption(
                        context,
                        LineIcons.link,
                        'Delete Share',
                        'Remove the share link for this voice note',
                        () async {
                          Navigator.of(context).pop();
                          await _deleteShare(voiceNote);
                        },
                        isDestructive: true,
                      ),
                    ] else ...[
                      // Voice note is not shared - show Share Voice Note
                      _buildSettingsOption(
                        context,
                        LineIcons.share,
                        'Share Voice Note',
                        'Create a shareable link for this voice note',
                        () async {
                          Navigator.of(context).pop();
                          await _shareVoiceNote(voiceNote);
                        },
                        isDestructive: false,
                      ),
                    ],
                    _buildSettingsOption(
                      context,
                      LineIcons.trash,
                      'Delete Voice Note',
                      'Permanently delete this voice note',
                      () {
                        Navigator.of(context).pop();
                        _showDeleteConfirmation(voiceNote);
                      },
                      isDestructive: true,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    required bool isDestructive,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? colorScheme.error : colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: colorScheme.onSurface.withOpacity(0.7),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LineIcons.chevronRight,
                  color: colorScheme.onSurface.withOpacity(0.4),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showShareOptionsDialog(VoiceNoteModel voiceNote, String shareUrl) {
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
                      voiceNote.voiceNoteTitle,
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
                        '🎤 Check out my voice note: "${voiceNote.voiceNoteTitle}"\n\n$shareUrl',
                        subject: 'Voice Note: ${voiceNote.voiceNoteTitle}',
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
            const SizedBox(height: 12),

            // Additional sharing options
            Row(
              children: [
                Expanded(
                  child: _buildShareButton(
                    context,
                    'WhatsApp',
                    LineIcons.comments,
                    () async {
                      Navigator.of(context).pop();
                      final message =
                          '🎤 Check out my voice note: "${voiceNote.voiceNoteTitle}"\n\n$shareUrl';
                      await Share.share(
                        message,
                        subject: 'Voice Note: ${voiceNote.voiceNoteTitle}',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildShareButton(
                    context,
                    'Email',
                    LineIcons.envelope,
                    () async {
                      Navigator.of(context).pop();
                      await Share.share(
                        '🎤 Check out my voice note: "${voiceNote.voiceNoteTitle}"\n\n$shareUrl',
                        subject: 'Voice Note: ${voiceNote.voiceNoteTitle}',
                      );
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

  Widget _buildMetadataRow(BuildContext context, VoiceNoteModel voiceNote) {
    return Row(
      children: [
        _buildMetadataChip(
          context,
          LineIcons.clock,
          voiceNote.formattedDuration,
        ),
        const SizedBox(width: 8.0),
        _buildMetadataChip(
          context,
          LineIcons.calendar,
          _formatDate(voiceNote.createdAt),
        ),
      ],
    );
  }

  Widget _buildMetadataChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 6.0),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? colorScheme.error : colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: color,
          size: 20,
        ),
        tooltip: tooltip,
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    String title,
    IconData icon,
    Widget child,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8.0),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        child,
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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

  String _formatDetailedDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;

    return '$day $month $year at $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: "Voice Notes",
        showTitle: true,
        showBackButton: false,
        actions: [
          if (_voiceNotes.isNotEmpty)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: IconButton(
                key: ValueKey(_isSearching),
                icon: Icon(
                  _isSearching ? LineIcons.times : LineIcons.search,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      _filteredVoiceNotes = _voiceNotes;
                      _searchQuery = '';
                    }
                  });
                },
                tooltip: _isSearching ? 'Close Search' : 'Search Voice Notes',
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced Search bar with animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isSearching ? 70 : 0,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _isSearching
                ? Container(
                    margin: const EdgeInsets.only(top: 16.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.surfaceVariant.withOpacity(0.4),
                            theme.colorScheme.surfaceVariant.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _searchVoiceNotes,
                        autofocus: true,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by title or description...',
                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              LineIcons.search,
                              color: theme.colorScheme.primary,
                              size: 22,
                            ),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        _searchController.clear();
                                        _searchVoiceNotes('');
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          LineIcons.times,
                                          color: theme.colorScheme.primary,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Search results counter
          if (_isSearching && _filteredVoiceNotes.isNotEmpty)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.1),
                          theme.colorScheme.primary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LineIcons.search,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_filteredVoiceNotes.length} result${_filteredVoiceNotes.length == 1 ? '' : 's'} found',
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
            ),

          // Voice notes list
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading voice notes...',
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredVoiceNotes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      theme.colorScheme.primary
                                          .withOpacity(0.1),
                                      theme.colorScheme.primary
                                          .withOpacity(0.05),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _voiceNotes.isEmpty
                                      ? LineIcons.microphone
                                      : LineIcons.search,
                                  size: 56,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 32.0),
                              Text(
                                _voiceNotes.isEmpty
                                    ? 'No Voice Notes Yet'
                                    : 'No Results Found',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                  fontFamily: 'Poppins',
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12.0),
                              Text(
                                _voiceNotes.isEmpty
                                    ? 'Tap the microphone button to record your first voice note and start building your audio collection.'
                                    : 'Try adjusting your search terms or clear the search to see all voice notes.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                  fontFamily: 'Poppins',
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_isSearching) ...[
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'Tip: Search by title or description',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: theme.colorScheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _filteredVoiceNotes.length,
                        itemBuilder: (context, index) {
                          final voiceNote = _filteredVoiceNotes[index];
                          return VoiceNoteCard(
                            voiceNote: voiceNote,
                            onTap: () => _showVoiceNoteDetails(voiceNote),
                            onDelete: () => _showDeleteConfirmation(voiceNote),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _showRecordingModal,
          icon: const Icon(LineIcons.microphone),
          label: const Text(
            'Record',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
