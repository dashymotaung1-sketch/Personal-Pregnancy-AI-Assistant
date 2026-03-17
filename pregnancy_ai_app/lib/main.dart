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
import 'package:table_calendar/table_calendar.dart';

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
      debugPrint("Daily tip: $tip");
      return;
    }
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9,
      0,
    );
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
      theme: ThemeData(
        primarySwatch: Colors.pink,
        useMaterial3: true,
      ),
      home: RegistrationScreen(),
    );
  }
}

// -------------------
// Registration Screen
// -------------------
class RegistrationScreen extends StatefulWidget {
  final String? prefilledName;
  const RegistrationScreen({super.key, this.prefilledName});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  Future<void> goToModeSelection() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your phone number')));
      return;
    }

    // Save user info
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _nameController.text);
    await prefs.setString('userPhone', _phoneController.text);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ModeSelectionScreen(
          userName: _nameController.text,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome! Let's get to know you",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Your Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: goToModeSelection,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Continue", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------
// Mode Selection Screen
// -------------------
class ModeSelectionScreen extends StatelessWidget {
  final String userName;

  const ModeSelectionScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Mode"),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Hello $userName!",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              "What would you like to track?",
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: _buildModeCard(
                    context,
                    title: "Period Tracker",
                    icon: Icons.calendar_month,
                    color: Colors.purple,
                    description: "Track your menstrual cycle",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PeriodTrackerScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildModeCard(
                    context,
                    title: "Pregnancy",
                    icon: Icons.pregnant_woman,
                    color: Colors.pink,
                    description: "Track your pregnancy journey",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PregnancyLmpScreen(userName: userName),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------
// Pregnancy LMP Screen
// -------------------
class PregnancyLmpScreen extends StatefulWidget {
  final String userName;

  const PregnancyLmpScreen({super.key, required this.userName});

  @override
  State<PregnancyLmpScreen> createState() => _PregnancyLmpScreenState();
}

class _PregnancyLmpScreenState extends State<PregnancyLmpScreen> {
  final _lmpController = TextEditingController();
  DateTime? _lmpDate;

  Future<void> goToDashboard() async {
    try {
      _lmpDate = DateTime.parse(_lmpController.text);
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid date format. Use YYYY-MM-DD')));
      return;
    }

    // Save LMP date
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lmpDate', _lmpDate!.toIso8601String());

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          userName: widget.userName, 
          lmpDate: _lmpDate!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pregnancy Information")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "When was your last menstrual period?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _lmpController,
              decoration: const InputDecoration(
                labelText: "Last Menstrual Period (YYYY-MM-DD)",
                border: OutlineInputBorder(),
                hintText: "e.g., 2024-01-01",
              ),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: goToDashboard,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Continue to Dashboard", style: TextStyle(fontSize: 18)),
            ),
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

  const DashboardScreen({
    super.key,
    required this.userName,
    required this.lmpDate,
  });

  @override
  Widget build(BuildContext context) {
    final features = [
      {'title': 'Home', 'icon': Icons.home, 'route': '/home'},
      {'title': 'Kick Counter', 'icon': Icons.directions_run, 'route': '/kick'},
      {
        'title': 'Weight Tracker',
        'icon': Icons.monitor_weight,
        'route': '/weight',
      },
      {'title': 'Hospital Bag', 'icon': Icons.shopping_bag, 'route': '/bag'},
      {
        'title': 'Contraction Timer',
        'icon': Icons.timer,
        'route': '/contraction',
      },
      {
        'title': 'Emergency Contacts',
        'icon': Icons.phone,
        'route': '/contacts',
      },
      {'title': 'AI Assistant', 'icon': Icons.chat, 'route': '/chat'},
      {'title': 'Reminders', 'icon': Icons.alarm, 'route': '/reminders'},
      {
        'title': 'Doctor Appointments',
        'icon': Icons.medical_services,
        'route': '/appointments',
      },
      {
        'title': 'Medication Reminders',
        'icon': Icons.medication,
        'route': '/medications',
      },
      {
        'title': 'Period Tracker',
        'icon': Icons.calendar_today,
        'route': '/period',
      },
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
                    MaterialPageRoute(
                      builder: (_) =>
                          HomeScreen(userName: userName, lmpDate: lmpDate),
                    ),
                  );
                  break;
                case '/kick':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const KickCounterScreen(),
                    ),
                  );
                  break;
                case '/weight':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WeightTrackerScreen(),
                    ),
                  );
                  break;
                case '/bag':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HospitalBagScreen(),
                    ),
                  );
                  break;
                case '/contraction':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ContractionTimerScreen(),
                    ),
                  );
                  break;
                case '/contacts':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EmergencyContactsScreen(),
                    ),
                  );
                  break;
                case '/chat':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatService: ChatService(
                          apiKey: "<YOUR_OPENAI_API_KEY>",
                        ),
                      ),
                    ),
                  );
                  break;
                case '/reminders':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RemindersScreen()),
                  );
                  break;
                case '/appointments':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DoctorAppointmentsScreen(),
                    ),
                  );
                  break;
                case '/medications':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MedicationRemindersScreen(),
                    ),
                  );
                  break;
                case '/period':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PeriodTrackerScreen(),
                    ),
                  );
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
    if (week <= 12)
      return {'name': 'Plum', 'image': 'https://i.imgur.com/1Plum.png'};
    if (week <= 16)
      return {'name': 'Avocado', 'image': 'https://i.imgur.com/Avocado.png'};
    if (week <= 20)
      return {'name': 'Banana', 'image': 'https://i.imgur.com/Banana.png'};
    if (week <= 24)
      return {'name': 'Corn', 'image': 'https://i.imgur.com/Corn.png'};
    if (week <= 28)
      return {'name': 'Eggplant', 'image': 'https://i.imgur.com/Eggplant.png'};
    if (week <= 32)
      return {'name': 'Squash', 'image': 'https://i.imgur.com/Squash.png'};
    if (week <= 36)
      return {'name': 'Honeydew', 'image': 'https://i.imgur.com/Honeydew.png'};
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
            Text(
              "Current pregnancy week: $week",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              "Baby size: ${baby['name']}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Image.network(baby['image']!, height: 150, width: 150),
            const SizedBox(height: 8),
            const Text(
              "Quick tip: Stay healthy, drink water!",
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------
// Placeholder Screens
// -------------------
class KickCounterScreen extends StatelessWidget {
  const KickCounterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kick Counter")),
      body: const Center(child: Text("Kick Counter Placeholder")),
    );
  }
}

