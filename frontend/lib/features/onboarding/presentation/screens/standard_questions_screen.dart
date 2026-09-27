import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/theme/app_dimens.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/question_card.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/onboarding/presentation/controllers/standard_questions_controller.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/standard_question_text.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/question_option_tile.dart';

/// The last step of goal creation: the handful of questions we already know to
/// ask, answered while the backend generates the first lesson.
///
/// **Nothing here blocks** (see its controller). `POST /goals` has already
/// fired the chain, so these answers are memory for the generations after the
/// first, never an input it waits on: the student may answer all of them, some of them or none, and the
/// next screen is his first lesson either way. What happens when that lesson is
/// not ready yet is the lesson screen's own "still preparing" message with a
/// retry, never a bounce to a home screen with nothing on it.
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

  StandardQuestionsControllerProvider get _provider =>
      standardQuestionsControllerProvider(widget.goalId, _asked);

  StandardQuestionsController get _controller => ref.read(_provider.notifier);

  @override
  void initState() {
    super.initState();
    if (_asked.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.finish();
      });
    }
  }

  void _pick(String optionKey) {
    if (!_controller.pick(optionKey)) return;
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _controller.advance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(_provider);
    ref.listen(_provider, (previous, next) {
      if (next.done && previous?.done != true) context.go(AppRoutes.lesson);
    });
    if (_asked.isEmpty) return const Scaffold();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(l10n.standardQuestionsTitle),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _controller.finish,
            child: Text(l10n.standardQuestionsSkip),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(AppSizes.progressBar),
          child: LinearProgressIndicator(
            value: (state.index + 1) / _asked.length,
            backgroundColor: scheme.surfaceContainer,
            valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            minHeight: AppSizes.progressBar,
          ),
        ),
      ),
      body: _QuestionView(
        key: ValueKey(_asked[state.index].key),
        question: _asked[state.index],
        selected: state.selected(_asked[state.index].key),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuestionCard(
            question: standardQuestionLabel(l10n, question.key) ?? '',
          ),
          const SizedBox(height: AppSpacing.xl),
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
