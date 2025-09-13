import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:msbridge/config/config.dart';

class UpdateService {
  static const String _baseUrl = UpdateConfig.apiUrl;
  static const String _msBridgeApiKey = UpdateConfig.msBridgeApiKey;

  /// Check if the system is live
  static Future<bool> isSystemLive() async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': _msBridgeApiKey,
      };

      FlutterBugfender.log('Health check request to: $_baseUrl/health');
      FlutterBugfender.log('Headers: $headers');
      FlutterBugfender.log('API Key length: ${_msBridgeApiKey.length}');

      final response = await http
          .get(
            Uri.parse('$_baseUrl/health'),
            headers: headers,
          )
          .timeout(UpdateConfig.healthCheckTimeout);

      FlutterBugfender.log(
          'Health check response status: ${response.statusCode}');
      FlutterBugfender.log('Health check response body: ${response.body}');

      if (response.statusCode == 200) {
        FlutterBugfender.log('Health check successful: $_baseUrl');
        return true;
      }

      FlutterBugfender.error(
          'Health check failed with status: ${response.statusCode}');
      return false;
    } catch (e) {
      FlutterBugfender.error('Health check error: $e');
      return false;
    }
  }

  /// Check for app updates
  static Future<UpdateCheckResult> checkForUpdates() async {
    try {
      // Get current app version info
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final buildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      FlutterBugfender.log(
          'Checking for updates - Current version: $currentVersion ($buildNumber)');

      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': _msBridgeApiKey,
      };

      final requestBody = {
        'version': currentVersion,
        'buildNumber': buildNumber,
      };

      FlutterBugfender.log('Update check request to: $_baseUrl/update-check');
      FlutterBugfender.log('Headers: $headers');
      FlutterBugfender.log('Request body: $requestBody');
      FlutterBugfender.log('API Key length: ${_msBridgeApiKey.length}');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/update-check'),
            headers: headers,
            body: json.encode(requestBody),
          )
          .timeout(UpdateConfig.updateCheckTimeout);

      FlutterBugfender.log(
          'Update check response status: ${response.statusCode}');
      FlutterBugfender.log('Update check response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        FlutterBugfender.log('Update check successful: $_baseUrl');
        return UpdateCheckResult.fromJson(data);
      } else {
        FlutterBugfender.error(
            'Update check failed with status: ${response.statusCode}');
        FlutterBugfender.error('Response body: ${response.body}');
        throw Exception(
            'Update check failed with status: ${response.statusCode}');
      }
    } catch (e) {
      FlutterBugfender.error('Error checking for updates: $e');
      return UpdateCheckResult.error('Failed to check for updates: $e');
    }
  }
}

/// Model class for update check results
class UpdateCheckResult {
  final bool isLive;
  final bool updateAvailable;
  final String? message;
  final AppVersion? latestVersion;
  final AppVersion? currentVersion;
  final String? error;

  UpdateCheckResult({
    required this.isLive,
    required this.updateAvailable,
    this.message,
    this.latestVersion,
    this.currentVersion,
    this.error,
  });

  factory UpdateCheckResult.fromJson(Map<String, dynamic> json) {
    final latestVersion = json['latestVersion'] != null
        ? AppVersion.fromJson(json['latestVersion'])
        : null;
    final currentVersion = json['currentVersion'] != null
        ? AppVersion.fromJson(json['currentVersion'])
        : null;

    // Client-side version comparison for edge cases
    bool updateAvailable = json['updateAvailable'] ?? false;
    String? message = json['message'];

    if (latestVersion != null && currentVersion != null) {
      final versionComparison =
          _compareVersions(currentVersion.version, latestVersion.version);

      if (versionComparison > 0) {
        // Current version is higher than server's latest version
        updateAvailable = false;
        message =
            'You have a newer version (${currentVersion.version}) than what\'s available on the server (${latestVersion.version}). You\'re up to date!';
        FlutterBugfender.log(
            'Client has newer version: ${currentVersion.version} > ${latestVersion.version}');
      } else if (versionComparison < 0) {
        // Current version is lower than server's latest version
        updateAvailable = true;
        message = 'A new version ${latestVersion.version} is available!';
        FlutterBugfender.log(
            'Update available: ${currentVersion.version} < ${latestVersion.version}');
      } else {
        // Versions are equal
        updateAvailable = false;
        message = 'You have the latest version!';
        FlutterBugfender.log(
            'Versions are equal: ${currentVersion.version} = ${latestVersion.version}');
      }
    }

    return UpdateCheckResult(
      isLive: json['status'] == 'live',
      updateAvailable: updateAvailable,
      message: message,
      latestVersion: latestVersion,
      currentVersion: currentVersion,
    );
  }

  /// Compare two version strings (e.g., "7.10.0" vs "7.9.0")
  /// Returns: 1 if version1 > version2, -1 if version1 < version2, 0 if equal
  static int _compareVersions(String version1, String version2) {
    try {
      final v1Parts = version1.split('.').map(int.parse).toList();
      final v2Parts = version2.split('.').map(int.parse).toList();

      // Pad with zeros to make both lists the same length
      while (v1Parts.length < v2Parts.length) {
        v1Parts.add(0);
      }
      while (v2Parts.length < v1Parts.length) {
        v2Parts.add(0);
      }

      for (int i = 0; i < v1Parts.length; i++) {
        if (v1Parts[i] > v2Parts[i]) return 1;
        if (v1Parts[i] < v2Parts[i]) return -1;
      }

      return 0;
    } catch (e) {
      FlutterBugfender.error(
          'Error comparing versions "$version1" vs "$version2": $e');
      // If parsing fails, do string comparison as fallback
      return version1.compareTo(version2);
    }
  }

  factory UpdateCheckResult.error(String errorMessage) {
    return UpdateCheckResult(
      isLive: false,
      updateAvailable: false,
      error: errorMessage,
    );
  }

  bool get hasError => error != null;
}

/// Model class for app version information
class AppVersion {
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final String? changelog;
  final String releaseDate;

  AppVersion({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    this.changelog,
    required this.releaseDate,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      version: json['version'] ?? '',
      buildNumber: json['buildNumber'] ?? 0,
      downloadUrl: json['downloadUrl'] ?? '',
      changelog: json['changelog'],
      releaseDate: json['releaseDate'] ?? '',
    );
  }
}
