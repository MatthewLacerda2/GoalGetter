import 'package:flutter/material.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
class ErrorRetryWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  ErrorRetryWidget({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              errorMessage,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 16.0),
          SizedBox(
            width: 150,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(150, 48),
              ),
              child: Text(AppLocalizations.of(context).retry),
            ),
          ),
        ],
      ),
    );
  }
}
