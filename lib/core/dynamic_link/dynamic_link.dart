import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:msbridge/main.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'dart:convert' as convert;

class DynamicLinkObserver extends NavigatorObserver {
  DynamicLinkObserver() {
    _initDynamicLinks();
  }

  void _initDynamicLinks() async {
    final PendingDynamicLinkData? initialLink =
        await FirebaseDynamicLinks.instance.getInitialLink();
    if (initialLink?.link != null) {
      _handleLink(initialLink!.link);
    }

    FirebaseDynamicLinks.instance.onLink.listen((data) {
      _handleLink(data.link);
    });
  }

  void _handleLink(Uri link) async {
    try {
      final Uri deep = link;
      final Uri target = deep;
      final List<String> parts =
          target.path.split('/').where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2 && parts[0] == 's') {
        final String shareId = parts[1];
        // Fetch and show a simple in-app viewer dialog
        final doc = await FirebaseFirestore.instance
            .collection('shared_notes')
            .doc(shareId)
            .get();
        final state = navigatorKey.currentState;
        if (state == null || !state.mounted) return;
        if (!doc.exists) {
          _showSnack('This shared note does not exist or was disabled.');
          return;
        }
        final data = doc.data() as Map<String, dynamic>;
        if (data['viewOnly'] != true) {
          _showSnack('This link is not viewable.');
          return;
        }
        _showSharedViewer(
          title: (data['title'] as String?) ?? 'Untitled',
          content: (data['content'] as String?) ?? '',
        );
      }
    } catch (e, stackTrace) {
      FlutterBugfender.sendCrash(
          'DynamicLink handling failed', stackTrace.toString());
      FlutterBugfender.error('DynamicLink handling failed: $e');
    }
  }

  void _showSnack(String message) {
    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null) return;
    CustomSnackBar.show(context, message, isSuccess: false);
  }

  void _showSharedViewer({required String title, required String content}) {
    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null) return;
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        String plain;
        try {
          final parsed = tryParseQuill(content);
          plain = parsed;
        } catch (e) {
          FlutterBugfender.error('Quill parsing failed: $e');
          plain = content;
        }
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title:
              Text(title, style: TextStyle(color: theme.colorScheme.primary)),
          content: SingleChildScrollView(
            child:
                Text(plain, style: TextStyle(color: theme.colorScheme.primary)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            )
          ],
        );
      },
    );
  }
}

String tryParseQuill(String content) {
  try {
    final dynamic json = convert.jsonDecode(content);
    if (json is List) {
      return json
          .map((op) =>
              op is Map && op['insert'] is String ? op['insert'] as String : '')
          .join('');
    }
    if (json is Map && json['ops'] is List) {
      final List ops = json['ops'];
      return ops
          .map((op) =>
              op is Map && op['insert'] is String ? op['insert'] as String : '')
          .join('');
    }
  } catch (e) {
    FlutterBugfender.error('Quill parsing failed: $e');
  }
  return content;
}
