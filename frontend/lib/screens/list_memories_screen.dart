import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:openapi/api.dart';

import '../config/app_config.dart';
import '../services/auth_service.dart';

class ListMemoriesScreen extends StatefulWidget {
  const ListMemoriesScreen({super.key});

  @override
  State<ListMemoriesScreen> createState() => _ListMemoriesScreenState();
}

class _ListMemoriesScreenState extends State<ListMemoriesScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<StudentContextItem> _memories = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accessToken = await _authService.getStoredAccessToken();
      final googleToken = await _authService.getStoredGoogleToken();
      final authToken = accessToken ?? googleToken;

      if (authToken == null) {
        throw Exception('No authentication token available');
      }

      final apiClient = ApiClient(basePath: AppConfig.baseUrl);
      apiClient.addDefaultHeader('Authorization', 'Bearer $authToken');

      final studentContextApi = StudentContextApi(apiClient);
      final memoriesResponse = await studentContextApi
          .getStudentContextsApiV1StudentContextGet();

      if (memoriesResponse != null) {
        setState(() {
          _memories = memoriesResponse.contexts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _memories = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMemory(StudentContextItem memory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Memory'),
          content: const Text('Are you sure you want to delete this memory?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        final accessToken = await _authService.getStoredAccessToken();
        final googleToken = await _authService.getStoredGoogleToken();
        final authToken = accessToken ?? googleToken;

        if (authToken == null) {
          throw Exception('No authentication token available');
        }

        final apiClient = ApiClient(basePath: AppConfig.baseUrl);
        apiClient.addDefaultHeader('Authorization', 'Bearer $authToken');

        final studentContextApi = StudentContextApi(apiClient);
        await studentContextApi
            .deleteStudentContextApiV1StudentContextContextIdDelete(memory.id);

        // Reload memories after deletion
        await _loadMemories();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting memory: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Memories'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: $_errorMessage',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadMemories,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _memories.isEmpty
          ? const Center(
              child: Text(
                'No memories',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: _memories.length,
                itemBuilder: (context, index) {
                  final memory = _memories[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                memory.state,
                                style: TextStyle(
                                  color: Colors.grey.shade900,
                                  fontSize: 16,
                                ),
                              ),
                              if (memory.metacognition.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  memory.metacognition,
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                'created at ${_formatDate(memory.createdAt)}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.grey.shade900),
                          onPressed: () => _deleteMemory(memory),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
