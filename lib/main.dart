import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:msbridge/backend/hive/note_reading/notes_model.dart';
import 'package:msbridge/backend/hive/note_taking/note_taking.dart';
import 'package:msbridge/backend/services/internet_service.dart';
import 'package:msbridge/frontend/theme/colors.dart';
import 'package:msbridge/frontend/utils/error.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    //Hive model for  getting notes from api server
    await Hive.initFlutter();
    Hive.registerAdapter(MSNoteAdapter());
    await Hive.openBox<MSNote>('notesBox');
    // Hive model for note taking local Notes
    Hive.registerAdapter(NoteTakingModelAdapter());
    await Hive.openBox<NoteTakingModel>('notes_taking');

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
