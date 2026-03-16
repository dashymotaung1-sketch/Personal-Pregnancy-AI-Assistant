import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:universal_io/io.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chat_service.dart';
import 'chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await Notifications.init();
  runApp(const PregnancyApp());
}

// -------------------
// Notifications Helper
// -------------------
class Notifications {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  static Future<void> showDailyTip(String tip) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      print("Daily tip: $tip");
      return;
    }
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 0);
    const androidDetails = AndroidNotificationDetails(
      'daily_tip_channel',
      'Daily Pregnancy Tip',
      channelDescription: 'Receive a daily pregnancy tip',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.zonedSchedule(
      0,
      'Daily Pregnancy Tip',
      tip,
      scheduled,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}

// -------------------
// Main App
// -------------------
class PregnancyApp extends StatelessWidget {
  const PregnancyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pregnancy AI Assistant',
      theme: ThemeData(primarySwatch: Colors.pink),
      home: const RegistrationScreen(),
    );
  }
}

// -------------------
// Registration Screen
// -------------------
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _lmpController = TextEditingController();
  DateTime? _lmpDate;

  void goToDashboard() {
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
      appBar: AppBar(title: const Text("Welcome")),
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

// -------------------
// Dashboard Screen
// -------------------
class DashboardScreen extends StatelessWidget {
  final String userName;
  final DateTime lmpDate;

  const DashboardScreen({super.key, required this.userName, required this.lmpDate});

  @override
  Widget build(BuildContext context) {
    final features = [
      {'title': 'Home', 'icon': Icons.home, 'route': '/home'},
      {'title': 'Kick Counter', 'icon': Icons.directions_run, 'route': '/kick'},
      {'title': 'Weight Tracker', 'icon': Icons.monitor_weight, 'route': '/weight'},
      {'title': 'Hospital Bag', 'icon': Icons.shopping_bag, 'route': '/bag'},
      {'title': 'Contraction Timer', 'icon': Icons.timer, 'route': '/contraction'},
      {'title': 'Emergency Contacts', 'icon': Icons.phone, 'route': '/contacts'},
      {'title': 'AI Assistant', 'icon': Icons.chat, 'route': '/chat'},
      {'title': 'Reminders', 'icon': Icons.alarm, 'route': '/reminders'},
      {'title': 'Doctor Appointments', 'icon': Icons.medical_services, 'route': '/appointments'},
      {'title': 'Medication Reminders', 'icon': Icons.medication, 'route': '/medications'},
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Dashboard, $userName')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: features.map((f) {
          return GestureDetector(
            onTap: () {
              switch (f['route']) {
                case '/home':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HomeScreen(userName: userName, lmpDate: lmpDate)),
                  );
                  break;
                case '/kick':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => KickCounterScreen()));
                  break;
                case '/weight':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => WeightTrackerScreen()));
                  break;
                case '/bag':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => HospitalBagScreen()));
                  break;
                case '/contraction':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ContractionTimerScreen()));
                  break;
                case '/contacts':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencyContactsScreen()));
                  break;
                case '/chat':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ChatScreen(chatService: ChatService(apiKey: "<YOUR_OPENAI_API_KEY>"))));
                  break;
                case '/reminders':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => RemindersScreen()));
                  break;
                case '/appointments':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorAppointmentsScreen()));
                  break;
                case '/medications':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => MedicationRemindersScreen()));
                  break;
              }
            },
            child: Card(
              elevation: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(f['icon'] as IconData, size: 48, color: Colors.pink),
                  const SizedBox(height: 8),
                  Text(f['title'] as String, textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// -------------------
// Home Screen
// -------------------
class HomeScreen extends StatelessWidget {
  final String userName;
  final DateTime lmpDate;

  const HomeScreen({super.key, required this.userName, required this.lmpDate});

  int getCurrentWeek() {
    final now = DateTime.now();
    final days = now.difference(lmpDate).inDays;
    return (days / 7).floor() + 1;
  }

  Map<String, String> getBabySize(int week) {
    if (week <= 12) return {'name': 'Plum', 'image': 'https://i.imgur.com/1Plum.png'};
    if (week <= 16) return {'name': 'Avocado', 'image': 'https://i.imgur.com/Avocado.png'};
    if (week <= 20) return {'name': 'Banana', 'image': 'https://i.imgur.com/Banana.png'};
    if (week <= 24) return {'name': 'Corn', 'image': 'https://i.imgur.com/Corn.png'};
    if (week <= 28) return {'name': 'Eggplant', 'image': 'https://i.imgur.com/Eggplant.png'};
    if (week <= 32) return {'name': 'Squash', 'image': 'https://i.imgur.com/Squash.png'};
    if (week <= 36) return {'name': 'Honeydew', 'image': 'https://i.imgur.com/Honeydew.png'};
    return {'name': 'Pumpkin', 'image': 'https://i.imgur.com/Pumpkin.png'};
  }

  @override
  Widget build(BuildContext context) {
    final week = getCurrentWeek();
    final baby = getBabySize(week);

    return Scaffold(
      appBar: AppBar(title: Text("Hello, $userName")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Current pregnancy week: $week", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text("Baby size: ${baby['name']}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Image.network(baby['image']!, height: 150, width: 150),
            const SizedBox(height: 8),
            const Text("Quick tip: Stay healthy, drink water!", style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

// -------------------
// Kick Counter Screen
// -------------------
class KickCounterScreen extends StatefulWidget {
  @override
  State<KickCounterScreen> createState() => _KickCounterScreenState();
}

class _KickCounterScreenState extends State<KickCounterScreen> {
  int kicks = 0;

  void addKick() => setState(() => kicks++);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kick Counter")),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("Kicks: $kicks", style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: addKick, child: const Text("Add Kick")),
        ]),
      ),
    );
  }
}

// -------------------
// Weight Tracker Screen
// -------------------
class WeightTrackerScreen extends StatefulWidget {
  @override
  State<WeightTrackerScreen> createState() => _WeightTrackerScreenState();
}

class _WeightTrackerScreenState extends State<WeightTrackerScreen> {
  List<Map<String, String>> weights = [];

  void addWeight() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Weight (kg)"),
        content: TextField(controller: controller, keyboardType: TextInputType.number),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                weights.add({'date': DateTime.now().toIso8601String(), 'weight': controller.text});
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Weight Tracker")),
      body: Column(
        children: [
          ElevatedButton(onPressed: addWeight, child: const Text("Add Weight")),
          Expanded(
            child: ListView.builder(
              itemCount: weights.length,
              itemBuilder: (_, index) {
                final w = weights[index];
                return ListTile(title: Text("${w['weight']} kg"), subtitle: Text(w['date']!));
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------
// Hospital Bag Screen
// -------------------
class HospitalBagScreen extends StatefulWidget {
  @override
  State<HospitalBagScreen> createState() => _HospitalBagScreenState();
}

class _HospitalBagScreenState extends State<HospitalBagScreen> {
  Map<String, bool> items = {
    "Diapers": false,
    "Clothes": false,
    "Blankets": false,
    "Baby Lotion": false,
  };

  void addItem() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Item"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                items[controller.text] = false;
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hospital Bag")),
      body: Column(
        children: [
          ElevatedButton(onPressed: addItem, child: const Text("Add Item")),
          Expanded(
            child: ListView(
              children: items.keys
                  .map((k) => CheckboxListTile(
                        title: Text(k),
                        value: items[k],
                        onChanged: (v) => setState(() => items[k] = v!),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------
// Contraction Timer Screen
// -------------------
class ContractionTimerScreen extends StatefulWidget {
  @override
  State<ContractionTimerScreen> createState() => _ContractionTimerScreenState();
}

class _ContractionTimerScreenState extends State<ContractionTimerScreen> {
  List<DateTime> contractions = [];

  void addContraction() => setState(() => contractions.add(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contraction Timer")),
      body: Column(
        children: [
          ElevatedButton(onPressed: addContraction, child: const Text("Add Contraction")),
          Expanded(
            child: ListView.builder(
              itemCount: contractions.length,
              itemBuilder: (_, index) => ListTile(
                title: Text("Contraction at ${contractions[index].toIso8601String()}"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------
// Emergency Contacts Screen
// -------------------
class EmergencyContactsScreen extends StatefulWidget {
  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<Map<String, String>> contacts = [
    {"name": "Doctor", "phone": "123456789"},
    {"name": "Partner", "phone": "987654321"},
  ];

  void addContact() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Contact"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => contacts.add({'name': nameController.text, 'phone': phoneController.text}));
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void callContact(String phone) async {
    final url = "tel:$phone";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Emergency Contacts")),
      body: Column(
        children: [
          ElevatedButton(onPressed: addContact, child: const Text("Add Contact")),
          Expanded(
            child: ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (_, index) {
                final c = contacts[index];
                return ListTile(
                  title: Text(c['name']!),
                  subtitle: Text(c['phone']!),
                  trailing: IconButton(
                    icon: const Icon(Icons.call),
                    onPressed: () => callContact(c['phone']!),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------
// Placeholder Screens
// -------------------
class RemindersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("Reminders")), body: const Center(child: Text("Reminders will be here")));
  }
}

class DoctorAppointmentsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("Doctor Appointments")), body: const Center(child: Text("Appointments will be here")));
  }
}

class MedicationRemindersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("Medication Reminders")), body: const Center(child: Text("Medication reminders will be here")));
  }
}