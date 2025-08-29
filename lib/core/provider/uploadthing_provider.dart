import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:msbridge/core/services/upload/uploadthing_service.dart';
import 'package:msbridge/config/config.dart';

class UploadThingProvider extends ChangeNotifier {
  UploadThingProvider()
      : _service = UploadThingService(apiKey: UploadThingConfig.apiKey);

  final UploadThingService _service;

  bool _isUploading = false;
  double _progress = 0.0;
  String? _lastUrl;
  String? _error;

  bool get isUploading => _isUploading;
  double get progress => _progress;
  String? get lastUrl => _lastUrl;
  String? get error => _error;

  Future<String?> uploadImage(File file) async {
    if (_isUploading) {
      _error = 'An upload is already in progress';
      notifyListeners();
      return null;
    }
    _isUploading = true;
    _error = null;
    _progress = 0.1; // Start indicator
    notifyListeners();
    try {
      final url = await _service.uploadImageFile(file);
      _lastUrl = url;
      _progress = 1.0;
      notifyListeners();
      return url;
    } catch (e, stackTrace) {
      _progress = 0.0;
      _error = e.toString();
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'UploadThingProvider.uploadImage failed',
      );
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }
  }

  void clear() {
    _isUploading = false;
    _progress = 0.0;
    _lastUrl = null;
    _error = null;
    notifyListeners();
  }
}
