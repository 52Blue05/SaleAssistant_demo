import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/chat_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SaleAssistantApp());
}

class SaleAssistantApp extends StatelessWidget {
  const SaleAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sale Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
      routes: {
        '/chat': (_) => const ChatScreen(),
      },
    );
  }
}
