// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:line_icons/line_icons.dart';

// Project imports:
import 'package:msbridge/config/config.dart';
import 'package:msbridge/core/repo/update_app_repo.dart';
import 'package:msbridge/features/update_app/widget/build_download_progress_card.dart';
import 'package:msbridge/features/update_app/widget/build_status_card.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';

class UpdateApp extends StatefulWidget {
  const UpdateApp({super.key});

  @override
  State<UpdateApp> createState() => _UpdateAppState();
}

enum ReleaseType {
  main,
  beta,
}

class _UpdateAppState extends State<UpdateApp> {
  String mainApkUrl = APKFile.apkFile;
  String betaApkUrl = APKFile.betaApkFile;
  late UpdateAppRepo _updateAppRepo;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _errorMessage = '';
  ReleaseType _selectedReleaseType = ReleaseType.main;
  bool _downloadCompleted = false;

  @override
  void initState() {
    super.initState();
    _updateAppRepo = UpdateAppRepo(apkUrl: getApkUrl());
  }

  @override
  void dispose() {
    // Ensure proper cleanup to prevent memory leaks
    if (_isDownloading) {
      _updateAppRepo.cancelDownload();
    }
    super.dispose();
  }

  String getApkUrl() {
    return _selectedReleaseType == ReleaseType.main ? mainApkUrl : betaApkUrl;
  }

  Future<void> _downloadApk() async {
    setState(() {
      _errorMessage = '';
      _downloadCompleted = false;
      _updateAppRepo = UpdateAppRepo(apkUrl: getApkUrl());
    });

    await _updateAppRepo.downloadAndInstallApk(
      context,
      (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
          });
        }
      },
      (isDownloading) {
        if (mounted) {
          setState(() {
            _isDownloading = isDownloading;
          });
        }
      },
      () {
        if (mounted) {
          setState(() {
            _downloadCompleted = true;
          });
          CustomSnackBar.show(
            context,
            "APK Downloaded Successfully! Check your Downloads folder.",
            isSuccess: true,
          );
        }
      },
      (error) {
        if (mounted) {
          setState(() {
            _errorMessage = error;
          });
          CustomSnackBar.show(
            context,
            "Error: $error",
            isSuccess: false,
          );
        }
      },
    );
  }

  void _cancelDownload() {
    _updateAppRepo.cancelDownload();
    if (mounted) {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(
        title: "Download Update",
        backbutton: true,
        showTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Main Update Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme
                    .surfaceContainerHighest, // Match search screen color
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary
                      .withValues(alpha: 0.3), // Prominent border
                  width: 2, // Thicker border
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow
                        .withValues(alpha: 0.2), // Enhanced shadow
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Update Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.primary
                          .withValues(alpha: 0.15), // More prominent
                      shape: BoxShape.circle,
                      border: Border.all(
                        // Add border to icon container
                        color: colorScheme.primary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      LineIcons.download,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    "MS Bridge Update",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    "Download the latest APK and install manually for the newest features and improvements.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Release Type Selector
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select Release Type:",
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ReleaseType>(
                          initialValue: _selectedReleaseType,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: ReleaseType.main,
                              child: Text('Main Release (Stable)'),
                            ),
                            DropdownMenuItem(
                              value: ReleaseType.beta,
                              child: Text('Beta Release (Latest Features)'),
                            ),
                          ],
                          onChanged: (ReleaseType? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedReleaseType = newValue;
                                _updateAppRepo =
                                    UpdateAppRepo(apkUrl: getApkUrl());
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Status Cards
            if (_errorMessage.isNotEmpty) ...[
              buildStatusCard(
                context,
                colorScheme,
                theme,
                isError: true,
                title: "Download Error",
                message: _errorMessage,
                icon: LineIcons.exclamationTriangle,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
            ],

            if (_downloadCompleted) ...[
              buildStatusCard(
                context,
                colorScheme,
                theme,
                isError: false,
                title: "Download Complete!",
                message:
                    "APK saved to Downloads folder.\nOpen the file to install manually.",
                icon: LineIcons.checkCircle,
                color: Colors.green,
              ),
              const SizedBox(height: 20),
            ],

            if (_isDownloading) ...[
              buildDownloadProgressCard(context, colorScheme, theme,
                  _downloadProgress, _cancelDownload),
              const SizedBox(height: 20),
            ],

            // Download Button
            if (!_isDownloading && !_downloadCompleted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(LineIcons.download, color: colorScheme.onPrimary),
                  label: Text(
                    "Download APK",
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  onPressed: _downloadApk,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
