import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/registration_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkIfRegistered();
  }

  // Check if user is already registered
  Future<void> _checkIfRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phoneNumber');
    final name = prefs.getString('userName');
    final lmpString = prefs.getString('lmpDate');

    if (phone != null && name != null && lmpString != null) {
      final lmpDate = DateTime.tryParse(lmpString);
      if (lmpDate != null) {
        // Already registered → go to Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(userName: name, lmpDate: lmpDate),
          ),
        );
        return;
      }
    }

    setState(() {
      _loading = false; // Show login form
    });
  }

  // Go to registration screen
  void _goToRegistration() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RegistrationScreen(prefilledPhone: phone),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: "Enter your cellphone number",
                hintText: "e.g., 0712345678",
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _goToRegistration,
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}