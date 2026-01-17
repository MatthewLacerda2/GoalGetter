import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:openapi/api.dart';

import '../../config/app_config.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import 'goal_prompt_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _routeAfterSignIn() async {
    try {
      // Get stored access token (JWT)
      final accessToken = await _authService.getStoredAccessToken();
      if (accessToken == null) {
        // If no token, go to goal prompt screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const GoalPromptScreen()),
          );
        }
        return;
      }

      // Check student status to see if user has goals
      final apiClient = ApiClient(basePath: AppConfig.baseUrl);
      apiClient.addDefaultHeader('Authorization', 'Bearer $accessToken');
      final studentApi = StudentApi(apiClient);
      final studentStatus = await studentApi
          .getStudentCurrentStatusApiV1StudentGet();

      if (mounted) {
        if (studentStatus != null &&
            studentStatus.goalId != null &&
            studentStatus.goalId!.isNotEmpty) {
          // User has goals, go to main screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MyHomePage(
                title: 'Goal Getter',
                onLanguageChanged: (String) {},
              ),
            ),
          );
        } else {
          // User has no goals, go to goal prompt screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const GoalPromptScreen()),
          );
        }
      }
    } catch (e) {
      // On error, go to goal prompt screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GoalPromptScreen()),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final googleAuthResult = await _authService.signInWithGoogleWeb();

      if (googleAuthResult != null) {
        final googleToken = googleAuthResult['token'] as String;

        // Call signup endpoint to create/fetch account
        final signupResult = await _authService.signupWithGoogle(googleToken);

        if (signupResult != null && mounted) {
          // Check student status to see if user has goals
          await _routeAfterSignIn();
        }
      } else {
        // User cancelled sign-in
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign-in cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing in: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 33, 33, 33),
              Color.fromARGB(255, 11, 11, 11),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // App Icon/Logo placeholder
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.school, size: 60, color: Colors.blue),
                ),

                const SizedBox(height: 40),

                // App Title
                const Text(
                  'Goal Getter',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 16),

                // Subtitle
                const Text(
                  'Your 1:1 Tutor',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey,
                    fontWeight: FontWeight.w300,
                  ),
                ),

                const Spacer(flex: 3),

                // Google Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const FaIcon(
                            FontAwesomeIcons.google,
                            color: Colors.white,
                            size: 20,
                          ),
                    label: Text(
                      _isLoading ? 'Signing in...' : 'Start with Google',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: Colors.black.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Terms and Privacy
                Text(
                  'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    height: 1.4,
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
