import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/database/note_taking/note_version.dart';
import 'package:msbridge/core/provider/note_version_provider.dart';
import 'package:msbridge/core/utils/version_download_utils.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/features/notes_taking/widget/build_content.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VersionHistoryScreen extends StatefulWidget {
  final NoteTakingModel note;

  const VersionHistoryScreen({super.key, required this.note});

  @override
  State<VersionHistoryScreen> createState() => _VersionHistoryScreenState();
}

class _VersionHistoryScreenState extends State<VersionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load versions when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final versionProvider =
          Provider.of<NoteVersionProvider>(context, listen: false);
      versionProvider.loadVersions(widget.note.noteId!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(
        title: "Version History",
        backbutton: true,
      ),
      backgroundColor: colorScheme.surface,
      body: Consumer<NoteVersionProvider>(
        builder: (context, versionProvider, child) {
          if (versionProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (versionProvider.error != null) {
            return _buildErrorState(theme, colorScheme, versionProvider);
          }

          return Column(
            children: [
              _buildCurrentVersionHeader(theme, colorScheme),
              Expanded(
                child: versionProvider.hasVersions()
                    ? _buildVersionTimeline(theme, colorScheme, versionProvider)
                    : _buildEmptyState(theme, colorScheme),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentVersionHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LineIcons.edit,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Current Version (v${widget.note.versionNumber})",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Last updated: ${DateFormat('MMM dd, yyyy HH:mm').format(widget.note.updatedAt)}",
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Created: ${DateFormat('MMM dd, yyyy HH:mm').format(widget.note.createdAt)}",
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.primary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LineIcons.history,
            size: 64,
            color: colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "No versions yet",
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Versions will appear here when you edit this note",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, ColorScheme colorScheme,
      NoteVersionProvider versionProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LineIcons.exclamationTriangle,
            size: 64,
            color: colorScheme.error.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "Error loading versions",
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            versionProvider.error ?? "Unknown error occurred",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.error.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              versionProvider.clearError();
              versionProvider.loadVersions(widget.note.noteId!);
            },
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionTimeline(ThemeData theme, ColorScheme colorScheme,
      NoteVersionProvider versionProvider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: versionProvider.versions.length,
      itemBuilder: (context, index) {
        final version = versionProvider.versions[index];
        final isLast = index == versionProvider.versions.length - 1;
        return _buildVersionTimelineItem(version, theme, colorScheme, isLast);
      },
    );
  }

  Widget _buildVersionTimelineItem(NoteVersion version, ThemeData theme,
      ColorScheme colorScheme, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line and dot
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: colorScheme.primary.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),

        // Version content
        Expanded(
          child: _buildVersionCard(version, theme, colorScheme),
        ),
      ],
    );
  }

  Widget _buildVersionCard(
      NoteVersion version, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Version header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "v${version.versionNumber}",
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMM dd, yyyy HH:mm')
                              .format(version.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (version.changes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            version.changes.first,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Download button
                      IconButton(
                        icon: Icon(
                          LineIcons.download,
                          color: colorScheme.secondary,
                          size: 20,
                        ),
                        onPressed: () => _downloadVersion(version),
                        tooltip: 'Download version',
                      ),
                      // Restore button
                      IconButton(
                        icon: Icon(
                          LineIcons.undo,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        onPressed: () => _showRestoreConfirmation(
                            version, theme, colorScheme),
                        tooltip: 'Restore this version',
                      ),
                      // Preview button
                      IconButton(
                        icon: Icon(
                          LineIcons.eye,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        onPressed: () =>
                            _showVersionPreview(version, theme, colorScheme),
                        tooltip: 'Preview version',
                      ),
                    ],
                  ),
                ],
              ),

              // Changes summary
              if (version.changes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.secondary.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "What changed:",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...version.changes.map((change) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  LineIcons.checkCircle,
                                  size: 14,
                                  color: colorScheme.secondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    change,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],

              // Tags if any
              if (version.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: version.tags
                      .map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tag,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.secondary,
                                fontSize: 10,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showVersionPreview(
      NoteVersion version, ThemeData theme, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 400,
            maxHeight: 600,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "v${version.versionNumber}",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Version ${version.versionNumber}",
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            DateFormat('MMM dd, yyyy HH:mm')
                                .format(version.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.primary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Changes summary
                      if (version.changes.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.secondary.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    LineIcons.infoCircle,
                                    color: colorScheme.secondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Changes in this version",
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: colorScheme.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...version.changes.map((change) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          LineIcons.checkCircle,
                                          size: 16,
                                          color: colorScheme.secondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            change,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: colorScheme.secondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Title Section
                      Text(
                        "Title",
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          version.noteTitle,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Content Section
                      Text(
                        "Content",
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: buildContent(version.noteContent, theme),
                      ),

                      // Tags Section
                      if (version.tags.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          "Tags",
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: version.tags
                              .map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondary
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: colorScheme.secondary
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.secondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Close",
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Download a specific version as a JSON file
  void _downloadVersion(NoteVersion version) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading version...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Download the version
      final filePath =
          await VersionDownloadUtils.downloadVersionAsJson(version);

      // Show success message with user-friendly location
      if (mounted) {
        final userFriendlyLocation =
            VersionDownloadUtils.getUserFriendlyPath(filePath);
        final fileName = filePath.split('/').last;
        CustomSnackBar.show(
          context,
          'Version downloaded successfully!\nFile: $fileName\nLocation: $userFriendlyLocation',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error downloading version: $e',
          isSuccess: false,
        );
      }
    }
  }

  /// Show confirmation dialog for restoring a version
  void _showRestoreConfirmation(
      NoteVersion version, ThemeData theme, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Restore Version ${version.versionNumber}?',
          style: TextStyle(color: colorScheme.primary),
        ),
        content: Text(
          'This will create a new note with the content from version ${version.versionNumber}. '
          'The original note will remain unchanged.\n\n'
          'Are you sure you want to proceed?',
          style: TextStyle(color: colorScheme.primary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restoreVersion(version);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  /// Restore a note from a specific version
  void _restoreVersion(NoteVersion version) async {
    try {
      final versionProvider =
          Provider.of<NoteVersionProvider>(context, listen: false);

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restoring version...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Restore the version
      final success = await versionProvider.restoreNoteFromVersion(
        version,
        widget.note.userId,
      );

      if (success && mounted) {
        CustomSnackBar.show(
          context,
          'Note restored successfully from version ${version.versionNumber}!',
          isSuccess: true,
        );

        // Navigate back to notes list
        Navigator.pop(context);
      } else if (mounted) {
        CustomSnackBar.show(
          context,
          'Error restoring note: ${versionProvider.error}',
          isSuccess: false,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error restoring note: $e',
          isSuccess: false,
        );
      }
    }
  }
}
