/// The lesson's time as the finish screen shows it: minutes and seconds only.
///
/// A lesson is two minutes (SOUL.md), so hours never apply. Anything past
/// 59:59 - the phone left on the table overnight - shows as 59:59 rather than
/// growing a third field (the user, 2026-09-26).
String formatLessonClock(Duration duration) {
  final seconds = duration.inSeconds.clamp(0, 59 * 60 + 59);
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  return '${twoDigits(seconds ~/ 60)}:${twoDigits(seconds % 60)}';
}
