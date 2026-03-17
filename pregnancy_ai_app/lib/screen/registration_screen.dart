import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final String? prefilledName;
  const RegistrationScreen({super.key, this.prefilledName});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _lmpController = TextEditingController();
  DateTime? _lmpDate;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledName != null) {
      _nameController.text = widget.prefilledName!;
    }
  }

  Future<void> goToDashboard() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }
    try {
      _lmpDate = DateTime.parse(_lmpController.text);
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid date format')));
      return;
    }

    // Save user info
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _nameController.text);
    await prefs.setString('lmpDate', _lmpDate!.toIso8601String());

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          userName: _nameController.text,
          lmpDate: _lmpDate!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registration")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Your Name"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _lmpController,
              decoration: const InputDecoration(
                  labelText: "Last Menstrual Period (YYYY-MM-DD)"),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: goToDashboard,
              child: const Text("Continue"),
            )
          ],
        ),
      ),
    );
  }
}