// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:msbridge/theme/colors.dart';
// import 'package:provider/provider.dart';
// import 'package:msbridge/core/provider/theme_provider.dart';
// import 'package:msbridge/widgets/appbar.dart';
// import 'package:msbridge/widgets/custom_snackbar.dart';
// import 'package:msbridge/widgets/loading_dialogbox.dart';

// void main() {
//   group('UI Rendering Tests', () {
//     setUp(() async {
//       TestWidgetsFlutterBinding.ensureInitialized();

//       // Mock platform channels
//       const MethodChannel('plugins.flutter.io/shared_preferences')
//           .setMockMethodCallHandler((methodCall) async {
//         if (methodCall.method == 'getAll') {
//           return <String, dynamic>{
//             'flutter.appTheme': 'dark',
//             'flutter.dynamicColors': false,
//           };
//         }
//         return true;
//       });

//       // Mock Firebase Auth
//       const MethodChannel('plugins.flutter.io/firebase_auth')
//           .setMockMethodCallHandler((methodCall) async {
//         return null;
//       });
//     });

//     group('CustomAppBar Widget Tests', () {
//       testWidgets('CustomAppBar renders with default properties',
//           (tester) async {
//         await tester.pumpWidget(
//           MaterialApp(
//             home: Scaffold(
//               appBar: const CustomAppBar(),
//             ),
//           ),
//         );

//         expect(find.byType(AppBar), findsOneWidget);
//         expect(find.byType(CustomAppBar), findsOneWidget);
//       });

//       testWidgets('CustomAppBar shows title when provided', (tester) async {
//         const title = 'Test Title';

//         await tester.pumpWidget(
//           MaterialApp(
//             home: Scaffold(
//               appBar: const CustomAppBar(
//                 title: title,
//                 showTitle: true,
//               ),
//             ),
//           ),
//         );

//         expect(find.text(title), findsOneWidget);
//       });

//       testWidgets('CustomAppBar hides title when showTitle is false',
//           (tester) async {
//         const title = 'Test Title';

//         await tester.pumpWidget(
//           MaterialApp(
//             home: Scaffold(
//               appBar: const CustomAppBar(
//                 title: title,
//                 showTitle: false,
//               ),
//             ),
//           ),
//         );

//         expect(find.text(title), findsNothing);
//       });

//       testWidgets('CustomAppBar shows back button when configured',
//           (tester) async {
//         await tester.pumpWidget(
//           MaterialApp(
//             home: Scaffold(
//               appBar: const CustomAppBar(
//                 showBackButton: true,
//               ),
//             ),
//           ),
//         );

//         expect(find.byIcon(Icons.arrow_back), findsOneWidget);
//       });

//       testWidgets('CustomAppBar back button triggers navigation',
//           (tester) async {
//         bool backPressed = false;

//         await tester.pumpWidget(
//           MaterialApp(
//             home: Scaffold(
//               appBar: CustomAppBar(
//                 showBackButton: true,
//                 onBackButtonPressed: () {
//                   backPressed = true;
//                 },
//               ),
//             ),
//           ),
//         );

//         await tester.tap(find.byIcon(Icons.arrow_back));
//         await tester.pumpAndSettle();

//         expect(backPressed, isTrue);
//       });

//       testWidgets('CustomAppBar displays actions when provided',
//           (tester) async {
//         await tester.pumpWidget(
//           MaterialApp(
//             home: Scaffold(
//               appBar: const CustomAppBar(
//                 actions: [
//                   Icon(Icons.settings),
//                   Icon(Icons.more_vert),
//                 ],
//               ),
//             ),
//           ),
//         );

//         expect(find.byIcon(Icons.settings), findsOneWidget);
//         expect(find.byIcon(Icons.more_vert), findsOneWidget);
//       });

