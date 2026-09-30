import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
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
      home: const LoginPage(),
      debugShowCheckedModeBanner: false, // Menghilangkan banner debug
    );
  }
}
