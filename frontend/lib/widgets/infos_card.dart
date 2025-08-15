import 'package:flutter/material.dart';

class InfosCard extends StatelessWidget {
  final List<String> texts;
  final Color? mainColor;
  final Color? descriptionColor;

  const InfosCard({
    super.key,
    required this.texts,
    this.mainColor,
    this.descriptionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mainColor ?? Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey, width: 4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < texts.length; i++) ...[
            SizedBox(
              width: double.infinity,
              child: Text(
                texts[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: descriptionColor ?? Colors.white,
                  height: 1.6,
                ),
              ),
            ),
            if (i < texts.length - 1) ...[
              const SizedBox(height: 8),
              Container(
                height: 2,
                color: descriptionColor ?? Colors.white,
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}