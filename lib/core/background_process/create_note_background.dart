import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

Future<String> encodeContent(Delta delta) async {
  try {
    return await compute(encodeContentInIsolate, delta);
  } catch (e) {
    FirebaseCrashlytics.instance.recordError(
      Exception('Error encoding content'),
      StackTrace.current,
      reason: 'Error encoding content: $e',
    );
    return "Error encoding content: $e";
  }
}

String encodeContentInIsolate(Delta delta) {
  try {
    return jsonEncode(delta.toJson());
  } catch (e) {
    FirebaseCrashlytics.instance.recordError(
      Exception('Error encoding content in isolate'),
      StackTrace.current,
      reason: 'Error encoding content in isolate: $e',
    );
    return "Error encoding content in isolate: $e";
  }
}
