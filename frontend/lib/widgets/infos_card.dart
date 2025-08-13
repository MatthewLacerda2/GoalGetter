import 'package:flutter/material.dart';

class InfosCard extends StatelessWidget {
  final List<String> texts;

  const InfosCard({
    super.key,
    required this.texts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300, width: 3.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < texts.length; i++) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Text(
                texts[i],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                  height: 1.6,
                ),
              ),
            ),
            if (i < texts.length - 1) ...[
              const SizedBox(height: 8),
              Container(
                height: 2,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}