import 'dart:io';

import '../engine/engine.dart';
import '../utils/utils.dart';
import 'commands.dart';

/// Command to check architecture rules.
class CheckCommand implements BaseCommand {
  @override
  String get name => 'check';

  @override
  String get description => 'Check architecture rules for module dependencies';

  @override
  void execute(List<String> arguments) {
    Logger.info('Checking architecture rules...');
    Logger.info('');

    final currentDir = Directory.current.path;

    // Parse package.dart
    final packageFile = File('$currentDir/package.dart');
    if (!packageFile.existsSync()) {
      Logger.error('package.dart not found');
      exit(1);
    }
    final packageData =
        GenFileGenerator.parsePackageDart(packageFile.readAsStringSync());

    // Parse project.dart
    final projectData = ProjectParser.parse(currentDir);
    if (projectData == null) {
      Logger.error('Failed to parse project.dart');
      exit(1);
    }

    // Run checks
    final checker = ArchitectureChecker(
      project: projectData,
      package: packageData,
    );
    final results = checker.check();

    // Display results
    int errorCount = 0;
    int okCount = 0;

    for (final result in results) {
      switch (result.severity) {
        case CheckSeverity.error:
          Logger.error('[ERROR] ${result.rule}');
          Logger.error('  ${result.message}');
          Logger.info('');
          errorCount++;
          break;
        case CheckSeverity.ok:
          Logger.success('[OK] ${result.message}');
          okCount++;
          break;
      }
    }

    Logger.info('');

    if (errorCount > 0) {
      Logger.error('$errorCount error(s), $okCount passed.');
      if (projectData.options.strictMode) {
        exit(1);
      } else {
        Logger.warn('strictMode is false — violations are reported but not enforced.');
      }
    } else {
      Logger.success('All checks passed. ($okCount passed)');
    }
  }
}
