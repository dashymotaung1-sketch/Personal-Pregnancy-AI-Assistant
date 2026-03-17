import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PeriodTrackerScreen extends StatefulWidget {
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
      appBar: AppBar(title: const Text("Period Tracker")),
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
            onPressed: _selectedDay == null ? null : () {
              addPeriodDay(_selectedDay!);
            },
            child: const Text("Add Period Day"),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: _periodDays.map((d) => ListTile(
                title: Text("${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}"),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}