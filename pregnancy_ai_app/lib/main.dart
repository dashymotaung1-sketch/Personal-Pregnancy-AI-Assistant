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
        'title': 'Health Exercises (YONGER)',
        'icon': Icons.fitness_center,
        'route': '/exercises',
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
                case '/exercises':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HealthExercisesScreen(),
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
// Health Exercises Screen (YONGER)
// -------------------
class HealthExercisesScreen extends StatefulWidget {
  const HealthExercisesScreen({super.key});

  @override
  State<HealthExercisesScreen> createState() => _HealthExercisesScreenState();
}

class _HealthExercisesScreenState extends State<HealthExercisesScreen> {
  List<Map<String, dynamic>> _completedExercises = [];
  DateTime _selectedDate = DateTime.now();
  
  // Exercise categories with YONGER exercises
  final List<Map<String, dynamic>> _exerciseCategories = [
    {
      'name': 'Warm-up Exercises',
      'icon': Icons.accessibility_new,
      'color': Colors.orange,
      'exercises': [
        {'name': 'Neck Rolls', 'duration': '2 mins', 'description': 'Gently roll your neck in clockwise and counterclockwise circles', 'completed': false},
        {'name': 'Shoulder Shrugs', 'duration': '2 mins', 'description': 'Lift shoulders up to ears, hold for 5 seconds, then release', 'completed': false},
        {'name': 'Arm Circles', 'duration': '2 mins', 'description': 'Make small circles with arms, gradually increasing size', 'completed': false},
        {'name': 'Ankle Rotations', 'duration': '2 mins', 'description': 'Rotate ankles clockwise and counterclockwise while seated', 'completed': false},
        {'name': 'Wrist Flexions', 'duration': '2 mins', 'description': 'Gently bend wrists up and down to improve flexibility', 'completed': false},
      ],
    },
    {
      'name': 'Breathing Exercises',
      'icon': Icons.air,
      'color': Colors.blue,
      'exercises': [
        {'name': 'Deep Belly Breathing', 'duration': '5 mins', 'description': 'Place hands on belly, breathe deeply into abdomen', 'completed': false},
        {'name': '4-7-8 Breathing', 'duration': '4 mins', 'description': 'Inhale for 4 counts, hold for 7, exhale for 8', 'completed': false},
        {'name': 'Alternate Nostril', 'duration': '5 mins', 'description': 'Close one nostril, inhale, switch and exhale', 'completed': false},
        {'name': 'Box Breathing', 'duration': '4 mins', 'description': 'Inhale 4, hold 4, exhale 4, hold 4', 'completed': false},
        {'name': 'Lion\'s Breath', 'duration': '2 mins', 'description': 'Inhale deeply, then exhale with open mouth and tongue out', 'completed': false},
      ],
    },
    {
      'name': 'Pelvic Floor',
      'icon': Icons.fitness_center,
      'color': Colors.purple,
      'exercises': [
        {'name': 'Basic Kegels', 'duration': '5 mins', 'description': 'Contract pelvic floor muscles, hold for 5-10 seconds', 'completed': false},
        {'name': 'Quick Kegels', 'duration': '5 mins', 'description': 'Quickly contract and release pelvic floor muscles', 'completed': false},
        {'name': 'Pelvic Tilts', 'duration': '5 mins', 'description': 'On hands and knees, tilt pelvis forward and backward', 'completed': false},
        {'name': 'Bridge Pose', 'duration': '5 mins', 'description': 'Lie on back, lift hips while engaging pelvic floor', 'completed': false},
        {'name': 'Happy Baby Pose', 'duration': '4 mins', 'description': 'Lie on back, hold feet and gently rock side to side', 'completed': false},
      ],
    },
    {
      'name': 'Leg & Glute Exercises',
      'icon': Icons.directions_walk,
      'color': Colors.green,
      'exercises': [
        {'name': 'Leg Lifts', 'duration': '5 mins', 'description': 'Lie on side, lift upper leg slowly and lower', 'completed': false},
        {'name': 'Calf Raises', 'duration': '3 mins', 'description': 'Standing, raise up on toes and lower slowly', 'completed': false},
        {'name': 'Modified Squats', 'duration': '5 mins', 'description': 'Partial squats holding onto chair for support', 'completed': false},
        {'name': 'Glute Bridges', 'duration': '5 mins', 'description': 'Lie on back, lift hips squeezing glutes', 'completed': false},
        {'name': 'Clamshells', 'duration': '4 mins', 'description': 'Lie on side with knees bent, open top knee like a clam', 'completed': false},
      ],
    },
    {
      'name': 'Stretching',
      'icon': Icons.self_improvement,
      'color': Colors.teal,
      'exercises': [
        {'name': 'Cat-Cow Stretch', 'duration': '5 mins', 'description': 'On hands and knees, alternate arching and rounding spine', 'completed': false},
        {'name': 'Butterfly Stretch', 'duration': '4 mins', 'description': 'Sit with soles together, gently press knees down', 'completed': false},
        {'name': 'Side Stretches', 'duration': '3 mins', 'description': 'Standing, reach one arm overhead and lean to side', 'completed': false},
        {'name': 'Upper Back Stretch', 'duration': '3 mins', 'description': 'Clasp hands in front, round back and stretch', 'completed': false},
        {'name': 'Hamstring Stretch', 'duration': '4 mins', 'description': 'Sit with leg extended, gently reach toward toes', 'completed': false},
      ],
    },
    {
      'name': 'Core Stability',
      'icon': Icons.sports_gymnastics,
      'color': Colors.red,
      'exercises': [
        {'name': 'Seated Twists', 'duration': '4 mins', 'description': 'Sit tall, gently twist upper body side to side', 'completed': false},
        {'name': 'Bird Dog', 'duration': '5 mins', 'description': 'On hands and knees, extend opposite arm and leg', 'completed': false},
        {'name': 'Dead Bug', 'duration': '4 mins', 'description': 'Lie on back, slowly lower opposite arm and leg', 'completed': false},
        {'name': 'Side Plank (Modified)', 'duration': '3 mins', 'description': 'Modified side plank with knees bent', 'completed': false},
        {'name': 'Pelvic Curls', 'duration': '4 mins', 'description': 'Gentle pelvic movements while lying on back', 'completed': false},
      ],
    },
    {
      'name': 'Arm & Upper Body',
      'icon': Icons.fitness_center,
      'color': Colors.deepOrange,
      'exercises': [
        {'name': 'Wall Push-ups', 'duration': '5 mins', 'description': 'Stand facing wall, do push-ups against wall', 'completed': false},
        {'name': 'Arm Circles (Small)', 'duration': '3 mins', 'description': 'Make small circles with arms extended', 'completed': false},
        {'name': 'Bicep Curls (Light)', 'duration': '4 mins', 'description': 'Light bicep curls with small weights or resistance bands', 'completed': false},
        {'name': 'Shoulder Press', 'duration': '4 mins', 'description': 'Light shoulder presses with small weights', 'completed': false},
        {'name': 'Tricep Extensions', 'duration': '4 mins', 'description': 'Light tricep extensions overhead', 'completed': false},
      ],
    },
    {
      'name': 'Cool Down',
      'icon': Icons.night_shelter,
      'color': Colors.indigo,
      'exercises': [
        {'name': 'Child\'s Pose', 'duration': '3 mins', 'description': 'Kneel and fold forward, resting forehead on floor', 'completed': false},
        {'name': 'Legs Up the Wall', 'duration': '5 mins', 'description': 'Lie on back with legs resting against wall', 'completed': false},
        {'name': 'Seated Forward Fold', 'duration': '4 mins', 'description': 'Sit with legs extended, gently fold forward', 'completed': false},
        {'name': 'Full Body Relaxation', 'duration': '5 mins', 'description': 'Lie down and consciously relax each body part', 'completed': false},
        {'name': 'Gentle Spinal Twist', 'duration': '3 mins', 'description': 'Gentle seated twist to release lower back', 'completed': false},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCompletedExercises();
  }

  Future<void> _loadCompletedExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('completed_exercises') ?? [];
    setState(() {
      _completedExercises = saved.map((s) {
        final Map<String, dynamic> map = json.decode(s);
        return {
          'date': DateTime.parse(map['date']),
          'exerciseName': map['exerciseName'],
          'category': map['category'],
        };
      }).toList();
    });
  }

  Future<void> _saveCompletedExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _completedExercises.map((e) {
      return json.encode({
        'date': e['date'].toIso8601String(),
        'exerciseName': e['exerciseName'],
        'category': e['category'],
      });
    }).toList();
    await prefs.setStringList('completed_exercises', data);
  }

