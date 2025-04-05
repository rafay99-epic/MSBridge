import 'package:flutter/material.dart';
import 'package:msbridge/core/repo/update_app_repo.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

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
  String mainApkUrl = 'https://rafay99.com/MSBridge-APK';
  String betaApkUrl = 'https://rafay99.com/MSBridge-beta';
  late UpdateAppRepo _updateAppRepo;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _errorMessage = '';
  ReleaseType _selectedReleaseType = ReleaseType.main;

  @override
  void initState() {
    super.initState();
    _updateAppRepo = UpdateAppRepo(apkUrl: getApkUrl());
  }

  String getApkUrl() {
    return _selectedReleaseType == ReleaseType.main ? mainApkUrl : betaApkUrl;
  }

  Future<void> _downloadAndInstall() async {
    setState(() {
      _errorMessage = '';
      _updateAppRepo = UpdateAppRepo(apkUrl: getApkUrl());
    });

    await _updateAppRepo.downloadAndInstallApk(
      context,
      (progress) {
        setState(() {
          _downloadProgress = progress;
        });
      },
      (isDownloading) {
        setState(() {
          _isDownloading = isDownloading;
        });
      },
      () {
        CustomSnackBar.show(
          context,
          "APK File Downloaded Successfully",
        );
      },
      (error) {
        setState(() {
          _errorMessage = error;
        });
        CustomSnackBar.show(
          context,
          "Error: $error",
        );
      },
    );
  }

  void _cancelDownload() {
    _updateAppRepo.cancelDownload();
    setState(() {
      _isDownloading = false;
      _downloadProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const CustomAppBar(
        title: "Update MS Bridge",
        backbutton: true,
        showTitle: true,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.system_update_alt_rounded,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                "MS Bridge Update",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Get the latest features and improvements.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
              DropdownButton<ReleaseType>(
                value: _selectedReleaseType,
                items: const [
                  DropdownMenuItem(
                    value: ReleaseType.main,
                    child: Text('Main Release'),
                  ),
                  DropdownMenuItem(
                    value: ReleaseType.beta,
                    child: Text('Beta Release'),
                  ),
                ],
                onChanged: (ReleaseType? newValue) {
                  setState(() {
                    _selectedReleaseType = newValue!;
                    _updateAppRepo = UpdateAppRepo(apkUrl: getApkUrl());
                  });
                },
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),
              _isDownloading
                  ? Column(
                      children: [
                        LinearPercentIndicator(
                          width: MediaQuery.of(context).size.width * 0.7,
                          animation: true,
                          lineHeight: 14.0,
                          percent: _downloadProgress,
                          progressColor: theme.colorScheme.secondary,
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.15),
                          barRadius: const Radius.circular(8),
                          fillColor: theme.colorScheme.surface,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Downloading: ${(_downloadProgress * 100).toStringAsFixed(1)}%",
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton.icon(
                          onPressed: _cancelDownload,
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text(
                            "Cancel Download",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.download_rounded),
                      label: const Text("Download & Install"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _downloadAndInstall,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
