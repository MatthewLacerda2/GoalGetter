import 'package:flutter/material.dart';
import 'package:openapi/api.dart';
import 'goal_prompt_screen.dart';
import 'tutorial_screen.dart';
import '../../widgets/info_card.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';

class StudyPlanScreen extends StatefulWidget {
  final GoalStudyPlanResponse plan;

  const StudyPlanScreen({super.key, required this.plan});

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
      // Get the Google token from AuthService
      final googleToken = _authService.getTempGoogleToken();
      if (googleToken == null) {
        throw Exception('No Google token available. Please sign in again.');
      }

      // Create API client and add the Google token as Authorization header
      final apiClient = ApiClient(basePath: AppConfig.baseUrl);
      apiClient.addDefaultHeader('Authorization', 'Bearer $googleToken');

      final onboardingApi = OnboardingApi(apiClient);
      final request = GoalFullCreationRequest(
        goalName: widget.plan.goalName,
        goalDescription: widget.plan.goalDescription,
        firstObjectiveName: widget.plan.firstObjectiveName,
        firstObjectiveDescription: widget.plan.firstObjectiveDescription,
      );

      final response = await onboardingApi.generateFullCreationApiV1OnboardingFullCreationPost(request);
      
      if (response != null && mounted) {
        // Success - navigate to tutorial screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const TutorialScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
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
        title: const Text('Study Plan'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal title
            Text(
              widget.plan.goalName,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            // Goal description
            Text(
              widget.plan.goalDescription,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400], // dark grey-ish
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            Text('First Objective:',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // First objective
            Text(
              widget.plan.firstObjectiveName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.plan.firstObjectiveDescription,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.grey[500]),
            const SizedBox(height: 16),
            // Milestones
            if (widget.plan.milestones.isNotEmpty) ...[
              Text(
                'Milestones',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              ...widget.plan.milestones.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InfoCard(
                    title: m,
                    backgroundColor: milestoneBg,
                    borderColor: Colors.grey[600],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            const Divider(color: Colors.grey),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Confirm?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const GoalPromptScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'No',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitFullCreation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Yes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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