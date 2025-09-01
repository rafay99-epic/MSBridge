// import 'dart:convert';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bugfender/flutter_bugfender.dart';
// import 'package:msbridge/core/provider/lock_provider/app_pin_lock_provider.dart';
// import 'package:msbridge/core/provider/lock_provider/fingerprint_provider.dart';
// import 'package:msbridge/core/provider/theme_provider.dart';
// import 'package:msbridge/core/repo/auth_gate.dart';
// import 'package:msbridge/core/wrapper/app_pin_lock_wrapper.dart';
// import 'package:msbridge/core/wrapper/fingerprint_wrapper.dart';
// import 'package:msbridge/main.dart';
// import 'package:msbridge/theme/colors.dart';
// import 'package:provider/provider.dart';

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final themeProvider = Provider.of<ThemeProvider>(context);
//     return MaterialApp(
//       navigatorKey: navigatorKey,
//       theme: _buildTheme(themeProvider, false),
//       darkTheme: _buildTheme(themeProvider, true),
//       themeMode: themeProvider.selectedTheme == AppTheme.light
//           ? ThemeMode.light
//           : ThemeMode.dark,
//       home: const SecurityWrapper(child: AuthGate()),
//       debugShowCheckedModeBanner: false,
//       localizationsDelegates: [
//         FlutterQuillLocalizations.delegate,
//       ],
//       supportedLocales: const [
//         Locale('en', 'US'),
//         Locale('en'),
//       ],
//       navigatorObservers: [
//         _DynamicLinkObserver(),
//       ],
//     );
//   }

//   ThemeData _buildTheme(ThemeProvider themeProvider, bool isDark) {
//     return themeProvider.getThemeData();
//   }
// }

// class FlutterQuillLocalizations {}

// class SecurityWrapper extends StatelessWidget {
//   final Widget child;

//   const SecurityWrapper({super.key, required this.child});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer2<AppPinLockProvider, FingerprintAuthProvider>(
//       builder: (context, pinProvider, fingerprintProvider, _) {
//         if (fingerprintProvider.isFingerprintEnabled) {
//           return FingerprintAuthWrapper(child: child);
//         } else if (pinProvider.enabled) {
//           return AppPinLockWrapper(child: child);
//         } else {
//           return child;
//         }
//       },
//     );
//   }
// }

// class _DynamicLinkObserver extends NavigatorObserver {
//   _DynamicLinkObserver() {
//     _initDynamicLinks();
//   }

//   void _initDynamicLinks() async {
//     final PendingDynamicLinkData? initialLink =
//         await FirebaseDynamicLinks.instance.getInitialLink();
//     if (initialLink?.link != null) {
//       _handleLink(initialLink!.link);
//     }

//     FirebaseDynamicLinks.instance.onLink.listen((data) {
//       _handleLink(data.link);
//     });
//   }

//   void _handleLink(Uri link) async {
//     try {
//       final Uri deep = link;
//       final Uri target = deep;
//       final List<String> parts =
//           target.path.split('/').where((p) => p.isNotEmpty).toList();
//       if (parts.length >= 2 && parts[0] == 's') {
//         final String shareId = parts[1];
//         // Fetch and show a simple in-app viewer dialog
//         final doc = await FirebaseFirestore.instance
//             .collection('shared_notes')
//             .doc(shareId)
//             .get();
//         final state = navigatorKey.currentState;
//         if (state == null || !state.mounted) return;
//         if (!doc.exists) {
//           _showSnack('This shared note does not exist or was disabled.');
//           return;
//         }
//         final data = doc.data() as Map<String, dynamic>;
//         if (data['viewOnly'] != true) {
//           _showSnack('This link is not viewable.');
//           return;
//         }
//         _showSharedViewer(
//           title: (data['title'] as String?) ?? 'Untitled',
//           content: (data['content'] as String?) ?? '',
//         );
//       }
//     } catch (e, st) {
//       FlutterBugfender.error('DynamicLink handling failed: $e');
//       FlutterBugfender.sendCrash(
//         'DynamicLink handling failed: $e',
//         st.toString(),
//       );
//     }
//   }

//   void _showSnack(String message) {
//     final context = navigatorKey.currentState?.overlay?.context;
//     if (context == null) return;
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text(message)));
//   }

//   void _showSharedViewer({required String title, required String content}) {
//     final context = navigatorKey.currentState?.overlay?.context;
//     if (context == null) return;
//     showDialog(
//       context: context,
//       builder: (ctx) {
//         final theme = Theme.of(ctx);
//         String plain;
//         try {
//           final parsed = _tryParseQuill(content);
//           plain = parsed;
//         } catch (_) {
//           plain = content;
//         }
//         return AlertDialog(
//           backgroundColor: theme.colorScheme.surface,
//           title:
//               Text(title, style: TextStyle(color: theme.colorScheme.primary)),
//           content: SingleChildScrollView(
//             child:
//                 Text(plain, style: TextStyle(color: theme.colorScheme.primary)),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(ctx).pop(),
//               child: const Text('Close'),
//             )
//           ],
//         );
//       },
//     );
//   }
// }

// String _tryParseQuill(String content) {
//   try {
//     final dynamic json = _jsonDecode(content);
//     if (json is List) {
//       return json
//           .map((op) =>
//               op is Map && op['insert'] is String ? op['insert'] as String : '')
//           .join('');
//     }
//     if (json is Map && json['ops'] is List) {
//       final List ops = json['ops'];
//       return ops
//           .map((op) =>
//               op is Map && op['insert'] is String ? op['insert'] as String : '')
//           .join('');
//     }
//   } catch (_) {}
//   return content;
// }

// dynamic _jsonDecode(String s) {
//   return jsonDecode(s);
// }

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:msbridge/core/dynamic_link/dynamic_link.dart';
import 'package:msbridge/core/provider/theme_provider.dart';
import 'package:msbridge/core/repo/auth_gate.dart';
import 'package:msbridge/core/wrapper/main_wrapper.dart';
import 'package:msbridge/main.dart';
import 'package:msbridge/theme/colors.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: _buildTheme(themeProvider, false),
      darkTheme: _buildTheme(themeProvider, true),
      themeMode: themeProvider.selectedTheme == AppTheme.light
          ? ThemeMode.light
          : ThemeMode.dark,
      home: const SecurityWrapper(child: AuthGate()),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('en'),
      ],
      navigatorObservers: [
        DynamicLinkObserver(),
      ],
    );
  }

  ThemeData _buildTheme(ThemeProvider themeProvider, bool isDark) {
    return themeProvider.getThemeData();
  }
}
