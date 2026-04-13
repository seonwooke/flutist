import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../engine/engine.dart';
import '../utils/utils.dart';
import 'commands.dart';

class PubCommand implements BaseCommand {
  @override
  String get name => 'pub';

  @override
  String get description => 'Manage dependencies in package.dart.';

  @override
  void execute(List<String> arguments) async {
    if (arguments.isEmpty) {
      Logger.error('No subcommand provided.');
      Logger.info('Usage: flutist pub add <package_name>');
      exit(1);
    }

    final subcommand = arguments[0];
    final subArgs = arguments.skip(1).toList();

    switch (subcommand) {
      case 'add':
        await _handleAdd(subArgs);
        break;
      default:
        Logger.error('Unknown subcommand: $subcommand');
        Logger.info('Available subcommands: add');
        exit(1);
    }
  }

  /// Handles the 'add' subcommand.
  Future<void> _handleAdd(List<String> arguments) async {
    if (arguments.isEmpty) {
      Logger.error('No package name provided.');
      Logger.info('Usage: flutist pub add <package_name> [<package_name2> ...]');
      exit(1);
    }

    final rootPath = Directory.current.path;
    final packageDartPath = path.join(rootPath, 'package.dart');

    // Check if package.dart exists
    if (!File(packageDartPath).existsSync()) {
      Logger.error('package.dart not found.');
      Logger.info('Run "flutist init" first to create package.dart');
      exit(1);
    }

    try {
      Logger.info('Resolving versions for: ${arguments.join(', ')}');

      // Batch-resolve all packages in a single dart pub add call
      final versions = await _getAllVersions(arguments, rootPath);

      if (versions == null) {
        exit(1);
      }

      for (final packageName in arguments) {
        final version = versions[packageName];

        if (version == null) {
          Logger.error('Could not resolve version for: $packageName');
          exit(1);
        }

        Logger.info('Found version: $packageName ($version)');

        // Read and parse package.dart
        final packageContent = await File(packageDartPath).readAsString();
        final updatedContent =
            _addDependencyToPackage(packageContent, packageName, version);

        if (updatedContent == packageContent) continue;

        // Write updated content
        await File(packageDartPath).writeAsString(updatedContent);

        Logger.success('Added $packageName ($version) to package.dart');
      }

      // Generate flutist_gen.dart once after all packages are added
      GenFileGenerator.generate(rootPath);
    } catch (e) {
      Logger.error('Failed to add dependency: $e');
      exit(1);
    }
  }

  /// Resolves the latest versions of all [packages] in a single dart pub add call.
  Future<Map<String, String>?> _getAllVersions(
      List<String> packages, String rootPath) async {
    final tempDir = Directory(path.join(rootPath, '.flutist_temp'));
    try {
      if (!tempDir.existsSync()) {
        tempDir.createSync(recursive: true);
      }

      // Create a temporary pubspec.yaml
      final tempPubspecPath = path.join(tempDir.path, 'pubspec.yaml');
      await File(tempPubspecPath).writeAsString('''
name: temp_package
environment:
  sdk: ">=3.5.0 <4.0.0"
''');

      // Run dart pub add with all packages at once
      final result = await Process.run(
        'dart',
        ['pub', 'add', ...packages],
        workingDirectory: tempDir.path,
      );

      if (result.exitCode != 0) {
        // Filter internal temp package name from error output
        final errorMsg = (result.stderr as String)
            .replaceAll('temp_package', 'your project')
            .trim();
        Logger.error('Failed to resolve package versions:\n$errorMsg');
        return null;
      }

      // Read pubspec.yaml and collect all resolved versions
      final pubspecContent = await File(tempPubspecPath).readAsString();
      final pubspec = loadYaml(pubspecContent) as Map;
      final dependencies = pubspec['dependencies'] as Map?;
      if (dependencies == null) return null;

      final versions = <String, String>{};
      for (final packageName in packages) {
        final version = dependencies[packageName];
        if (version is String) {
          versions[packageName] = version;
        } else if (version is Map) {
          versions[packageName] = 'any';
        }
      }

      return versions;
    } finally {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  /// Adds a dependency to package.dart content.
  String _addDependencyToPackage(
    String packageContent,
    String packageName,
    String version,
  ) {
    // Check if dependency already exists
    final existingPattern = RegExp(
      "Dependency\\s*\\(\\s*name:\\s*'$packageName'\\s*,\\s*version:\\s*'[^']+'\\s*\\)",
    );

    if (existingPattern.hasMatch(packageContent)) {
      Logger.warn('$packageName already exists in package.dart. Skipping.');
      return packageContent;
    }

    // Find dependencies array
    final dependenciesPattern = RegExp(
      r'dependencies:\s*\[(.*?)\]',
      dotAll: true,
    );

    final match = dependenciesPattern.firstMatch(packageContent);
    if (match == null) {
      // No dependencies array found, create one
      final packageMatch =
          RegExp(r"final package = Package\(").firstMatch(packageContent);
      if (packageMatch != null) {
        final insertPos = packageMatch.end;
        return '${packageContent.substring(0, insertPos)}\n  dependencies: [\n    Dependency(name: \'$packageName\', version: \'$version\'),\n  ],${packageContent.substring(insertPos)}';
      }
      return packageContent;
    }

    final dependenciesContent = match.group(1)!;
    final fullMatch = match.group(0)!;
    final matchStart = match.start;

    // Find the position of '[' in the full match
    final bracketStart = fullMatch.indexOf('[');
    final dependenciesStart = matchStart + bracketStart + 1;

    // Find the position of ']' in the full match
    final bracketEnd = fullMatch.lastIndexOf(']');
    final dependenciesEnd = matchStart + bracketEnd;

    // Check if dependencies array is empty or has content
    final trimmedContent = dependenciesContent.trim();
    String newDependency;

    if (trimmedContent.isEmpty) {
      // Empty array
      newDependency =
          '    Dependency(name: \'$packageName\', version: \'$version\'),';
    } else {
      // Has existing dependencies
      // Remove trailing whitespace and newlines from dependenciesContent
      final cleanedContent =
          dependenciesContent.replaceAll(RegExp(r'[\s\n]+$'), '');

      // Check if there are comments (TODO, etc.)
      final hasComments = trimmedContent.contains('//');
      if (hasComments && !trimmedContent.contains('Dependency(')) {
        // Only comments, add after comments
        newDependency =
            '$cleanedContent\n    Dependency(name: \'$packageName\', version: \'$version\'),';
      } else {
        // Has dependencies, add new line
        newDependency =
            '$cleanedContent\n    Dependency(name: \'$packageName\', version: \'$version\'),';
      }
    }

    return '${packageContent.substring(0, dependenciesStart)}'
        '$newDependency'
        '\n  '
        '${packageContent.substring(dependenciesEnd)}';
  }
}
