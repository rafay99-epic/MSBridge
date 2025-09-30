// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:http/http.dart' as http;

// Project imports:
import 'package:msbridge/config/config.dart' as config;

class ShortLinkService {
  static const Duration _timeout = Duration(seconds: 8);
  static const int _maxAttempts = 2;

  static String get _baseUrl => config.UpdateConfig.mode == 'production'
      ? config.LinkShortenerConfig.prodBaseUrl
      : config.LinkShortenerConfig.devBaseUrl;
  static String get _endpoint => config.LinkShortenerConfig.shortenEndpoint;

  static Future<String> generateShortLink({
    required String type, // 'note' | 'voice'
    required String shareId,
    required String originalUrl,
  }) async {
    final Uri url = Uri.parse('$_baseUrl$_endpoint');
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
      'x-api-key': config.UpdateConfig.msBridgeApiKey,
    };
    final Map<String, Object?> payload = <String, Object?>{
      'shareId': shareId,
      'type': type,
      'originalUrl': originalUrl,
    };

    int attempt = 0;
    while (attempt < _maxAttempts) {
      attempt += 1;
      try {
        final http.Response res = await http
            .post(url, headers: headers, body: jsonEncode(payload))
            .timeout(_timeout);
        if (res.statusCode == 200) {
          final Object? decoded = jsonDecode(res.body);
          if (decoded is Map && decoded['shortUrl'] is String) {
            return decoded['shortUrl'] as String;
          }
          FlutterBugfender.error('Shorten API: unexpected body ${res.body}');
          return originalUrl;
        }
        FlutterBugfender.error(
            'Shorten API failed: ${res.statusCode} ${res.body}');
      } catch (e) {
        FlutterBugfender.error('Shorten API attempt $attempt failed: $e');
        if (attempt >= _maxAttempts) break;
      }
    }
    return originalUrl;
  }
}
