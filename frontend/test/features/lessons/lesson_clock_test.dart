import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/features/lessons/presentation/widgets/lesson_clock.dart';

void main() {
  test('minutes and seconds only, clamped at 59:59', () {
    expect(formatLessonClock(const Duration(seconds: 95)), '01:35');
    expect(formatLessonClock(const Duration(minutes: 12, seconds: 5)), '12:05');
    expect(formatLessonClock(const Duration(hours: 2)), '59:59');
    expect(formatLessonClock(Duration.zero), '00:00');
  });
}
