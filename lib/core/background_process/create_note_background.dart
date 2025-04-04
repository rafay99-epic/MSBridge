import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/quill_delta.dart';

Future<String> encodeContent(Delta delta) async {
  try {
    return await compute(encodeContentInIsolate, delta);
  } catch (e) {
    return "Error encoding content: $e";
  }
}

String encodeContentInIsolate(Delta delta) {
  try {
    return jsonEncode(delta.toJson());
  } catch (e) {
    return "Error encoding content in isolate: $e";
  }
}
