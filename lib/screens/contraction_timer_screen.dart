import 'package:flutter/material.dart';

class ContractionTimerScreen extends StatelessWidget {
  const ContractionTimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contraction Timer')),
      body: const Center(
        child: Text('Timer and history will go here'),
      ),
    );
  }
}