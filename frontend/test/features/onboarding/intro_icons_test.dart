import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/features/onboarding/presentation/intro_icons.dart';

/// The backend's IntroIcon values (services/gemini/onboarding/schema.py).
const backendIntroIcons = [
  'rocket_launch',
  'flag',
  'lightbulb',
  'menu_book',
  'emoji_events',
  'explore',
  'school',
  'psychology',
  'trending_up',
  'star',
  'track_changes',
  'calendar_today',
  'extension',
  'local_fire_department',
  'map',
];

void main() {
  test('every backend intro icon has its own Material icon', () {
    final icons = backendIntroIcons.map(introIconFor).toSet();
    expect(icons, hasLength(15));
    expect(icons, isNot(contains(introIconFallback)));
    expect(introIcons.keys, unorderedEquals(backendIntroIcons));
  });

  test('the name matches the Material icon of that name', () {
    expect(introIconFor('rocket_launch'), Icons.rocket_launch);
    expect(introIconFor('local_fire_department'), Icons.local_fire_department);
  });

  test('an unknown name falls back', () {
    expect(introIconFor('not_an_icon'), introIconFallback);
  });
}
