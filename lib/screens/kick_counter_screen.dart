import 'package:flutter/material.dart';

class KickCounterScreen extends StatefulWidget {
  const KickCounterScreen({super.key});

  @override
  State<KickCounterScreen> createState() => _KickCounterScreenState();
}

class _KickCounterScreenState extends State<KickCounterScreen> {
  int kicks = 0;

  void _incrementCounter() {
    setState(() {
      kicks++;
    });
  }

  void _resetCounter() {
    setState(() {
      kicks = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kick Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Kicks: $kicks', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _incrementCounter,
              child: const Text('Add Kick'),
            ),
            ElevatedButton(
              onPressed: _resetCounter,
              child: const Text('Reset Counter'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}