import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:msbridge/backend/hive/notes_model.dart';
import 'package:msbridge/backend/services/internet_service.dart';
import 'package:msbridge/frontend/theme/colors.dart';
import 'package:msbridge/frontend/utils/error.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await Hive.initFlutter();
    Hive.registerAdapter(MSNoteAdapter());
    await Hive.openBox<MSNote>('notesBox');
    runApp(
      const MyApp(),
    );
  } catch (e) {
    runApp(ErrorApp(errorMessage: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: lightTheme,
      debugShowCheckedModeBanner: false,
      home: const InternetChecker(),
    );
  }
}
