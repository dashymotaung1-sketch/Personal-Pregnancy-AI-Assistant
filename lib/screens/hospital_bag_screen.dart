import 'package:flutter/material.dart';

class HospitalBagScreen extends StatelessWidget {
  const HospitalBagScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hospital Bag Checklist')),
      body: const Center(
        child: Text('Checklist UI goes here'),
      ),
    );
  }
}