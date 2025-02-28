import 'package:flutter/material.dart';
import 'package:msbridge/backend/repo/auth_gate.dart';
import 'package:msbridge/frontend/theme/colors.dart';
import 'package:msbridge/backend/repo/auth_repo.dart';
import 'package:provider/provider.dart';
import 'package:appwrite/appwrite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final client = Client()
      .setEndpoint("https://cloud.appwrite.io/v1")
      .setProject("67bb3d10001efe42eb57");

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepo>(create: (_) => AuthRepo(client)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(), // Calls AuthGate instead of Home directly
    );
  }
}
