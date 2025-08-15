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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 75, 75, 75),
                  height: 1.6,
                ),
              ),
            ),
            if (i < texts.length - 1) ...[
              const SizedBox(height: 6),
              Container(
                height: 2,
                color: Colors.grey[800],
              ),
              const SizedBox(height: 6),
            ],
          ],
        ],
      ),
    );
  }
}