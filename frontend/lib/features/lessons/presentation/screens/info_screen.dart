import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  final IconData icon;
  final String descriptionText;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final String? title;

  InfoScreen({
    super.key,
    required this.icon,
    required this.descriptionText,
    required this.buttonText,
    required this.onButtonPressed,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (title != null) ...[
                      Text(
                        title!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                      SizedBox(height: 24.0),
                    ],
                    Icon(
                      icon,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 140,
                    ),
                    SizedBox(height: 48),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                            20.0),
                      ),
                      child: Text(
                        descriptionText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          fontSize: 20.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                        vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(20.0),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.0),
            ],
          ),
        ),
      ),
    );
  }
}