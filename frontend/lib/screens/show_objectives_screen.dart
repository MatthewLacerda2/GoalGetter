import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:openapi/api.dart';

import '../config/app_config.dart';
import '../services/auth_service.dart';

class ShowObjectivesScreen extends StatefulWidget {
  const ShowObjectivesScreen({super.key});

  @override
  State<ShowObjectivesScreen> createState() => _ShowObjectivesScreenState();
}

class _ShowObjectivesScreenState extends State<ShowObjectivesScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<ObjectiveItem> _objectives = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadObjectives();
  }

  Future<void> _loadObjectives() async {
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

      final objectiveApi = ObjectiveApi(apiClient);
      final objectivesResponse = await objectiveApi
          .getObjectivesListApiV1ObjectiveListGet();

      if (objectivesResponse != null) {
        setState(() {
          _objectives = objectivesResponse.objectiveList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _objectives = [];
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

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Objectives'),
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
                    onPressed: _loadObjectives,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _objectives.isEmpty
          ? const Center(
              child: Text(
                'No completed objectives',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: _objectives.length,
                itemBuilder: (context, index) {
                  final objective = _objectives[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          objective.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'created at ${_formatDate(objective.createdAt)}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
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
