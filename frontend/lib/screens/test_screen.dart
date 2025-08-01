import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class TestScreen extends StatefulWidget {
  
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final TextEditingController _routeController = TextEditingController();
  final TextEditingController _payloadController = TextEditingController();
  // Update fields for id, datetime, and texts array
  String _id = '';
  String _datetime = '';
  List<String> _texts = ['', '', '']; // Array of 3 texts
  String _rawResponse = '';
  bool _isLoading = false;
  StreamSubscription? _subscription;

  @override
  void dispose() {
    _routeController.dispose();
    _payloadController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    if (_routeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a route')),
      );
      return;
    }

    // Cancel any existing subscription
    await _subscription?.cancel();

    setState(() {
      _isLoading = true;
      _id = '';
      _datetime = '';
      _texts = ['', '', '']; // Reset texts array
      _rawResponse = '';
    });

    try {
      final request = http.Request('POST', Uri.parse(_routeController.text));
      request.headers['Content-Type'] = 'application/json';
      request.body = _payloadController.text.isNotEmpty ? _payloadController.text : '{}';

      final streamedResponse = await request.send();
      
      _subscription = streamedResponse.stream
          .transform(utf8.decoder)
          .listen(
        (String chunk) {
          if (chunk.trim().isNotEmpty) {
            setState(() {
              _rawResponse += chunk;
              
              // Try to parse the latest complete JSON object
              try {
                // Find the last complete JSON object in the response
                int lastBraceIndex = _rawResponse.lastIndexOf('}');
                if (lastBraceIndex != -1) {
                  // Find the matching opening brace
                  int braceCount = 0;
                  int startIndex = -1;
                  for (int i = lastBraceIndex; i >= 0; i--) {
                    if (_rawResponse[i] == '}') {
                      braceCount++;
                    } else if (_rawResponse[i] == '{') {
                      braceCount--;
                      if (braceCount == 0) {
                        startIndex = i;
                        break;
                      }
                    }
                  }
                  
                  if (startIndex != -1) {
                    String jsonPart = _rawResponse.substring(startIndex, lastBraceIndex + 1);
                    final json = jsonDecode(jsonPart);
                    _id = json['id']?.toString() ?? '';
                    _datetime = json['datetime']?.toString() ?? '';
                    
                    // Handle texts array
                    if (json['texts'] != null && json['texts'] is List) {
                      List<dynamic> textsList = json['texts'];
                      _texts = textsList.map((text) => text?.toString() ?? '').toList();
                      // Ensure we have exactly 3 texts
                      while (_texts.length < 3) {
                        _texts.add('');
                      }
                      if (_texts.length > 3) {
                        _texts = _texts.take(3).toList();
                      }
                    }
                  }
                }
              } catch (e) {
                // If JSON parsing fails, don't clear existing fields
              }
            });
          }
        },
        onDone: () {
          setState(() {
            _isLoading = false;
          });
        },
        onError: (error) {
          setState(() {
            _texts[0] += '\nError: $error';
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _texts[0] = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Screen'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Route Field
            TextField(
              controller: _routeController,
              decoration: const InputDecoration(
                labelText: 'Route',
                hintText: 'https://api.example.com/endpoint',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Payload Field
            TextField(
              controller: _payloadController,
              decoration: const InputDecoration(
                labelText: 'Payload (JSON)',
                hintText: '{"key": "value"}',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            // Send Button
            ElevatedButton(
              onPressed: _isLoading ? null : _sendRequest,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send'),
            ),
            const SizedBox(height: 24),
            
            // Response Section
            const Text(
              'Response:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // ID Field
            TextField(
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'ID',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: _id),
            ),
            const SizedBox(height: 8),
            
            // Datetime Field
            TextField(
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Datetime',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: _datetime),
            ),
            const SizedBox(height: 8),
            
            // Three Text Fields for the texts array
            TextField(
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Text 1',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: _texts.isNotEmpty ? _texts[0] : ''),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            
            TextField(
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Text 2',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: _texts.length > 1 ? _texts[1] : ''),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            
            TextField(
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Text 3',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: _texts.length > 2 ? _texts[2] : ''),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}