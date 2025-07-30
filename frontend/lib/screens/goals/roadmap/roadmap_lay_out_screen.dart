import 'package:flutter/material.dart';
import '../../../utils/road_step_data.dart';
import '../../../widgets/screens/goals/roadmap/road_step_widget.dart';
import '../../../l10n/app_localizations.dart';

class RoadmapLayOutScreen extends StatefulWidget {
  final List<RoadStepData> steps;
  final List<String> beforehands;

  const RoadmapLayOutScreen({
    super.key,
    required this.steps,
    this.beforehands = const [],
  });

  @override
  State<RoadmapLayOutScreen> createState() => _RoadmapLayOutScreenState();
}

class _RoadmapLayOutScreenState extends State<RoadmapLayOutScreen> with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<Offset>> _animations = [];
  final List<AnimationController> _beforehandControllers = [];
  final List<Animation<Offset>> _beforehandAnimations = [];

  @override
  void initState() {
    super.initState();
    // Initialize animations for steps
    for (int i = 0; i < widget.steps.length; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      final animation = Tween<Offset>(
        begin: const Offset(-1.0, 0.0), // Start off-screen left
        end: Offset.zero, // End at normal position
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
      _controllers.add(controller);
      _animations.add(animation);

      // Stagger the animations
      Future.delayed(Duration(milliseconds: 200 * i), () {
        if (mounted) controller.forward();
      });
    }

    // Initialize animations for beforehands
    for (int i = 0; i < widget.beforehands.length; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      final animation = Tween<Offset>(
        begin: const Offset(-1.0, 0.0), // Start off-screen left
        end: Offset.zero, // End at normal position
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
      _beforehandControllers.add(controller);
      _beforehandAnimations.add(animation);

      // Stagger the animations after steps
      Future.delayed(Duration(milliseconds: 200 * (widget.steps.length + i)), () {
        if (mounted) controller.forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final c in _beforehandControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.roadmap)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...List.generate(widget.steps.length, (i) {
                return SlideTransition(
                  position: _animations[i],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: RoadStepWidget(roadStep: widget.steps[i]),
                  ),
                );
              }),
              if (widget.beforehands.isNotEmpty) ...[
                const SizedBox(height: 36),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocalizations.of(context)!.beforeYouStart,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ...List.generate(widget.beforehands.length, (i) {
                  return SlideTransition(
                    position: _beforehandAnimations[i],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 2.0, // Medium thickness
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                          color: Colors.green.shade200,
                        ),
                        child: Text(
                          widget.beforehands[i],
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    //TODO: save the roadmap, goal and task
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.goalStarted),
                      ),
                    );
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.letSGo,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
