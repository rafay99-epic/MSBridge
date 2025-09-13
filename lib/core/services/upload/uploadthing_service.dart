import 'dart:io';
import 'dart:convert';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:uploadthing/uploadthing.dart';

class UploadThingService {
  UploadThingService({required String apiKey})
      : _client = UploadThing(_normalizeKey(apiKey));

  final UploadThing _client;

  Future<String> uploadImageFile(File file) async {
    try {
      final bool ok = await _client.uploadFiles([file]);
      if (!ok || _client.uploadedFilesData.isEmpty) {
        throw Exception('Upload failed with no response');
      }
      final dynamic first = _client.uploadedFilesData.first;
      final String? url = first is Map<String, dynamic>
          ? (first['url'] as String?)
          : first['url'];
      if (url == null || url.isEmpty) {
        throw Exception('Upload returned empty URL');
      }
      return url;
    } catch (e) {
      FlutterBugfender.error('UploadThing uploadImageFile failed: $e');

      rethrow;
    }
  }

  // Add audio file upload method
  Future<String> uploadAudioFile(File file) async {
    try {
      final bool ok = await _client.uploadFiles([file]);
      if (!ok || _client.uploadedFilesData.isEmpty) {
        throw Exception('Upload failed with no response');
      }
      final dynamic first = _client.uploadedFilesData.first;
      final String? url = first is Map<String, dynamic>
          ? (first['url'] as String?)
          : first['url'];
      if (url == null || url.isEmpty) {
        throw Exception('Upload returned empty URL');
      }
      return url;
    } catch (e) {
      FlutterBugfender.error('UploadThing uploadAudioFile failed: $e');
      rethrow;
    }
  }

  Future<List<Map<String, String>>> listRecent({int limit = 10}) async {
    try {
      final files = await _client.listFiles(limit: limit);
      return files
          .map((f) => {
                'key': f.key,
                'name': f.name,
                'url': _client.getFileUrl(f.key),
              })
          .toList(growable: false);
    } catch (e, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'UploadThing listRecent failed',
      );
      rethrow;
    }
  }
}

String _normalizeKey(String input) {
  try {
    if (input.startsWith('sk_')) return input;
    // Try base64 decode
    final decoded = utf8.decode(base64.decode(input));
    final dynamic json = jsonDecode(decoded);
    if (json is Map && json['apiKey'] is String) {
      final String key = json['apiKey'] as String;
      return key;
    }
  } catch (e, stackTrace) {
    FirebaseCrashlytics.instance
        .log('Failed to normalize UploadThing key: $input');
    FirebaseCrashlytics.instance.recordError(
      e,
      stackTrace,
      reason: 'Failed to normalize UploadThing key',
    );
  }
  // Fallback to original
  return input;
}