//       testWidgets('CustomAppBar respects theme colors', (tester) async {
//         await tester.pumpWidget(
//           MaterialApp(
//             theme: ThemeData(
//               colorScheme: const ColorScheme.light(
//                 primary: Colors.blue,
//                 surface: Colors.white,
//               ),
//             ),
//             home: Scaffold(
//               appBar: const CustomAppBar(
//                 title: 'Test',
//               ),
//             ),
//           ),
//         );

//         final appBar = tester.widget<AppBar>(find.byType(AppBar));
//         expect(appBar.backgroundColor, Colors.white);
//         expect(appBar.foregroundColor, Colors.blue);
//       });
//     });

//     group('Loading Dialog Tests', () {
//       testWidgets('LoadingDialog renders correctly', (tester) async {
//         await tester.pumpWidget(
//           const MaterialApp(
//             home: Scaffold(
//               body: LoadingDialog(
//                 message: 'Loading...',
//               ),
//             ),
//           ),
//         );

//         expect(find.byType(LoadingDialog), findsOneWidget);
//         expect(find.text('Loading...'), findsOneWidget);
//         expect(find.byType(CircularProgressIndicator), findsOneWidget);
//       });

//       testWidgets('LoadingDialog shows custom message', (tester) async {
//         const customMessage = 'Processing your request...';

//         await tester.pumpWidget(
//           const MaterialApp(
//             home: Scaffold(
//               body: LoadingDialog(
//                 message: customMessage,
//               ),
//             ),
//           ),
//         );

//         expect(find.text(customMessage), findsOneWidget);
//       });

//       testWidgets('LoadingDialog has proper styling', (tester) async {
//         await tester.pumpWidget(
//           MaterialApp(
//             theme: ThemeData(
//               colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
//             ),
//             home: const Scaffold(
//               body: LoadingDialog(
//                 message: 'Loading...',
//               ),
//             ),
//           ),
//         );

//         // Verify expected structure without assuming exact specific internals
//         expect(find.byType(LoadingDialog), findsOneWidget);
//       });
//     });

//     group('Custom SnackBar Tests', () {
//       testWidgets('CustomSnackBar shows success message', (tester) async {
//         await tester.pumpWidget(
//           MaterialApp(
//             home: Builder(
//               builder: (context) => Scaffold(
//                 body: ElevatedButton(
//                   onPressed: () {
//                     CustomSnackBar.show(
//                       context,
//                       'Success message',
//                       SnackBarType.success,
//                     );
//                   },
//                   child: const Text('Show Success'),
//                 ),
//               ),
//             ),
//           ),
//         );

//         await tester.tap(find.text('Show Success'));
//         await tester.pumpAndSettle();

//         expect(find.text('Success message'), findsOneWidget);
//         expect(find.byType(SnackBar), findsOneWidget);
//       });

//       testWidgets('CustomSnackBar shows error message', (tester) async {
//         await tester.pumpWidget(
//           MaterialApp(
//             home: Builder(
//               builder: (context) => Scaffold(
//                 body: ElevatedButton(
//                   onPressed: () {
//                     CustomSnackBar.show(
//                       context,
//                       'Error message',
//                       SnackBarType.error,
//                     );
//                   },
//                   child: const Text('Show Error'),
//                 ),
//               ),
//             ),
//           ),
//         );

//         await tester.tap(find.text('Show Error'));
//         await tester.pumpAndSettle();

//         expect(find.text('Error message'), findsOneWidget);
//         expect(find.byType(SnackBar), findsOneWidget);
//       });

//       testWidgets('CustomSnackBar auto-dismisses after duration',
//           (tester) async {
//         await tester.pumpWidget(
//           MaterialApp(
//             home: Builder(
//               builder: (context) => Scaffold(
//                 body: ElevatedButton(
//                   onPressed: () {
//                     CustomSnackBar.show(
//                       context,
//                       'Auto dismiss test',
//                       SnackBarType.info,
//                     );
//                   },
//                   child: const Text('Show Message'),
//                 ),
//               ),
//             ),
//           ),
//         );

//         await tester.tap(find.text('Show Message'));
//         await tester.pump();

