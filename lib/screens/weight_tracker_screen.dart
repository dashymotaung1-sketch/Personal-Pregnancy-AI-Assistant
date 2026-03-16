import 'package:flutter/material.dart';

class WeightTrackerScreen extends StatelessWidget {
  const WeightTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weight Tracker')),
      body: const Center(
        child: Text('Weight input and chart will go here'),
      ),
    );
  }
}