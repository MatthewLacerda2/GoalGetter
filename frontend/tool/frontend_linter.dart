import 'dart:io';

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('Error: Could not find lib directory.');
    exit(1);
  }

  int filesWithErrors = 0;
  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) {
        final path = file.path.replaceAll('\\', '/');
        return path.endsWith('.dart') &&
               !path.endsWith('.g.dart') &&
               !path.endsWith('.freezed.dart') &&
               !path.contains('/l10n/generated/');
      });

  for (final file in dartFiles) {
    try {
      final lines = file.readAsLinesSync();
      final lineCount = lines.length;
      if (lineCount > 400) {
        print('  File: ${file.path}');
        print('    Error: File exceeds maximum line limit: $lineCount/400 lines');
        filesWithErrors++;
      }
    } catch (e) {
      print('  File: ${file.path}');
      print('    Error: Failed to read file: $e');
      filesWithErrors++;
    }
  }

  if (filesWithErrors > 0) {
    print('\n[LINT FAILURE] Frontend line count limit exceeded.');
    exit(1);
  } else {
    print('[LINT SUCCESS] All Dart files conform to the 400-line limit.');
    exit(0);
  }
}
