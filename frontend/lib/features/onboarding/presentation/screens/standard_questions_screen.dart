import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';
import 'package:goal_getter/features/onboarding/data/onboarding_api.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/onboarding/presentation/standard_question_text.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/question_option_tile.dart';

/// The last step of goal creation: the handful of questions we already know to
/// ask, answered while the backend generates the first lesson (#132).
///
/// **Nothing here blocks.** `POST /goals` has already fired the chain, so these
/// answers are memory for the generations after the first, never an input it
/// waits on: the student may answer all of them, some of them or none, and the
/// next screen is his first lesson either way. What happens when that lesson is
/// not ready yet is the lesson screen's own "still preparing" message with a
/// retry (#98), never a bounce to a home screen with nothing on it.
///
/// The questions arrive as keys; `standard_question_text.dart` turns them into
/// the sentences of the student's locale, and a key this build does not know is
/// left out rather than drawn blank.
class StandardQuestionsScreen extends ConsumerStatefulWidget {
  final String goalId;
  final List<StandardQuestion> questions;

  const StandardQuestionsScreen({
    super.key,
    required this.goalId,
    required this.questions,
  });

  @override
  ConsumerState<StandardQuestionsScreen> createState() =>
      _StandardQuestionsScreenState();
}

class _StandardQuestionsScreenState
    extends ConsumerState<StandardQuestionsScreen> {
  late final List<StandardQuestion> _asked = widget.questions
      .where((q) => standardQuestionText.containsKey(q.key))
      .toList();
  final List<StandardAnswer> _answers = [];
  int _index = 0;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    if (_asked.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    }
  }

  void _pick(String optionKey) {
    if (_leaving) return;
    setState(() {
      _answers.add(
        StandardAnswer(questionKey: _asked[_index].key, optionKey: optionKey),
      );
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _index == _asked.length - 1 ? _finish() : setState(() => _index += 1);
    });
  }

  /// Send what he answered and take him to his lesson.
  ///
  /// The send is not awaited and a failure is swallowed on purpose: these
  /// answers are worth having and worth nothing at all compared with the lesson
  /// he is on his way to, and there is no screen here on which to show him an
  /// error about a question he has already finished with.
  void _finish() {
    if (_leaving) return;
    _leaving = true;
    if (_answers.isNotEmpty) {
      ref
          .read(onboardingApiProvider)
          .sendStandardAnswers(widget.goalId, List.of(_answers))
          .catchError((_) {});
    }
    context.go(AppRoutes.lesson);
  }

  String? _selected(String questionKey) {
    for (final answer in _answers) {
      if (answer.questionKey == questionKey) return answer.optionKey;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    if (_asked.isEmpty) return const Scaffold();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(l10n.standardQuestionsTitle),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _finish,
            child: Text(l10n.standardQuestionsSkip),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_index + 1) / _asked.length,
            backgroundColor: scheme.surfaceContainer,
            valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            minHeight: 6,
          ),
        ),
      ),
      body: _QuestionView(
        key: ValueKey(_asked[_index].key),
        question: _asked[_index],
        selected: _selected(_asked[_index].key),
        onPick: _pick,
      ),
    );
  }
}

/// One question and its options, faded in as it arrives.
class _QuestionView extends StatelessWidget {
  const _QuestionView({
    super.key,
    required this.question,
    required this.selected,
    required this.onPick,
  });

  final StandardQuestion question;
  final String? selected;
  final void Function(String optionKey) onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Text(
              standardQuestionLabel(l10n, question.key) ?? '',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          for (final optionKey in question.optionKeys)
            if (standardOptionLabel(l10n, question.key, optionKey)
                case final label?)
              QuestionOptionTile(
                option: label,
                isSelected: selected == optionKey,
                onTap: () => onPick(optionKey),
              ),
        ],
      ),
    );
  }
}
