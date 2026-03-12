import 'package:flutter/material.dart';
import 'tracker_screen.dart';

class SetupScreen extends StatefulWidget {
  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  DateTime? _lmpDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Setup Your Pregnancy')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _lmpDate == null
                  ? 'Select your last menstrual period'
                  : 'Selected: ${_lmpDate!.toLocal()}'.split(' ')[0],
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );

                if (pickedDate != null) {
                  setState(() {
                    _lmpDate = pickedDate;
                  });
                }
              },
              child: Text('Pick Date'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _lmpDate == null
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TrackerScreen(lmpDate: _lmpDate!),
                  ),
                );
              },
              child: Text('Go to Tracker'),
            ),
          ],
        ),
      ),
    );
  }
}