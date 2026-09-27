import 'package:flutter_test/flutter_test.dart';

import '../../tool/frontend_linter.dart';

/// The rules of `tool/layer_rules.dart`: which folder of a feature may import
/// which, and which folders a feature's `presentation/` holds (#222).

List<String> _rules(String path, String source) =>
    lintSource(path, source).map((v) => v.rule).toList();

const _importApi =
    "import 'package:goal_getter/features/lessons/data/lessons_api.dart';";

void main() {
  group('presentation-imports-data', () {
    test('fails on a screen or a widget importing a data/ file', () {
      expect(
        _rules(
          'lib/features/lessons/presentation/screens/lesson_screen.dart',
          _importApi,
        ),
        contains('presentation-imports-data'),
      );
      expect(
        _rules(
          'lib/features/home/presentation/widgets/streak_chip.dart',
          _importApi,
        ),
        contains('presentation-imports-data'),
      );
      expect(
        _rules(
          'lib/features/lessons/presentation/screens/lesson_screen.dart',
          "import '../../data/lessons_api.dart';",
        ),
        contains('presentation-imports-data'),
      );
    });

    test('passes on a controller importing data/, and a screen its domain', () {
      expect(
        _rules(
          'lib/features/lessons/presentation/controllers/lesson_controller.dart',
          _importApi,
        ),
        isEmpty,
      );
      expect(
        _rules(
          'lib/features/lessons/presentation/screens/lesson_screen.dart',
          "import 'package:goal_getter/features/lessons/domain/lesson_models.dart';",
        ),
        isEmpty,
      );
    });
  });

  group('presentation-layout', () {
    test('fails on a file loose under presentation/ or in a fourth folder', () {
      expect(
        _rules('lib/features/lessons/presentation/lesson_clock.dart', ''),
        contains('presentation-layout'),
      );
      expect(
        _rules('lib/features/lessons/presentation/helpers/clock.dart', ''),
        contains('presentation-layout'),
      );
    });

    test('passes on the three folders, and outside features/', () {
      for (final folder in ['controllers', 'screens', 'widgets']) {
        expect(
          _rules('lib/features/lessons/presentation/$folder/a.dart', ''),
          isEmpty,
          reason: folder,
        );
      }
      expect(_rules('lib/app/router/app_router.dart', ''), isEmpty);
    });
  });
}