//         // Message should be visible
//         expect(find.text('Auto dismiss test'), findsOneWidget);

//         // Wait for auto-dismiss and settle animations
//         await tester.pump(const Duration(seconds: 5));
//         await tester.pumpAndSettle();

//         // Message should be gone
//         expect(find.text('Auto dismiss test'), findsNothing);
//       });
//     });

//     group('Theme Integration Tests', () {
//       testWidgets('Widgets respond to theme changes', (tester) async {
//         final themeProvider = ThemeProvider();

//         await tester.pumpWidget(
//           ChangeNotifierProvider<ThemeProvider>.value(
//             value: themeProvider,
//             child: Consumer<ThemeProvider>(
//               builder: (context, provider, child) {
//                 return MaterialApp(
//                   theme: provider.getThemeData(),
//                   home: const Scaffold(
//                     appBar: CustomAppBar(title: 'Theme Test'),
//                     body: Text('Testing theme changes'),
//                   ),
//                 );
//               },
//             ),
//           ),
//         );

//         // Initial render
//         await tester.pumpAndSettle();
//         expect(find.text('Theme Test'), findsOneWidget);
//         expect(find.text('Testing theme changes'), findsOneWidget);

//         // Change theme
//         await themeProvider.setTheme(AppTheme.light);
//         await tester.pumpAndSettle();

//         // Widgets should still be there with new theme
//         expect(find.text('Theme Test'), findsOneWidget);
//         expect(find.text('Testing theme changes'), findsOneWidget);
//       });

//       testWidgets('Material 3 features work correctly', (tester) async {
//         await tester.pumpWidget(
//           MaterialApp(
//             theme: ThemeData(
//               useMaterial3: true,
//               colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
//             ),
//             home: const Scaffold(
//               appBar: CustomAppBar(title: 'Material 3 Test'),
//               body: Card(
//                 child: ListTile(
//                   title: Text('Material 3 Card'),
//                   subtitle: Text('Testing Material 3 components'),
//                 ),
//               ),
//             ),
//           ),
//         );

//         expect(find.text('Material 3 Test'), findsOneWidget);
//         expect(find.text('Material 3 Card'), findsOneWidget);
//         expect(find.byType(Card), findsOneWidget);
//         expect(find.byType(ListTile), findsOneWidget);
//       });
//     });

//     group('Responsive Design Tests', () {
//       testWidgets('UI adapts to different screen sizes', (tester) async {
//         // Test small screen
//         tester.binding.window.physicalSizeTestValue = const Size(360, 640);
//         tester.binding.window.devicePixelRatioTestValue = 1.0;

//         await tester.pumpWidget(
//           MaterialApp(
//             home: Scaffold(
//               appBar: const CustomAppBar(title: 'Responsive Test'),
//               body: LayoutBuilder(
//                 builder: (context, constraints) {
//                   return Text('Width: ${constraints.maxWidth}');
//                 },
//               ),
//             ),
//           ),
//         );

//         await tester.pumpAndSettle();
//         expect(find.textContaining('Width: 360'), findsOneWidget);

//         // Test large screen
//         tester.binding.window.physicalSizeTestValue = const Size(800, 600);
//         await tester.pumpAndSettle();
//         expect(find.textContaining('Width: 800'), findsOneWidget);

//         // Reset
//         tester.binding.window.clearPhysicalSizeTestValue();
//         tester.binding.window.clearDevicePixelRatioTestValue();
//       });

//       testWidgets('Text scales correctly with accessibility settings',
//           (tester) async {
//         await tester.pumpWidget(
//           MaterialApp(
//             home: const Scaffold(
//               body: Text('Accessibility test'),
//             ),
//           ),
//         );

//         final textWidget = tester.widget<Text>(find.text('Accessibility test'));
//         expect(textWidget.textScaleFactor, isNull); // Should use default

//         // Test with different text scale
//         await tester.pumpWidget(
//           MediaQuery(
//             data: const MediaQueryData(textScaleFactor: 1.5),
//             child: MaterialApp(
//               home: const Scaffold(
//                 body: Text('Accessibility test'),
//               ),
//             ),
//           ),
//         );

