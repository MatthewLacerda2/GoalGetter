import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_getter/core/config/app_config.dart';
import 'package:goal_getter/core/services/auth_service.dart';
import 'package:goal_getter/core/widgets/failure.dart';
import 'package:goal_getter/features/onboarding/presentation/sign_in_routing.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';

/// DEV_LOGIN builds only: signs in as `Fictitious <AppConfig.devLoginName>`
/// through POST /auth/dev-login, then routes the way a launch would (or back
/// to the goal being committed, see [routeAfterSignIn]).
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
      if (mounted) await routeAfterSignIn(ref, context);
    } on Exception catch (e) {
      if (!mounted) return;
      showFailure(
        context,
        e,
        title: AppLocalizations.of(context).signInFailed,
        onRetry: _signIn,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.signInButton,
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
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
        ),
      ),
    );
  }
}
