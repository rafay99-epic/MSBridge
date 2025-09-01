import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:flutter_quill/quill_delta.dart';

Future<String> encodeContent(Delta delta) async {
  try {
    return await compute(encodeContentInIsolate, delta);
  } catch (e) {
    FlutterBugfender.error('Error encoding content: $e');
    FlutterBugfender.sendCrash(
        'Error encoding content: $e', StackTrace.current.toString());
    return "Error encoding content: $e";
  }
}

String encodeContentInIsolate(Delta delta) {
  try {
    return jsonEncode(delta.toJson());
  } catch (e) {
    FlutterBugfender.error('Error encoding content in isolate: $e');
    FlutterBugfender.sendCrash(
        'Error encoding content in isolate: $e', StackTrace.current.toString());
    return "Error encoding content in isolate: $e";
  }
}
