import 'package:flutter/material.dart';
import 'screens/setup_screen.dart';
import 'services/ai_service.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(PregnancyApp());
}

class PregnancyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pregnancy PI App',
      theme: ThemeData(
        primarySwatch: Colors.pink,
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                aiService: AIService(apiKey: 'YOUR_OPENAI_API_KEY'),
              ),
      ),
      home: SetupScreen(),
    );
  }
}