import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:openapi/api.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/openapi_client_factory.dart';
import '../theme/app_theme.dart';

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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.objectives),
        backgroundColor: AppTheme.surfaceVariant,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentPrimary,
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: AppTheme.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacing16),
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
                        AppLocalizations.of(context)!
                            .noCompletedObjectives,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSize18,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      child: ListView.builder(
                        itemCount: _objectives.length,
                        itemBuilder: (context, index) {
                          final objective = _objectives[index];
                          return Container(
                            margin: const EdgeInsets.only(
                                bottom: AppTheme.spacing12),
                            padding: const EdgeInsets.all(
                                AppTheme.spacing16),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(
                                  AppTheme.spacing8),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  objective.name,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: AppTheme.fontSize18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                    height: AppTheme.spacing4),
                                Text(
                                  '${AppLocalizations.of(context)!.createdAt} ${_formatDate(objective.createdAt)}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: AppTheme.fontSize14,
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
