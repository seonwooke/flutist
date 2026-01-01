import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../generator/flutist_generator.dart';
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
      Logger.info('Usage: flutist pub add <package_name>');
      exit(1);
    }

    final packageName = arguments[0];
    final rootPath = Directory.current.path;
    final packageDartPath = path.join(rootPath, 'package.dart');

    // Check if package.dart exists
    if (!File(packageDartPath).existsSync()) {
      Logger.error('package.dart not found.');
      Logger.info('Run "flutist init" first to create package.dart');
      exit(1);
    }

    try {
      Logger.info('Adding dependency: $packageName');

      // Get latest version using dart pub add
      final version = await _getLatestVersion(packageName, rootPath);

      if (version == null) {
        Logger.error('Failed to get version for package: $packageName');
        exit(1);
      }

      Logger.info('Found version: $version');

      // Read and parse package.dart
      final packageContent = await File(packageDartPath).readAsString();
      final updatedContent =
          _addDependencyToPackage(packageContent, packageName, version);

      // Write updated content
      await File(packageDartPath).writeAsString(updatedContent);

      Logger.success('Added $packageName ($version) to package.dart');

      // Generate flutist_gen.dart
      GenFileGenerator.generate(rootPath);

      Logger.success('Generated flutist_gen.dart');
    } catch (e) {
      Logger.error('Failed to add dependency: $e');
      exit(1);
    }
  }

  /// Gets the latest version of a package using dart pub add.
  Future<String?> _getLatestVersion(String packageName, String rootPath) async {
    // Create a temporary directory for pub add
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

      // Run dart pub add
      final result = await Process.run(
        'dart',
        ['pub', 'add', packageName],
        workingDirectory: tempDir.path,
      );

      if (result.exitCode != 0) {
        Logger.error('Failed to get package version: ${result.stderr}');
        return null;
      }

      // Read pubspec.yaml to get the version
      final pubspecContent = await File(tempPubspecPath).readAsString();
      final pubspec = loadYaml(pubspecContent) as Map;

      final dependencies = pubspec['dependencies'] as Map?;
      if (dependencies == null || !dependencies.containsKey(packageName)) {
        return null;
      }

      final version = dependencies[packageName];
      if (version is String) {
        return version;
      } else if (version is Map) {
        // Handle path, git, etc.
        return 'any';
      }

      return null;
    } finally {
      // Clean up temp directory
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
      r"Dependency\s*\(\s*name:\s*'$packageName'\s*,\s*version:\s*'[^']+'\s*\)",
    );

    if (existingPattern.hasMatch(packageContent)) {
      // Update existing dependency
      return packageContent.replaceFirst(
        existingPattern,
        "Dependency(name: '$packageName', version: '$version')",
      );
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

    return packageContent.substring(0, dependenciesStart) +
        newDependency +
        packageContent.substring(dependenciesEnd);
  }
}
