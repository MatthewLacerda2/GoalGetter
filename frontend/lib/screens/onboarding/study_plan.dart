import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../../app/app.dart';
import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/openapi_client_factory.dart';
import '../../utils/settings_storage.dart';
import '../../widgets/info_card.dart';
import 'goal_prompt_screen.dart';

class StudyPlanScreen extends StatefulWidget {
  final GoalStudyPlanResponse plan;

  StudyPlanScreen({super.key, required this.plan});

  @override
  State<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends State<StudyPlanScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _submitFullCreation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiClient = await OpenApiClientFactory(
        authService: _authService,
      ).createWithGoogleToken();

      final onboardingApi = OnboardingApi(apiClient);
      final request = GoalFullCreationRequest(
        goalName: widget.plan.goalName,
        goalDescription: widget.plan.goalDescription,
        firstObjectiveName: widget.plan.firstObjectiveName,
        firstObjectiveDescription: widget.plan.firstObjectiveDescription,
      );

      final response = await onboardingApi
          .generateFullCreationApiV1OnboardingFullCreationPost(request);

      if (response != null && mounted) {
        final student = response.student;

        // Store/update access token from response (account already exists from signup)
        await _authService.storeFinalCredentials(response.accessToken, {
          'id': student.id,
          'email': student.email,
          'name': student.name,
          'google_id': student.googleId,
        });

        // Use the JWT access token to persist the active goal/objective IDs.
        try {
          final jwtClient = ApiClient(basePath: AppConfig.baseUrl);
          jwtClient.addDefaultHeader(
            'Authorization',
            'Bearer ${response.accessToken}',
          );

          final studentApi = StudentApi(jwtClient);

          final studentStatus = await studentApi
              .getStudentCurrentStatusApiV1StudentGet();

          if (studentStatus?.goalId != null &&
              studentStatus!.goalId!.isNotEmpty) {
            await SettingsStorage.setCurrentGoalId(studentStatus.goalId!);
          }
        } catch (_) {
          // Best-effort only.
        }

        if (!mounted) return;

        // Navigate straight into the app (same end state as first-goal flow).
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.home,
          (route) => false,
          arguments: HomeRouteArgs(selectedIndex: 0),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final milestoneBg = Colors.grey[800];

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.studyPlan),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal title
            Text(
              widget.plan.goalName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            SizedBox(height: 8),
            // Goal description
            Text(
              widget.plan.goalDescription,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
            ),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.firstObjective,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            // First objective
            Text(
              widget.plan.firstObjectiveName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            SizedBox(height: 6),
            Text(
              widget.plan.firstObjectiveDescription,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
            ),
            SizedBox(height: 20),
            Divider(color: Colors.grey[500]),
            SizedBox(height: 16),
            // Milestones
            if (widget.plan.milestones.isNotEmpty) ...[
              Text(
                AppLocalizations.of(context)!.milestones,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              ...widget.plan.milestones.map(
                (m) => Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: InfoCard(title: m, backgroundColor: milestoneBg),
                ),
              ),
            ],
            SizedBox(height: 28),
            Divider(color: Colors.grey),
            SizedBox(height: 12),
            Center(
              child: Text(
                AppLocalizations.of(context)!.confirmQuestion,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => GoalPromptScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: 16.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.no,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitFullCreation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: 16.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            AppLocalizations.of(context)!.yes,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
