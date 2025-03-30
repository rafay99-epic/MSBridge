import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_quill/quill_delta.dart';

Future<String> encodeContent(Delta delta) async {
  return await compute(encodeContentInIsolate, delta);
}

String encodeContentInIsolate(Delta delta) {
  return jsonEncode(delta.toJson());
}
