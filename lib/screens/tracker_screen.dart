import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/baby_development.dart';

class TrackerScreen extends StatefulWidget {
  final DateTime lmpDate;

  TrackerScreen({required this.lmpDate});

  @override
  _TrackerScreenState createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  late int currentWeek;
  late String trimester;
  late DateTime dueDate;
  late BabyDevelopment currentDevelopment;

  @override
  void initState() {
    super.initState();
    calculatePregnancyDetails();
    getCurrentDevelopment();
  }

  void calculatePregnancyDetails() {
    final today = DateTime.now();
    final difference = today.difference(widget.lmpDate).inDays;
    currentWeek = (difference / 7).floor() + 1; // Week number
    dueDate = widget.lmpDate.add(Duration(days: 280)); // 40 weeks

    if (currentWeek <= 12) {
      trimester = "First Trimester";
    } else if (currentWeek <= 26) {
      trimester = "Second Trimester";
    } else {
      trimester = "Third Trimester";
    }
  }

  void getCurrentDevelopment() {
    // Find the closest week info available
    currentDevelopment = developmentData.reduce((a, b) {
      return ( (currentWeek - a.week).abs() < (currentWeek - b.week).abs() ) ? a : b;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pregnancy Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Week: $currentWeek',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Trimester: $trimester',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              'Expected Due Date: ${DateFormat('dd MMM yyyy').format(dueDate)}',
              style: TextStyle(fontSize: 18),
            ),
            Divider(height: 40),
            Text(
              'Baby Size: ${currentDevelopment.babySize}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              'Development: ${currentDevelopment.development}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Health Tip: ${currentDevelopment.healthTip}',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}