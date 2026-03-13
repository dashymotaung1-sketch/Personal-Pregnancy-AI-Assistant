import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:universal_io/io.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'chat_service.dart';
import 'chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await Notifications.init();
  runApp(const PregnancyApp());
}

// Notifications helper
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
      print("Daily tip: $tip"); // Web placeholder
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

  void goToHome() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your name')));
      return;
    }
    try {
      _lmpDate = DateTime.parse(_lmpController.text);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid date format')));
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => HomeScreen(
                userName: _nameController.text,
                lmpDate: _lmpDate!,
              )),
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
              onPressed: goToHome,
              child: const Text("Continue"),
            )
          ],
        ),
      ),
    );
  }
}

// -------------------
// Home Screen
// -------------------
class Appointment {
  String title;
  DateTime date;
  Appointment({required this.title, required this.date});
}

class HomeScreen extends StatefulWidget {
  final String userName;
  final DateTime lmpDate;

  const HomeScreen({super.key, required this.userName, required this.lmpDate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Appointments
  List<Appointment> appointments = [];

  void addAppointment(String title, DateTime date) {
    appointments.add(Appointment(title: title, date: date));
    setState(() {});
  }

  void showAddAppointmentDialog() {
    final titleController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Add Appointment"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Title"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (date != null) selectedDate = date;
                  },
                  child: const Text("Select Date"),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty &&
                        selectedDate != null) {
                      addAppointment(titleController.text, selectedDate!);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Save"))
            ],
          );
        });
  }

  // Pregnancy calculation
  int? _currentWeek;
  String? _trimester;
  DateTime? _dueDate;
  List stages = [];

  String getBackendUrl() {
    if (kIsWeb) return "http://127.0.0.1:8080";
    if (Platform.isAndroid) return "http://10.0.2.2:8080";
    if (Platform.isIOS) return "http://127.0.0.1:8080";
    return "http://127.0.0.1:8080";
  }

  Future<void> fetchStages() async {
    try {
      final response = await http.get(Uri.parse("${getBackendUrl()}/stages"));
      if (response.statusCode == 200) {
        setState(() => stages = jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("Failed to fetch stages: $e");
    }
  }

  void calculatePregnancy() {
    final now = DateTime.now();
    final days = now.difference(widget.lmpDate).inDays;
    final week = (days / 7).floor() + 1;
    _currentWeek = week;
    _dueDate = widget.lmpDate.add(const Duration(days: 280));

    if (week <= 13) _trimester = "First trimester";
    else if (week <= 27) _trimester = "Second trimester";
    else _trimester = "Third trimester";

    if (_currentWeek! <= stages.length) {
      Notifications.showDailyTip(stages[_currentWeek! - 1]['tips']);
    }
  }

  @override
  void initState() {
    super.initState();
    calculatePregnancy();
    fetchStages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Welcome, ${widget.userName}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Pregnancy info
          Text("Current pregnancy week: $_currentWeek"),
          Text("Trimester: $_trimester"),
          Text(
              "Expected due date: ${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}"),
          const Divider(height: 32),

          // Pregnancy stages
          const Text("Pregnancy Stages & Tips:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          stages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stages.length,
                  itemBuilder: (context, index) {
                    final stage = stages[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.pinkAccent,
                          child: Text(stage['week'].toString(),
                              style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text("Week ${stage['week']}"),
                        subtitle: Text(stage['info']),
                        children: [
                          if (stage['imageUrl'] != null)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(
                                stage['imageUrl'],
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              "Tip: ${stage['tips']}",
                              style:
                                  const TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

          const SizedBox(height: 32),

          // Appointments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Appointments",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                  onPressed: showAddAppointmentDialog,
                  icon: const Icon(Icons.add)),
            ],
          ),
          if (appointments.isEmpty)
            const Text("No appointments yet."),
          for (var app in appointments)
            ListTile(
              title: Text(app.title),
              subtitle: Text(
                  "${app.date.year}-${app.date.month.toString().padLeft(2, '0')}-${app.date.day.toString().padLeft(2, '0')}"),
            ),

          const SizedBox(height: 32),

          // AI Chat Button
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chatService: ChatService(apiKey: "<YOUR_OPENAI_API_KEY>"),
                  ),
                ),
              );
            },
            child: const Text("Ask AI a Pregnancy Question"),
          ),
        ]),
      ),
    );
  }
}