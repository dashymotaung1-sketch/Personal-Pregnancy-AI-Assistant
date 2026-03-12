import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class ChatScreen extends StatefulWidget {
  final AIService aiService;

  ChatScreen({required this.aiService});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  String _answer = '';
  bool _loading = false;

  void askAI() async {
    final question = _controller.text;
    if (question.isEmpty) return;

    setState(() {
      _loading = true;
      _answer = '';
    });

    final response = await widget.aiService.askQuestion(question);

    setState(() {
      _answer = response;
      _loading = false;
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pregnancy AI Assistant')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ask any pregnancy question...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loading ? null : askAI,
              child: _loading ? CircularProgressIndicator() : Text('Ask'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _answer,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}