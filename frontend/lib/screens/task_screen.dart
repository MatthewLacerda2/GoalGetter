import 'package:flutter/material.dart';
import 'package:goal_getter/l10n/app_localizations.dart';
import 'package:goal_getter/widgets/screens/task/task_test_button.dart';
import '../widgets/screens/task/task_tab_header.dart';
import '../widgets/info_card.dart';
import '../widgets/progress_bar.dart';
import '../widgets/infos_card.dart';

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TaskTabHeader(
            xpLevel: 2000,
            goalTitle: "Aprender violão",
            streakCounter: 365,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SizedBox(height: 10),
                ProgressBar(
                  title: "Aprenda todas as notas básicas",
                  icon: Icons.music_note,
                  progress: 2,
                  end: 8,
                  color: Colors.green,
                ),
                SizedBox(height: 28),
                LessonButton( //INFO: the idea later is to have these customized
                  title: AppLocalizations.of(context)!.lessonSession,
                  buttonText: AppLocalizations.of(context)!.showMeWhatYouGot,
                  onPressed: () {
                    // TODO: Implement button action
                  },
                ),
                SizedBox(height: 20),
                Text(
                  '${AppLocalizations.of(context)!.notes}:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 14),
                InfosCard(
                  texts: [
                    "Escolha duas notas básicas",
                    "Posicione os dedos corretamente",
                    "Toque a nota no ritmo \u2193 \u2191 \u2193 \u2191 \u2193 \u2193 \u2193",
                    "Troque de nota e repita DE-VA-GAR"
                  ],
                ),
                SizedBox(height: 24),
                InfoCard(
                  title: "Foque na precisão",
                  description: "Não faça as notas rápido. Faça-a devagar, acerte ela, toca um pouco, aí troca",
                ),
                SizedBox(height: 24),
                InfoCard(
                  title: "Foque em duas notas de cada vez",
                  description: "Só aprenda uma nota nova quando você decorou uma perfeitamente. Só varie um pouco, pra não ficar na mesmice",
                ),
                SizedBox(height: 24),
                InfoCard(
                  title: "Sério, precisão",
                  description: "Posicione os dedos perfeitamente, a nota tem que sair perfeita! Só depois, você toca no ritmo, e então troca",
                ),
                SizedBox(height: 24),
                InfoCard(
                  title: "NÃO toque ritmo rápido",
                  description: "A troca entre as notas tem que ser lenta, mas o ritmo que você toca as notas também!",
                ),
                SizedBox(height: 24),
                InfoCard(
                  title: "Já falei que é pra ser preciso?",
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}