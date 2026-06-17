import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const SerenaApp());
}

class SerenaApp extends StatelessWidget {
  const SerenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Serena',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
