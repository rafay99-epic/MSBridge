import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:msbridge/config/config.dart';

class AboutAuthorApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? details;

  AboutAuthorApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() {
    if (statusCode != null && details != null) {
      return '$message (Status: $statusCode) - $details';
    } else if (statusCode != null) {
      return '$message (Status: $statusCode)';
    } else if (details != null) {
      return '$message - $details';
    }
    return message;
  }
}

class AboutAuthorApiService {
  static const String _baseUrl = APIConfig.baseURL;
  static const String _authorEndpoint = APIConfig.aboutAuthorApiEndpoint;
  static const Duration _timeout = Duration(seconds: 15);

  /// Fetches author data from the API with comprehensive error handling and Firebase Crashlytics integration
  static Future<Map<String, dynamic>> fetchAuthorData() async {
    try {
      // Log API call attempt
      FlutterBugfender.log(
          'AboutAuthor: Starting API call to $_baseUrl$_authorEndpoint');

      final response = await http.get(
        Uri.parse('$_baseUrl$_authorEndpoint'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'MSBridge/1.0',
        },
      ).timeout(
        _timeout,
        onTimeout: () {
          FlutterBugfender.log(
              'AboutAuthor: API request timed out after ${_timeout.inSeconds} seconds');
          throw AboutAuthorApiException(
            'Request timed out',
            details: 'Timeout after ${_timeout.inSeconds} seconds',
          );
        },
      );

      // Log response details
      FlutterBugfender.log(
          'AboutAuthor: API response received - Status: ${response.statusCode}, Content-Length: ${response.contentLength}');

      if (response.statusCode == 200) {
        return _parseAuthorResponse(response);
      } else {
        return _handleHttpError(response);
      }
    } on AboutAuthorApiException {
      rethrow;
    } on TimeoutException catch (e, stackTrace) {
      return _handleTimeoutError(e, stackTrace);
    } on SocketException catch (e, stackTrace) {
      return _handleSocketError(e, stackTrace);
    } catch (e, stackTrace) {
      return _handleUnexpectedError(e, stackTrace);
    }
  }

  /// Parses the successful API response
  static Map<String, dynamic> _parseAuthorResponse(http.Response response) {
    try {
      final data = json.decode(response.body);
      if (data != null && data['author'] != null) {
        // Log successful data parsing
        FlutterBugfender.log(
            'AboutAuthor: Data parsed successfully - Author name: ${data['author']['name'] ?? 'Unknown'}');

        // Validate and log any potential issues with avatar URLs
        _validateAndLogAvatarUrls(data['author']);

        return data['author'];
      } else {
        // Log invalid data structure
        FlutterBugfender.log(
            'AboutAuthor: Invalid data structure - data: $data');
        FlutterBugfender.error(
          'Invalid API response structure: $data, response: ${response.body}, status: ${response.statusCode}, error: ${response.reasonPhrase}',
        );
        throw AboutAuthorApiException(
          'Invalid data format received from server',
          details: 'Missing or null author data in response',
        );
      }
    } on FormatException catch (e) {
      // Log JSON parsing errors
      FlutterBugfender.log('AboutAuthor: JSON parsing failed - ${e.message}');
      FlutterBugfender.error(
        'Failed to parse JSON response from author API: $e',
      );
      throw AboutAuthorApiException(
        'Invalid response format from server',
        details: 'JSON parsing failed: ${e.message}',
      );
    }
  }

