import 'package:flutter/material.dart';
import 'roadmap_questions.dart';

const followUpQuestions = [
    "Why you decided to learn it?",
    "Why that instrument?",
    "What songs you wanna play?",
    "What do you wanna play it for?",
    "Do you know other instrument?",
];

class RoadmapPromptScreen extends StatefulWidget {
  const RoadmapPromptScreen({super.key});

  @override
  State<RoadmapPromptScreen> createState() => _RoadmapPromptScreenState();
}

class _RoadmapPromptScreenState extends State<RoadmapPromptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();
  
  // Focus nodes to track when fields are focused
  final _promptFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _promptFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _promptController.dispose();
    _promptFocusNode.dispose();
    super.dispose();
  }

  void _onEnterPressed() {
    if (_promptController.text.length >= 16) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoadmapQuestionsScreen(
            questions: followUpQuestions,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Be detailed of your goal!',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500))
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Roadmap'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              // Main question
              //Text('State your problem. State your purpose. State your level.',
              Text(
                'Tell what your goal is, what can you do so far, and what is the purpose',
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _promptController,
                focusNode: _promptFocusNode,
                decoration: InputDecoration(
                  hintText: 'I want to learn guitar, i can play most basic chords like G, D, E, and i wanna play some songs i like, like "Hey Jude"',
                  border: const OutlineInputBorder(),
                ),
                maxLength: 500,
                maxLines: 10,
                onChanged: (value) => setState(() {}),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _onEnterPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
            ),
            child: const Text(
              'Enter',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}