import 'package:clock/clock.dart';

/// How long each onboarding question was on screen before the student answered
/// it (#174), for both the objective questions and the standard ones.
///
/// The clock of a question runs while it is the one on screen: [show] starts it
/// the moment the question takes the screen, and [stop] ends it at the tap that
/// answers it - or when he leaves it unanswered, going back. A question he
/// returns to adds its new time to the old, so what is sent is everything he
/// spent on it, not only his last visit. The time between the tap and the next
/// question (the pause that shows his choice, the slide) is on no question.
///
/// Read through `package:clock`, which the widget tests' fake time drives, so a
/// test can say "five seconds pass" and read five back.
class QuestionTimer {
  QuestionTimer(int count) : _spent = List.filled(count, Duration.zero);

  final List<Duration> _spent;
  final Stopwatch _running = clock.stopwatch();
  int? _current;

  /// Question [index] is now on screen: its clock runs.
  void show(int index) {
    stop();
    _current = index;
    _running
      ..reset()
      ..start();
  }

  /// The question on screen is answered or left: its time so far is kept.
  void stop() {
    final current = _current;
    if (current == null) return;
    _spent[current] += _running.elapsed;
    _running
      ..stop()
      ..reset();
    _current = null;
  }

  /// Whole seconds question [index] has been on screen, every visit together,
  /// truncated as the lesson screen truncates `seconds_spent`.
  int secondsOn(int index) => _spent[index].inSeconds;
}
