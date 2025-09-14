import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
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

    // Validate config/API key before starting upload
    if (UploadThingConfig.apiKey.isEmpty) {
      _error = 'Upload configuration is invalid';
      FlutterBugfender.error('Upload configuration is invalid');
      notifyListeners();
      return null;
    }

    // Clear stale URL and set upload state
    _lastUrl = null;
    _isUploading = true;
    _error = null;
    _progress = 0.1; // Start indicator
    notifyListeners();

    try {
      final url = await _service.uploadImageFile(file);

      // Validate that the returned URL is non-empty
      if (url.isEmpty) {
        _progress = 0.0;
        _error = 'Upload failed: Empty URL returned from service';
        _lastUrl = null;
        FlutterBugfender.error(
            'UploadThingProvider.uploadImage failed: Empty URL returned');
        return null;
      }

      _lastUrl = url;
      _progress = 1.0;
      notifyListeners();
      return url;
    } catch (e) {
      _progress = 0.0;
      _error = e.toString();
      _lastUrl = null;
      FlutterBugfender.error(
        'UploadThingProvider.uploadImage failed: $e',
      );
      FlutterBugfender.sendCrash('UploadThingProvider.uploadImage failed: $e',
          StackTrace.current.toString());
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<String?> uploadAudio(File file) async {
    if (_isUploading) {
      _error = 'An upload is already in progress';
      notifyListeners();
      return null;
    }

    // Validate config/API key before starting upload
    if (UploadThingConfig.apiKey.isEmpty) {
      _error = 'Upload configuration is invalid';
      FlutterBugfender.error('Upload configuration is invalid');
      notifyListeners();
      return null;
    }

    // Clear stale URL and set upload state
    _lastUrl = null;
    _isUploading = true;
    _error = null;
    _progress = 0.1; // Start indicator
    notifyListeners();

    try {
      final url = await _service.uploadAudioFile(file);

      // Validate that the returned URL is non-empty
      if (url.isEmpty) {
        _progress = 0.0;
        _error = 'Upload failed: Empty URL returned from service';
        _lastUrl = null;
        FlutterBugfender.error(
            'UploadThingProvider.uploadAudio failed: Empty URL returned');
        return null;
      }

      _lastUrl = url;
      _progress = 1.0;
      notifyListeners();
      return url;
    } catch (e) {
      _progress = 0.0;
      _error = e.toString();
      _lastUrl = null;
      FlutterBugfender.error(
        'UploadThingProvider.uploadAudio failed: $e',
      );
      FlutterBugfender.sendCrash('UploadThingProvider.uploadAudio failed: $e',
          StackTrace.current.toString());
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
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
