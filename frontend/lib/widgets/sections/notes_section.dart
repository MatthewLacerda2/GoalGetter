import 'package:flutter/material.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

import '../info_card.dart';

class NotesSection extends StatelessWidget {
  final List<String> notes;
  final String? label;

  NotesSection({
    super.key,
    required this.notes,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return SizedBox.shrink();
    }

    final notesLabel = label ?? '${AppLocalizations.of(context)!.notes}:';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          notesLabel,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 16.0),
        ...notes.map(
          (note) => Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: InfoCard.ghost(
              description: note,
            ),
          ),
        ),
      ],
    );
  }
}
