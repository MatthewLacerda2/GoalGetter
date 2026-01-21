import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:openapi/api.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/openapi_client_factory.dart';

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
      final apiClient = await OpenApiClientFactory(
        authService: _authService,
      ).createAuthorized();

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
        title: Text(AppLocalizations.of(context)!.objectives),
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
          ? Center(
              child: Text(
                AppLocalizations.of(context)!.noCompletedObjectives,
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
                        const SizedBox(height: 4),
                        Text(
                          '${AppLocalizations.of(context)!.createdAt} ${_formatDate(objective.createdAt)}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
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
