import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:openapi/api.dart';

import '../../app/app.dart';
import '../../config/app_config.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/openapi_client_factory.dart';
import '../../widgets/screens/onboarding/pre_onboarding_carousel.dart';
import 'mock_start_screen.dart';

class StartScreen extends StatefulWidget {
  StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isGoogleInit = false;

  @override
  void initState() {
    super.initState();
    _initGoogleSignIn();
  }

  Future<void> _initGoogleSignIn() async {
    try {
      developer.log('Initializing Google Sign-In...');
      await _authService.ensureInitialized();
      if (mounted) {
        setState(() {
          _isGoogleInit = true;
        });
      }

      // Listen to authentication changes
      if (kIsWeb) {
        GoogleSignIn.instance.authenticationEvents.listen((GoogleSignInAuthenticationEvent event) async {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            final GoogleSignInAccount account = event.user;
            developer.log('Google user stream event received: ${account.email}');
            await _handleGoogleSignInWeb(account);
          }
        });
      }
    } catch (e) {
      developer.log('Failed to initialize Google Sign-In: $e');
    }
  }

  Future<void> _handleGoogleSignInWeb(GoogleSignInAccount account) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final googleAuthResult = await _authService.handleGoogleSignInAccount(account);

      if (googleAuthResult != null) {
        final googleToken = googleAuthResult['token'] as String;

        // Call signup endpoint to create/fetch account
        final signupResult = await _authService.signupWithGoogle(googleToken);

        if (signupResult != null && mounted) {
          // Check student status to see if user has goals
          await _routeAfterSignIn();
        }
      }
    } catch (error) {
      developer.log('Error handling Google web sign-in event: $error');
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

  Future<void> _routeAfterSignIn() async {
    try {
      // Get stored access token (JWT)
      final accessToken = await _authService.getStoredAccessToken();
      if (accessToken == null) {
        // If no token, go to goal prompt screen
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.goalPrompt);
        }
        return;
      }

      // Check student status to see if user has goals
      final apiClient = await OpenApiClientFactory(
        authService: _authService,
      ).createWithAccessToken();
      final studentApi = StudentApi(apiClient);
      final studentStatus = await studentApi
          .getStudentCurrentStatusApiV1StudentGet();

      if (mounted) {
        if (studentStatus != null &&
            studentStatus.goalId != null &&
            studentStatus.goalId!.isNotEmpty) {
          // User has goals, go to main screen
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        } else {
          // User has no goals, go to goal prompt screen
          Navigator.of(context).pushReplacementNamed(AppRoutes.goalPrompt);
        }
      }
    } catch (e) {
      // On error, go to goal prompt screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.goalPrompt);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await handleMockGoogleSignIn(context);
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
        decoration: BoxDecoration(
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
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(flex: 2),

                // App Title
                Text(
                  'Goal Getter',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),

                // Subtitle
                Text(
                  AppLocalizations.of(context)!.yourMentor,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w300,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),

                SizedBox(height: 28),

                PreOnboardingCarousel(height: 170),

                Spacer(flex: 2),

                // Google Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : FaIcon(
                            FontAwesomeIcons.google,
                            color: Colors.white,
                            size: 20,
                          ),
                    label: Text(
                      _isLoading ? 'Signing in...' : 'Start with Google',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4285F4),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                ),

                // Terms and Privacy
                Text(
                  AppLocalizations.of(context)!.agreeToTermsAndPrivacyPolicy,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
