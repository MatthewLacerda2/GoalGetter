import 'package:flutter/material.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/info_card.dart';
import '../../main.dart';

class FinishLessonScreen extends StatelessWidget {
  const FinishLessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ProgressBar(
                title: "Aprenda todas as notas básicas",
                icon: Icons.music_note,
                progress: 8,
                end: 8,
                color: Colors.green,
              ),
              
              const SizedBox(height: 24),
              
              InfoCard(
                title: "Parabéns!",
                description: "Você completou esta lição com sucesso. Continue praticando para melhorar suas habilidades.",
                mainColor: Colors.green,
              ),
              
              const SizedBox(height: 16),
              
              InfoCard(
                title: "Dica importante",
                description: "Lembre-se de praticar regularmente. A consistência é a chave para o progresso.",
                mainColor: Colors.blue,
              ),
              
              const SizedBox(height: 16),
              
              InfoCard(
                title: "Próximos passos",
                description: "Explore outras lições e continue sua jornada de aprendizado.",
                mainColor: Colors.orange,
              ),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyHomePage(
                          title: 'GoalGetter',
                          onLanguageChanged: (language) {
                          },
                        ),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}