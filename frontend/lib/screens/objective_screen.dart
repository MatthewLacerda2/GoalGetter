import 'package:flutter/material.dart';
import 'package:goal_getter/l10n/app_localizations.dart';
import '../widgets/info_card.dart';
import '../widgets/progress_bar.dart';
import '../widgets/screens/objective/objective_tab_header.dart';
import '../models/fake_questions.dart';
import '../models/question_data.dart';
import '../widgets/screens/objective/lesson_button.dart';

class ObjectiveScreen extends StatelessWidget {
  const ObjectiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ObjectiveTabHeader(
            goalTitle: "Aprender violão",
            streakCounter: 365,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                SizedBox(height: 12),
                ProgressBar(
                  title: "Aprenda todas as notas básicas",
                  progress: 3,
                  end: 10,
                  color: Colors.grey.withValues(alpha: 0.1),
                ),
                SizedBox(height: 16),
                LessonButton(
                  title: "Aprenda todas as notas básicas",
                  description: AppLocalizations.of(context)!.startLesson,
                  questions: fakeAcousticGuitarQuestions.map((q) => QuestionData(
                    question: q.question,
                    choices: List<String>.from(q.choices),
                    correctAnswer: q.correctAnswer,
                  )).toList(),
                  mainColor: Colors.blue,
                ),
                SizedBox(height: 12),
                Text(
                  '${AppLocalizations.of(context)!.notes}:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                InfoCard(
                  title: "Foque na precisão",
                  description: "Não faça as notas rápido. Faça-a devagar, acerte ela, toca um pouco, aí troca",
                ),
                SizedBox(height: 16),
                InfoCard(
                  title: "Foque em duas notas de cada vez",
                  description: "Só aprenda uma nota nova quando você decorou uma perfeitamente. Só varie um pouco, pra não ficar na mesmice",
                ),
                SizedBox(height: 16),
                InfoCard(
                  title: "Sério, precisão",
                  description: "Posicione os dedos perfeitamente, a nota tem que sair perfeita! Só depois, você toca no ritmo, e então troca",
                ),
                SizedBox(height: 16),
                InfoCard(
                  title: "NÃO toque ritmo rápido",
                  description: "A troca entre as notas tem que ser lenta, mas o ritmo que você toca as notas também!",
                ),
                SizedBox(height: 16),
                InfoCard(
                  title: "Já falei que é pra ser preciso?",
                ),
                SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}