  bool _isExerciseCompleted(String exerciseName, DateTime date) {
    return _completedExercises.any((e) =>
        e['exerciseName'] == exerciseName &&
        e['date'].year == date.year &&
        e['date'].month == date.month &&
        e['date'].day == date.day);
  }

  void _toggleExercise(String exerciseName, String category) {
    setState(() {
      if (_isExerciseCompleted(exerciseName, _selectedDate)) {
        _completedExercises.removeWhere((e) =>
            e['exerciseName'] == exerciseName &&
            e['date'].year == _selectedDate.year &&
            e['date'].month == _selectedDate.month &&
            e['date'].day == _selectedDate.day);
      } else {
        _completedExercises.add({
          'date': _selectedDate,
          'exerciseName': exerciseName,
          'category': category,
        });
      }
      _saveCompletedExercises();
    });
  }

  int _getCompletedCountForDate(DateTime date) {
    return _completedExercises
        .where((e) =>
            e['date'].year == date.year &&
            e['date'].month == date.month &&
            e['date'].day == date.day)
        .length;
  }

  int _getTotalExercises() {
    return _exerciseCategories.fold(0, (sum, category) => 
        sum + (category['exercises'] as List).length);
  }

  void _showExerciseDetails(Map<String, dynamic> exercise, String category) {
    bool isCompleted = _isExerciseCompleted(exercise['name'], _selectedDate);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(exercise['name']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.pink),
                    const SizedBox(width: 8),
                    Text('Duration: ${exercise['duration']}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                exercise['description'],
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.category, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Category: $category',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                _toggleExercise(exercise['name'], category);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? Colors.grey : Colors.pink,
              ),
              child: Text(isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int completedToday = _getCompletedCountForDate(_selectedDate);
    int totalExercises = _getTotalExercises();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Exercises (YONGER)"),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
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
          // Date selector and progress
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.pink.withOpacity(0.05),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                        });
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.pink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.add(const Duration(days: 1));
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Stack(
                  children: [
                    LinearProgressIndicator(
                      value: completedToday / totalExercises,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
                      minHeight: 10,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$completedToday of $totalExercises exercises completed today',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep up the great work! 🌟',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          
          // Exercise categories
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _exerciseCategories.length,
              itemBuilder: (context, index) {
                final category = _exerciseCategories[index];
                final exercises = category['exercises'] as List;
                final categoryCompletedCount = exercises
                    .where((e) => _isExerciseCompleted(e['name'], _selectedDate))
                    .length;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: category['color'].withOpacity(0.15),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(category['icon'], color: category['color'], size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category['name'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: category['color'],
                                    ),
                                  ),
                                  Text(
                                    '$categoryCompletedCount/${exercises.length} completed',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${((categoryCompletedCount / exercises.length) * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: category['color'],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Exercises list
                      ...exercises.map((exercise) {
                        bool isCompleted = _isExerciseCompleted(exercise['name'], _selectedDate);
                        
                        return ListTile(
                          leading: Checkbox(
                            value: isCompleted,
                            onChanged: (_) => _toggleExercise(exercise['name'], category['name']),
                            activeColor: Colors.pink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          title: Text(
                            exercise['name'],
                            style: TextStyle(
                              fontWeight: isCompleted ? FontWeight.normal : FontWeight.w500,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                              color: isCompleted ? Colors.grey : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            '${exercise['duration']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.info_outline, color: Colors.pink[300]),
                            onPressed: () => _showExerciseDetails(exercise, category['name']),
                          ),
                          onTap: () => _toggleExercise(exercise['name'], category['name']),
                        );
                      }).toList(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Show summary for the week
          int weeklyTotal = 0;
          Map<String, int> categoryWeekly = {};
          
          for (int i = 0; i < 7; i++) {
            final date = DateTime.now().subtract(Duration(days: i));
            weeklyTotal += _getCompletedCountForDate(date);
            
            // Count per category for the week
            for (var category in _exerciseCategories) {
              final categoryName = category['name'] as String;
              final exercises = category['exercises'] as List;
              
              int categoryCount = exercises
                  .where((e) => _isExerciseCompleted(e['name'], date))
                  .length;
              
              categoryWeekly[categoryName] = (categoryWeekly[categoryName] ?? 0) + categoryCount;
            }
          }
          
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Weekly Progress'),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.emoji_events, color: Colors.amber, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            '$weeklyTotal exercises',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'completed this week',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Category Breakdown:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...categoryWeekly.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key),
                            Text(
                              '${entry.value} exercises',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
        label: const Text('Weekly Summary'),
        icon: const Icon(Icons.bar_chart),
        backgroundColor: Colors.pink,
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