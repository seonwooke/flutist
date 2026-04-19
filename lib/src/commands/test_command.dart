import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../utils/utils.dart';
import 'commands.dart';

/// Command to run tests across all modules in parallel.
class TestCommand implements BaseCommand {
  @override
  String get name => 'test';

  @override
  String get description => 'Run tests for all modules';

  @override
  void execute(List<String> arguments) async {
    final parser = ArgParser()
      ..addOption(
        'module',
        abbr: 'm',
        help: 'Run tests for a specific module only',
      )
      ..addFlag(
        'help',
        abbr: 'h',
        help: 'Show help information',
        negatable: false,
      );

    try {
      final result = parser.parse(arguments);

      if (result['help'] as bool) {
        _showHelp();
        return;
      }

      final targetModule = result['module'] as String?;
      final currentDir = Directory.current.path;

      // Find all module directories with test/ folders
      final testTargets = _findTestTargets(currentDir, targetModule);

      if (testTargets.isEmpty) {
        if (targetModule != null) {
          Logger.error('Module "$targetModule" not found or has no test/ directory.');
          exit(1);
        }
        Logger.warn('No test targets found.');
        return;
      }

      Logger.info('Running tests for ${testTargets.length} module(s)...');
      Logger.info('');

      // Run all tests in parallel
      final futures = <Future<_TestResult>>[];
      for (final target in testTargets) {
        futures.add(_runModuleTest(target));
      }

      final results = await Future.wait(futures);

      // Display results
      Logger.info('');
      _displayResults(results);

      // Exit with error if any failed
      final hasFailure = results.any((r) => !r.passed);
      if (hasFailure) {
        exit(1);
      }
    } catch (e) {
      Logger.error('Failed to run tests: $e');
      exit(1);
    }
  }

  void _showHelp() {
    print('''
COMMAND: test
DESCRIPTION: Run tests for all modules

USAGE:
  flutist test [options]

OPTIONS:
  -m, --module <name>   Run tests for a specific module only
  -h, --help            Show help information

EXAMPLES:
  flutist test
  flutist test --module login
''');
  }

  /// Finds all module directories that contain a test/ folder.
  List<_TestTarget> _findTestTargets(String rootDir, String? targetModule) {
    final targets = <_TestTarget>[];

    // Recursively search for directories containing both pubspec.yaml and test/
    _searchForTestTargets(Directory(rootDir), rootDir, targets);

    if (targetModule != null) {
      return targets.where((t) => t.name == targetModule).toList();
    }

    return targets;
  }

  void _searchForTestTargets(
    Directory dir,
    String rootDir,
    List<_TestTarget> targets,
  ) {
    // Skip hidden directories and build artifacts
    final dirName = p.basename(dir.path);
    if (dirName.startsWith('.') || dirName == 'build' || dirName == 'flutist') {
      return;
    }

    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    final testDir = Directory(p.join(dir.path, 'test'));

    if (pubspec.existsSync() && testDir.existsSync()) {
      // Don't include root project itself
      if (dir.path != rootDir) {
        targets.add(_TestTarget(
          name: p.basename(dir.path),
          path: dir.path,
        ));
      }
    }

    // Continue searching subdirectories
    try {
      for (final entity in dir.listSync()) {
        if (entity is Directory) {
          _searchForTestTargets(entity, rootDir, targets);
        }
      }
    } catch (e) {
      if (e is FileSystemException) {
        Logger.warn('Skipped directory (permission denied): ${dir.path}');
      }
    }
  }

  /// Detects whether a module requires flutter test or dart test.
  ///
  /// Returns true if the module (or any of its path dependencies) declares
  /// `flutter: sdk: flutter` in dependencies or `flutter_test: sdk: flutter`
  /// in dev_dependencies. This ensures that test-only packages that depend on
  /// Flutter implementation packages are also detected correctly.
  bool _isFlutterModule(String modulePath) {
    return _isFlutterModuleYaml(modulePath, {});
  }

  bool _isFlutterModuleYaml(String modulePath, Set<String> visited) {
    if (visited.contains(modulePath)) return false;
    visited.add(modulePath);

    final pubspecFile = File(p.join(modulePath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) return false;
    try {
      final content = pubspecFile.readAsStringSync();
      final yaml = loadYaml(content) as Map?;

      final deps = yaml?['dependencies'] as Map?;
      final flutter = deps?['flutter'];
      if (flutter is Map && flutter['sdk'] == 'flutter') return true;

      final devDeps = yaml?['dev_dependencies'] as Map?;
      final flutterTest = devDeps?['flutter_test'];
      if (flutterTest is Map && flutterTest['sdk'] == 'flutter') return true;

      // Check path dependencies one level deeper
      final allDeps = <String, dynamic>{
        if (deps != null) ...deps.cast<String, dynamic>(),
        if (devDeps != null) ...devDeps.cast<String, dynamic>(),
      };
      for (final entry in allDeps.entries) {
        final value = entry.value;
        if (value is Map && value['path'] is String) {
          final depPath = p.normalize(p.join(modulePath, value['path'] as String));
          if (_isFlutterModuleYaml(depPath, visited)) return true;
        }
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Runs dart test or flutter test in a module directory.
  Future<_TestResult> _runModuleTest(_TestTarget target) async {
    final useFlutter = _isFlutterModule(target.path);
    final process = await Process.start(
      useFlutter ? 'flutter' : 'dart',
      ['test'],
      workingDirectory: target.path,
    );

    // Start draining stdout/stderr immediately, but await them after exitCode
    // so the buffers are fully collected before we return — `listen` + reading
    // `StringBuffer.toString()` right after `process.exitCode` races against
    // the transform pipeline and can truncate the final chunks.
    final stdoutFuture =
        process.stdout.transform(const SystemEncoding().decoder).join();
    final stderrFuture =
        process.stderr.transform(const SystemEncoding().decoder).join();

    final exitCode = await process.exitCode;

    return _TestResult(
      target: target,
      passed: exitCode == 0,
      output: await stdoutFuture,
      error: await stderrFuture,
    );
  }

  /// Displays test results summary.
  void _displayResults(List<_TestResult> results) {
    int passedModules = 0;
    int failedModules = 0;

    for (final result in results) {
      if (result.passed) {
        Logger.success('[✓] ${result.target.name}');
        passedModules++;
      } else {
        Logger.error('[✗] ${result.target.name}');
        if (result.output.isNotEmpty) {
          for (final line in result.output.trimRight().split('\n')) {
            Logger.error('  $line');
          }
        }
        if (result.error.isNotEmpty) {
          for (final line in result.error.trimRight().split('\n')) {
            Logger.error('  $line');
          }
        }
        failedModules++;
      }
    }

    Logger.info('');
    if (failedModules > 0) {
      Logger.error(
          'Results: $passedModules passed, $failedModules failed.');
    } else {
      Logger.success('Results: $passedModules passed, all tests passed!');
    }
  }
}

class _TestTarget {
  final String name;
  final String path;

  _TestTarget({required this.name, required this.path});
}

class _TestResult {
  final _TestTarget target;
  final bool passed;
  final String output;
  final String error;

  _TestResult({
    required this.target,
    required this.passed,
    required this.output,
    required this.error,
  });
}
