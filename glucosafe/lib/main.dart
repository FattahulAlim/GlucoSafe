import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/services/notification_service.dart';
import 'features/auth/presentation/pages/welcome_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().initialize();
  runApp(const GlucoSafeApp());
}

class GlucoSafeApp extends StatelessWidget {
  const GlucoSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlucoSafe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
        fontFamily: 'Roboto', // Default font mirip wireframe
      ),
      home: const WelcomePage(),
      debugShowCheckedModeBanner: false, // Menghilangkan banner debug
    );
  }
}
