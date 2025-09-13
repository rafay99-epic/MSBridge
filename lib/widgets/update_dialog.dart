import 'package:flutter/material.dart';
import 'package:msbridge/core/services/update_service.dart';
import 'package:msbridge/core/services/download_service.dart';
import 'package:msbridge/widgets/snakbar.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateCheckResult updateResult;
  final VoidCallback? onDismiss;

  const UpdateDialog({
    super.key,
    required this.updateResult,
    this.onDismiss,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isDownloading,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(Icons.system_update,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Update Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version of MS Bridge is available!',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (widget.updateResult.latestVersion != null) ...[
              _buildVersionInfo(
                  'Current Version', widget.updateResult.currentVersion),
              const SizedBox(height: 8),
              _buildVersionInfo(
                  'Latest Version', widget.updateResult.latestVersion),
              const SizedBox(height: 16),
              if (widget.updateResult.latestVersion!.changelog != null) ...[
                Text(
                  'What\'s New:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    widget.updateResult.latestVersion!.changelog!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.4,
                        ),
                  ),
                ),
              ],
            ],
            if (_isDownloading) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Downloading update...',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!_isDownloading) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDismiss?.call();
              },
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () => _downloadUpdate(context),
              child: const Text('Download Update'),
            ),
          ] else ...[
            TextButton(
              onPressed: null,
              child: const Text('Downloading...'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVersionInfo(String label, AppVersion? version) {
    if (version == null) return const SizedBox.shrink();

    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${version.version} (${version.buildNumber})',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _downloadUpdate(BuildContext context) async {
    if (widget.updateResult.latestVersion?.downloadUrl == null) {
      CustomSnackBar.show(context, 'Download URL not available',
          isSuccess: false);
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      final success = await DownloadService.downloadApk(
        context,
        widget.updateResult.latestVersion!,
      );

      if (success) {
        Navigator.of(context).pop();
        CustomSnackBar.show(
          context,
          'Update downloaded successfully! Check your notifications.',
          isSuccess: true,
        );
      } else {
        setState(() {
          _isDownloading = false;
        });
        CustomSnackBar.show(
          context,
          'Download failed. Please try again.',
          isSuccess: false,
        );
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      CustomSnackBar.show(
        context,
        'Download error: $e',
        isSuccess: false,
      );
    }
  }
}
