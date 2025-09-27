import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:msbridge/core/services/update_app/update_service.dart';
import 'package:msbridge/core/services/update_app/background_download_service.dart';
import 'package:msbridge/widgets/snakbar.dart';

class EnhancedUpdateDialog extends StatefulWidget {
  final UpdateCheckResult updateResult;
  final VoidCallback? onDismiss;

  const EnhancedUpdateDialog({
    super.key,
    required this.updateResult,
    this.onDismiss,
  });

  @override
  State<EnhancedUpdateDialog> createState() => _EnhancedUpdateDialogState();
}

class _EnhancedUpdateDialogState extends State<EnhancedUpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
  }

  Future<void> _checkDownloadStatus() async {
    if (BackgroundDownloadService.isDownloadInProgress()) {
      final progress = BackgroundDownloadService.getDownloadProgress();
      setState(() {
        _isDownloading = true;
        _downloadProgress = progress;
        _downloadStatus = BackgroundDownloadService.getDownloadStatus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: !_isDownloading,
      child: AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient background
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.1),
                      colorScheme.primary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Update icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.system_update,
                        size: 32,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Update Available!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A new version of MS Bridge is ready',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Version comparison
                    _buildVersionComparison(theme, colorScheme),

                    const SizedBox(height: 20),

                    // Changelog section
                    if (widget.updateResult.latestVersion?.changelog !=
                        null) ...[
                      _buildChangelogSection(theme, colorScheme),
                      const SizedBox(height: 20),
                    ],

                    // Download progress (if downloading)
                    if (_isDownloading) ...[
                      _buildDownloadProgress(theme, colorScheme),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),

              // Action buttons
              _buildActionButtons(theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionComparison(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Version',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'v${widget.updateResult.currentVersion?.version ?? 'Unknown'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest Version',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'v${widget.updateResult.latestVersion?.version ?? 'Unknown'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChangelogSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.new_releases,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'What\'s New',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            widget.updateResult.latestVersion!.changelog!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadProgress(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.download,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Downloading Update',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _downloadProgress,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_downloadProgress * 100).toInt()}% - $_downloadStatus',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        children: [
          if (!_isDownloading) ...[
            Expanded(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onDismiss?.call();
                },
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface.withValues(alpha: 0.7),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Later'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _startDownload(context),
                icon: const Icon(Icons.download, size: 20),
                label: const Text('Update Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: TextButton.icon(
                onPressed: _pauseDownload,
                icon: const Icon(Icons.pause, size: 20),
                label: const Text('Pause'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextButton.icon(
                onPressed: _cancelDownload,
                icon: const Icon(Icons.cancel, size: 20),
                label: const Text('Cancel'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startDownload(BuildContext context) async {
    if (widget.updateResult.latestVersion?.downloadUrl == null) {
      CustomSnackBar.show(context, 'Download URL not available',
          isSuccess: false);
      return;
    }

    // Close dialog immediately and start background download
    Navigator.of(context).pop();

    // Show initial snackbar
    CustomSnackBar.show(
      context,
      'Download started! Check notifications for progress.',
      isSuccess: true,
    );

    try {
      final success = await BackgroundDownloadService.downloadApk(
        context,
        widget.updateResult.latestVersion!,
        onProgress: (progress) {
          // Progress is now handled by notifications
        },
        onStatus: (status) {
          // Status is now handled by notifications
        },
      );

      if (!success) {
        if (context.mounted) {
          CustomSnackBar.show(
            context,
            'Failed to start download. Please try again.',
            isSuccess: false,
          );
        }
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to start download: $e', StackTrace.current.toString());
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          'Download error: $e',
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _pauseDownload() async {
    await BackgroundDownloadService.pauseDownload();
    setState(() {
      _downloadStatus = 'Download paused';
    });
  }

  Future<void> _cancelDownload() async {
    await BackgroundDownloadService.cancelDownload();
    setState(() {
      _isDownloading = false;
      _downloadProgress = 0.0;
      _downloadStatus = '';
    });
  }
}
