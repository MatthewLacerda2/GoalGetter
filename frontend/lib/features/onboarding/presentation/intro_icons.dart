import 'package:flutter/material.dart';

/// The backend's `IntroIcon` set (`backend/services/gemini/onboarding/schema.py`):
/// each value is a Material icon name, so it maps with one const lookup. Keep
/// the two in step when the set changes.
const introIcons = <String, IconData>{
  'rocket_launch': Icons.rocket_launch,
  'flag': Icons.flag,
  'lightbulb': Icons.lightbulb,
  'menu_book': Icons.menu_book,
  'emoji_events': Icons.emoji_events,
  'explore': Icons.explore,
  'school': Icons.school,
  'psychology': Icons.psychology,
  'trending_up': Icons.trending_up,
  'star': Icons.star,
  'track_changes': Icons.track_changes,
  'calendar_today': Icons.calendar_today,
  'extension': Icons.extension,
  'local_fire_department': Icons.local_fire_department,
  'map': Icons.map,
};

/// A name outside the set (a newer backend) still gets an icon.
const introIconFallback = Icons.auto_awesome;

IconData introIconFor(String name) => introIcons[name] ?? introIconFallback;
