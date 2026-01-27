import 'package:flutter/material.dart';
import 'package:goal_getter/l10n/app_localizations.dart';

import '../../theme/app_theme.dart';
import '../info_card.dart';

class NotesSection extends StatelessWidget {
  final List<String> notes;
  final String? label;

  const NotesSection({
    super.key,
    required this.notes,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const SizedBox.shrink();
    }

    final notesLabel = label ?? '${AppLocalizations.of(context)!.notes}:';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          notesLabel,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppTheme.elementGap),
        ...notes.map(
          (note) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.elementGap),
            child: InfoCard.ghost(
              description: note,
            ),
          ),
        ),
      ],
    );
  }
}
