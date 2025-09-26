import 'dart:convert';

import 'package:flutter_bugfender/flutter_bugfender.dart';

bool isQuillJson(String content) {
  try {
    final dynamic parsed = jsonDecode(content);
    if (parsed is List) return true;
    if (parsed is Map && parsed['ops'] is List) return true;
    return false;
  } catch (e) {
    FlutterBugfender.sendCrash('Error checking if content is quill json: $e',
        StackTrace.current.toString());
    return false;
  }
}
