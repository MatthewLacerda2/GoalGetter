import 'package:flutter/material.dart';
import 'package:goal_getter/l10n/app_localizations.dart';
import 'package:openapi/api.dart';

import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../widgets/info_card.dart';
import '../widgets/screens/objective/lesson_button.dart';
import '../widgets/screens/objective/objective_tab_header.dart';

class ObjectiveScreen extends StatefulWidget {
  const ObjectiveScreen({super.key});

  @override
  State<ObjectiveScreen> createState() => _ObjectiveScreenState();
}

class _ObjectiveScreenState extends State<ObjectiveScreen> {
  final _authService = AuthService();
  bool _isLoading = true;
  String? _errorMessage;

  String? _goalTitle;
  int? _streakCounter;
  String? _objectiveName;
  List<ObjectiveNote>? _notes;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get the stored access token
      final accessToken = await _authService.getStoredAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available. Please sign in again.');
      }

      // Create API client and add the access token as Authorization header
      final apiClient = ApiClient(basePath: AppConfig.baseUrl);
      apiClient.addDefaultHeader('Authorization', 'Bearer $accessToken');

      // Fetch student status and objective in parallel
      final studentApi = StudentApi(apiClient);
      final objectiveApi = ObjectiveApi(apiClient);

      final studentResponse = await studentApi
          .getStudentCurrentStatusApiV1StudentGet();
      final objectiveResponse = await objectiveApi
          .getObjectiveApiV1ObjectiveGet();

      if (studentResponse == null) {
        throw Exception('Failed to fetch student status');
      }

      if (objectiveResponse == null) {
        throw Exception('Failed to fetch objective');
      }

      if (mounted) {
        setState(() {
          _goalTitle = studentResponse.goalName;
          _streakCounter = studentResponse.currentStreak;
          _objectiveName = objectiveResponse.name;
          _notes = objectiveResponse.notes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ObjectiveTabHeader(
            goalTitle: _goalTitle ?? '',
            streakCounter: _streakCounter ?? 0,
          ),
          Expanded(
            child: _isLoading
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
                          onPressed: _fetchData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      const SizedBox(height: 12),
                      if (_objectiveName != null)
                        LessonButton(
                          title: _objectiveName!,
                          description: AppLocalizations.of(
                            context,
                          )!.startLesson,
                          mainColor: Colors.blue,
                        ),
                      if (_notes != null && _notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          '${AppLocalizations.of(context)!.notes}:',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._notes!.map(
                          (note) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: InfoCard(description: note.info),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