class WeightTrackerScreen extends StatelessWidget {
  const WeightTrackerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Weight Tracker")),
      body: const Center(child: Text("Weight Tracker Placeholder")),
    );
  }
}

class HospitalBagScreen extends StatelessWidget {
  const HospitalBagScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hospital Bag")),
      body: const Center(child: Text("Hospital Bag Placeholder")),
    );
  }
}

class ContractionTimerScreen extends StatelessWidget {
  const ContractionTimerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contraction Timer")),
      body: const Center(child: Text("Contraction Timer Placeholder")),
    );
  }
}

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Emergency Contacts")),
      body: const Center(child: Text("Emergency Contacts Placeholder")),
    );
  }
}

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reminders")),
      body: const Center(child: Text("Reminders Placeholder")),
    );
  }
}

class DoctorAppointmentsScreen extends StatelessWidget {
  const DoctorAppointmentsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doctor Appointments")),
      body: const Center(child: Text("Doctor Appointments Placeholder")),
    );
  }
}

class MedicationRemindersScreen extends StatelessWidget {
  const MedicationRemindersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Medication Reminders")),
      body: const Center(child: Text("Medication Reminders Placeholder")),
    );
  }
}

// -------------------
// Period Tracker Screen
// -------------------
class PeriodTrackerScreen extends StatefulWidget {
  const PeriodTrackerScreen({super.key});
  @override
  State<PeriodTrackerScreen> createState() => _PeriodTrackerScreenState();
}

class _PeriodTrackerScreenState extends State<PeriodTrackerScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<DateTime> _periodDays = [];

  @override
  void initState() {
    super.initState();
    loadPeriodDays();
  }

  Future<void> loadPeriodDays() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('period_days') ?? [];
    setState(() {
      _periodDays = saved.map((s) => DateTime.parse(s)).toList();
    });
  }

  Future<void> savePeriodDays() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _periodDays.map((d) => d.toIso8601String()).toList();
    await prefs.setStringList('period_days', data);
  }

  void addPeriodDay(DateTime day) {
    setState(() {
      if (!_periodDays.contains(day)) {
        _periodDays.add(day);
        savePeriodDays();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Period Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => RegistrationScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => _periodDays.contains(day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _selectedDay == null
                ? null
                : () {
                    addPeriodDay(_selectedDay!);
                  },
            child: const Text("Add Period Day"),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: _periodDays
                  .map(
                    (d) => ListTile(
                      title: Text(
                        "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}",
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}