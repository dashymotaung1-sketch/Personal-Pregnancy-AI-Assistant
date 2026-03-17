import 'package:flutter/material.dart';
import 'screens/baby_size_screen.dart';
import 'screens/kick_counter_screen.dart';
import 'screens/weight_tracker_screen.dart';
import 'screens/hospital_bag_screen.dart';
import 'screens/contraction_timer_screen.dart';
import 'screens/emergency_contacts_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pregnancy Tracker',
      theme: ThemeData(primarySwatch: Colors.pink),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pregnancy Tracker')),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Features', style: TextStyle(fontSize: 20))),
            ListTile(
              title: const Text('Baby Size Visualizer'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BabySizeScreen()),
              ),
            ),
            ListTile(
              title: const Text('Kick Counter'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KickCounterScreen()),
              ),
            ),
            ListTile(
              title: const Text('Weight Tracker'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WeightTrackerScreen()),
              ),
            ),
            ListTile(
              title: const Text('Hospital Bag Checklist'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HospitalBagScreen()),
              ),
            ),
            ListTile(
              title: const Text('Contraction Timer'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContractionTimerScreen()),
              ),
            ),
            ListTile(
              title: const Text('Emergency Contacts'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
              ),
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text(
          'Welcome to Pregnancy Tracker!\nUse the menu to navigate features.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}