  /// Validates avatar URLs and logs any issues found
  static void _validateAndLogAvatarUrls(Map<String, dynamic> authorData) {
    try {
      // Check testimonials for invalid avatar URLs
      final testimonials = authorData['testimonials'] as List<dynamic>?;
      if (testimonials != null) {
        for (int i = 0; i < testimonials.length; i++) {
          final testimonial = testimonials[i];
          final avatar = testimonial['avatar']?.toString() ?? '';

          if (avatar.isNotEmpty &&
              !avatar.startsWith('http://') &&
              !avatar.startsWith('https://')) {
            FlutterBugfender.log(
                'AboutAuthor: Invalid avatar URL detected in testimonial $i: $avatar - This will cause image loading errors');
          }
        }
      }

      // Check author avatar
      final authorAvatar = authorData['avator']?.toString() ?? '';
      if (authorAvatar.isNotEmpty &&
          !authorAvatar.startsWith('http://') &&
          !authorAvatar.startsWith('https://')) {
        FlutterBugfender.log(
            'AboutAuthor: Invalid author avatar URL detected: $authorAvatar - This will cause image loading errors');
      }
    } catch (e) {
      // Log any errors during validation without failing the main request
      FlutterBugfender.log(
          'AboutAuthor: Error during avatar URL validation: ${e.toString()}');
      FlutterBugfender.error(
        'Error during avatar URL validation: $e',
      );
    }
  }

  /// Handles HTTP error responses
  static Map<String, dynamic> _handleHttpError(http.Response response) {
    FlutterBugfender.log(
        'AboutAuthor: HTTP error - Status: ${response.statusCode}');
    FlutterBugfender.error(
        'HTTP Error ${response.statusCode}, response: ${response.body}, status: ${response.statusCode}, error: ${response.reasonPhrase}');

    final errorMessage = _getHttpErrorMessage(response.statusCode);
    throw AboutAuthorApiException(
      'Server error: $errorMessage',
      statusCode: response.statusCode,
      details: 'Response body: ${response.body}',
    );
  }

  /// Handles timeout errors
  static Map<String, dynamic> _handleTimeoutError(
      TimeoutException e, StackTrace stackTrace) {
    // Log timeout errors
    FirebaseCrashlytics.instance
        .log('AboutAuthor: Request timeout - ${e.message}');
    FirebaseCrashlytics.instance.recordError(
      e,
      stackTrace,
      reason: 'Author API request timed out',
      information: ['Timeout duration: ${_timeout.inSeconds} seconds'],
    );

    throw AboutAuthorApiException(
      'Request timed out',
      details: 'Please check your internet connection and try again',
    );
  }

  /// Handles socket/network connectivity errors
  static Map<String, dynamic> _handleSocketError(
      SocketException e, StackTrace stackTrace) {
    // Log network connectivity errors
    FlutterBugfender.sendCrash(
        'AboutAuthor: Network connectivity error - ${e.message}',
        stackTrace.toString());
    FlutterBugfender.error(
      'AboutAuthor: Network connectivity error - ${e.message}',
    );

    throw AboutAuthorApiException(
      'Network connection error',
      details: 'Please check your internet connection',
    );
  }

  /// Handles unexpected errors
  static Map<String, dynamic> _handleUnexpectedError(
      dynamic e, StackTrace stackTrace) {
    // Log unexpected errors
    FlutterBugfender.sendCrash(
        'AboutAuthor: Unexpected error - ${e.toString()}',
        stackTrace.toString());
    FlutterBugfender.error(
      'AboutAuthor: Unexpected error - ${e.toString()}',
    );

    throw AboutAuthorApiException(
      'An unexpected error occurred',
      details: 'Please try again later',
    );
  }

  /// Helper method to get user-friendly HTTP error messages
  static String _getHttpErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad Request - Invalid request sent to server';
      case 401:
        return 'Unauthorized - Access denied';
      case 403:
        return 'Forbidden - Server refused to process request';
      case 404:
        return 'Not Found - Author data not available';
      case 429:
        return 'Too Many Requests - Rate limit exceeded';
      case 500:
        return 'Internal Server Error - Server encountered an error';
      case 502:
        return 'Bad Gateway - Server temporarily unavailable';
      case 503:
        return 'Service Unavailable - Server maintenance in progress';
      case 504:
        return 'Gateway Timeout - Server response timeout';
      default:
        return 'Unknown server error';
    }
  }
}
