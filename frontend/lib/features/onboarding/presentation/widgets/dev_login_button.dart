import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/app/startup/app_start_controller.dart';
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/config/app_config.dart';
import 'package:goal_getter/core/services/auth_service.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

/// DEV_LOGIN builds only: signs in as `Fictitious <AppConfig.devLoginName>`
/// through POST /auth/dev-login, then routes the way a launch would.
class DevLoginButton extends ConsumerStatefulWidget {
  const DevLoginButton({super.key});

  @override
  ConsumerState<DevLoginButton> createState() => _DevLoginButtonState();
}

class _DevLoginButtonState extends ConsumerState<DevLoginButton> {
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authServiceProvider)
          .signInAsFictitious(AppConfig.devLoginName);
      final result = await ref.read(appStartControllerProvider).evaluate();
      if (mounted) context.go(result.destination.location);
    } on Exception catch (e) {
      if (!mounted) return;
      final detail = e is ApiException ? e.detail : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).signInFailed(detail)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: _isLoading ? null : _signIn,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.science_outlined),
        label: Text(AppLocalizations.of(context).continueAsFictitiousUser),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