//         expect(find.text('Accessibility test'), findsOneWidget);
//       });
//     });

//     group('Navigation Tests', () {
//       testWidgets('Navigation between pages works', (tester) async {
//         await tester.pumpWidget(
//           MaterialApp(
//             home: const TestNavigationPage(),
//           ),
//         );

//         expect(find.text('Page 1'), findsOneWidget);

//         await tester.tap(find.text('Go to Page 2'));
//         await tester.pumpAndSettle();

//         // Assert by unique key on page 2 body to avoid duplicate text matches
//         expect(find.byKey(const ValueKey('page2-body')), findsOneWidget);
//         expect(find.text('Page 1'), findsNothing);
//       });

//       testWidgets('Back navigation works correctly', (tester) async {
//         await tester.pumpWidget(
//           MaterialApp(
//             home: const TestNavigationPage(),
//           ),
//         );

//         // Navigate to second page
//         await tester.tap(find.text('Go to Page 2'));
//         await tester.pumpAndSettle();
//         expect(find.byKey(const ValueKey('page2-body')), findsOneWidget);

//         // Navigate back
//         await tester.tap(find.byIcon(Icons.arrow_back));
//         await tester.pumpAndSettle();
//         expect(find.text('Page 1'), findsOneWidget);
//       });
//     });

//     group('Error Handling Tests', () {
//       testWidgets('UI handles null values gracefully', (tester) async {
//         await tester.pumpWidget(
//           const MaterialApp(
//             home: Scaffold(
//               appBar: CustomAppBar(
//                 title: null,
//                 showTitle: true,
//               ),
//               body: Text('Test'),
//             ),
//           ),
//         );

//         expect(find.text('Test'), findsOneWidget);
//         expect(find.byType(CustomAppBar), findsOneWidget);
//       });

//       testWidgets('Error widgets display correctly', (tester) async {
//         await tester.pumpWidget(
//           MaterialApp(
//             home: Scaffold(
//               body: SingleChildScrollView(
//                 child: Column(
//                   children: [
//                     const Text('Before error'),
//                     Builder(
//                       builder: (context) {
//                         throw Exception('Test error');
//                       },
//                     ),
//                     const Text('After error'),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );

//         expect(find.text('Before error'), findsOneWidget);
//         expect(find.byType(ErrorWidget), findsOneWidget);
//       });
//     });

//     group('Performance Tests', () {
//       testWidgets('Widget rebuilds are efficient', (tester) async {
//         int buildCount = 0;

//         await tester.pumpWidget(
//           MaterialApp(
//             home: StatefulBuilder(
//               builder: (context, setState) {
//                 buildCount++;
//                 return Scaffold(
//                   appBar: const CustomAppBar(title: 'Performance Test'),
//                   body: Column(
//                     children: [
//                       Text('Build count: $buildCount'),
//                       ElevatedButton(
//                         onPressed: () => setState(() {}),
//                         child: const Text('Rebuild'),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//         );

//         expect(buildCount, equals(1));

//         await tester.tap(find.text('Rebuild'));
//         await tester.pump();

//         expect(buildCount, equals(2));
//       });
//     });
//   });
// }

// // Helper widgets for testing
// class TestNavigationPage extends StatelessWidget {
//   const TestNavigationPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const CustomAppBar(title: 'Navigation Test'),
//       body: Column(
//         children: [
//           const Text('Page 1'),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.of(context).push(
//                 MaterialPageRoute(
//                   builder: (context) => const TestPage2(),
//                 ),
//               );
//             },
//             child: const Text('Go to Page 2'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class TestPage2 extends StatelessWidget {
//   const TestPage2({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const CustomAppBar(
//         title: 'Page 2',
//         showBackButton: true,
//       ),
//       body: const Text('Page 2', key: ValueKey('page2-body')),
//     );
//   }
// }
