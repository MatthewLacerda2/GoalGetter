import 'package:flutter/material.dart';

class QuestionChoice extends StatelessWidget {
  final String text;
  final Color borderColor;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const QuestionChoice({
    super.key,
    required this.text,
    required this.borderColor,
    required this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: 2.4,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: borderColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}