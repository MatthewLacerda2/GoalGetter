import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ErrorRetryWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ErrorRetryWidget({
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
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.edgePadding),
            child: Text(
              'Error: $errorMessage',
              style: const TextStyle(color: AppTheme.error),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          SizedBox(
            width: 150,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(150, 48),
              ),
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}
