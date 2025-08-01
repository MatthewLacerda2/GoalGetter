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
  String _response = '';
  String _rawResponse = '';
  bool _isLoading = false;
  bool _isComplete = false;
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
      _isComplete = false;
      _response = '';
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
              _response = _rawResponse; // Show raw during streaming
            });
          }
        },
        onDone: () {
          setState(() {
            _isLoading = false;
            _isComplete = true;
            _response = _formatJson(_rawResponse); // Format when complete
          });
        },
        onError: (error) {
          setState(() {
            _response += '\nError: $error';
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  String _formatJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString);
      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (e) {
      return jsonString; // Return raw if not valid JSON
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
            
            // Response Display
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _response.isEmpty ? 'No response yet' : _response,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}