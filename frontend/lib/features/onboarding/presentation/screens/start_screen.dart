import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/core/services/auth_service.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/pre_onboarding_carousel.dart';
import 'package:goal_getter/features/onboarding/debug/mock_start_screen.dart';

class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});

  @override
  ConsumerState<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<StartScreen> {
  late final AuthService _authService = ref.read(authServiceProvider);
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
    // Mock: the backend doesn't exist yet, so we skip the real "does this
    // student have a goal?" check. A signed-in user goes home; otherwise to the
    // goal prompt. The endpoint this replaces (GET student status → goalId) is
    // represented by the mock_* files.
    final accessToken = await _authService.getStoredAccessToken();
    if (!mounted) return;
    context.go(
      (accessToken != null && accessToken.isNotEmpty)
          ? AppRoutes.home
          : AppRoutes.goalPrompt,
    );
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
