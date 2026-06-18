import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SerenaApp());
}

class SerenaApp extends StatelessWidget {
  const SerenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Serena',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
