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
    if (arguments.contains('--help') || arguments.contains('-h')) {
      HelpCommand().execute([name]);
      return;
    }
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
      case 'delete':
        await _handleDelete(subArgs);
        break;
      default:
        Logger.error('Unknown subcommand: $subcommand');
        Logger.info('Available subcommands: add, delete');
        exit(1);
    }
  }

  /// Handles the 'delete' subcommand.
  ///
  /// Removes one or more dependencies from package.dart. Any matching
  /// `package.dependencies.xxx` entries in project.dart are also removed so
  /// no dangling references remain. The full plan is printed first; the
  /// user confirms at the y/n prompt, or passes `-y` for scripts.
  Future<void> _handleDelete(List<String> arguments) async {
    var dryRun = false;
    var skipConfirm = false;
    final packageNames = <String>[];

    for (final arg in arguments) {
      switch (arg) {
        case '--dry-run':
          dryRun = true;
          break;
        case '-y':
        case '--yes':
          skipConfirm = true;
          break;
        default:
          if (arg.startsWith('-')) {
            Logger.error('Unknown flag: $arg');
            Logger.info(
                'Usage: flutist pub delete <package_name> [--dry-run] [-y]');
            exit(1);
          }
          packageNames.add(arg);
      }
    }

    if (packageNames.isEmpty) {
      Logger.error('No package name provided.');
      Logger.info(
          'Usage: flutist pub delete <package_name> [<package_name2> ...] [--dry-run] [-y]');
      exit(1);
    }

    final rootPath = Directory.current.path;
    final packageDartPath = path.join(rootPath, 'package.dart');
    final projectDartPath = path.join(rootPath, 'project.dart');

    if (!File(packageDartPath).existsSync()) {
      Logger.error('package.dart not found.');
      Logger.info('Run "flutist init" first to create package.dart');
      exit(1);
    }

    var packageContent = await File(packageDartPath).readAsString();
    final projectExists = File(projectDartPath).existsSync();
    var projectContent =
        projectExists ? await File(projectDartPath).readAsString() : '';

    // Step 1: verify every requested package exists in package.dart.
    final missing = <String>[];
    for (final name in packageNames) {
      if (!_dependencyExists(packageContent, name)) {
        missing.add(name);
      }
    }
    if (missing.isNotEmpty) {
      Logger.error(
          'Not found in package.dart: ${missing.join(', ')}');
      exit(1);
    }

    // Step 2: collect usages from project.dart.
    final usagesByPkg = <String, List<String>>{};
    if (projectExists) {
      for (final name in packageNames) {
        usagesByPkg[name] = _findDependencyUsages(projectContent, name);
      }
    }

    final hasAnyUsage = usagesByPkg.values.any((u) => u.isNotEmpty);

    // Step 3: print the full plan. References in project.dart are listed
    // so the user can see exactly what will be touched before confirming.
    Logger.info('Will remove from package.dart:');
    for (final name in packageNames) {
      Logger.info('  - $name');
    }
    if (hasAnyUsage) {
      Logger.info('Will remove references in project.dart:');
      for (final entry in usagesByPkg.entries) {
        if (entry.value.isEmpty) continue;
        Logger.info('  - ${entry.key} (from: ${entry.value.join(', ')})');
      }
    }

    if (dryRun) {
      Logger.info('--dry-run set; no files changed.');
      return;
    }

    // Step 4: confirm.
    if (!skipConfirm) {
      Logger.info('');
      Logger.info('Proceed? (y/n)');
      final answer = stdin.readLineSync()?.trim().toLowerCase();
      if (answer != 'y' && answer != 'yes') {
        Logger.info('Aborted.');
        return;
      }
    }

    // Step 5: rewrite package.dart and project.dart.
    var updatedPackage = packageContent;
    for (final name in packageNames) {
      updatedPackage = _removeDependencyFromPackage(updatedPackage, name);
    }
    await File(packageDartPath).writeAsString(updatedPackage);
    Logger.success('Updated package.dart');

    if (projectExists && hasAnyUsage) {
      var updatedProject = projectContent;
      for (final name in packageNames) {
        updatedProject = _removeDependencyReferences(updatedProject, name);
      }
      await File(projectDartPath).writeAsString(updatedProject);
      Logger.success('Updated project.dart');
    }

    GenFileGenerator.generate(rootPath);

    for (final name in packageNames) {
      Logger.success('Removed $name from package.dart');
    }
  }

  /// Returns true if [packageContent] contains a Dependency entry named [pkg].
  bool _dependencyExists(String packageContent, String pkg) {
    final pattern = RegExp(
      "Dependency\\s*\\(\\s*name:\\s*'$pkg'\\s*,\\s*version:\\s*'[^']+'\\s*\\)",
    );
    return pattern.hasMatch(packageContent);
  }

  /// Returns the list of module names in project.dart that reference [pkg]
  /// via `package.dependencies.<camelCase>`. Comment lines are skipped.
  List<String> _findDependencyUsages(String projectContent, String pkg) {
    final camel = StringCase.toCamelCase(pkg);
    final usages = <String>[];

    final modulePattern = RegExp(r'Module\s*\((.*?)\),', dotAll: true);
    for (final match in modulePattern.allMatches(projectContent)) {
      final body = match.group(1)!;
      final nameMatch = RegExp(r"name:\s*'([^']+)'").firstMatch(body);
      if (nameMatch == null) continue;

      // Strip comment lines to mirror ProjectParser behavior.
      final stripped = body
          .split('\n')
          .where((line) => !line.trim().startsWith('//'))
          .join('\n');
      final refPattern = RegExp('package\\.dependencies\\.$camel\\b');
      if (refPattern.hasMatch(stripped)) {
        usages.add(nameMatch.group(1)!);
      }
    }
    return usages;
  }

  /// Removes the `Dependency(name: 'pkg', version: '...')` line from
  /// [packageContent], including the trailing comma and the preceding
  /// indentation/newline so the surrounding block stays clean.
  String _removeDependencyFromPackage(String packageContent, String pkg) {
    final pattern = RegExp(
      "(?:^|\\n)[ \\t]*Dependency\\s*\\(\\s*name:\\s*'$pkg'\\s*,\\s*version:\\s*'[^']+'\\s*\\)\\s*,?[ \\t]*(?=\\n|\$)",
      multiLine: true,
    );
    return packageContent.replaceFirst(pattern, '');
  }

  /// Removes `package.dependencies.<camelCase>` references from project.dart
  /// so that no dangling references remain after the dependency is deleted.
  ///
  /// Handles both forms users actually write:
  ///   1. Own-line multi-line list:
  ///        dependencies: [
  ///          package.dependencies.flutterBloc,
  ///        ],
  ///   2. Inline list on a single line:
  ///        dependencies: [package.dependencies.flutterBloc],
  ///        dependencies: [package.dependencies.a, package.dependencies.b],
  String _removeDependencyReferences(String projectContent, String pkg) {
    final camel = StringCase.toCamelCase(pkg);
    final ref = 'package\\.dependencies\\.$camel\\b';
    var result = projectContent;

    // 1. Own-line form in a multi-line list. Eats the line including its
    //    trailing comma, but leaves the trailing newline so adjacent lines
    //    keep their formatting.
    result = result.replaceAll(
      RegExp('\\n[ \\t]*$ref[ \\t]*,?[ \\t]*(?=\\n)'),
      '',
    );

    // 2. Inline form, ref followed by a comma (first or middle item).
    result = result.replaceAll(RegExp('$ref[ \\t]*,[ \\t]*'), '');

    // 3. Inline form, ref preceded by a comma (last item, no trailing comma).
    result = result.replaceAll(RegExp('[ \\t]*,[ \\t]*$ref'), '');

    // 4. Ref alone in the list (only entry).
    result = result.replaceAll(RegExp(ref), '');

    return result;
  }

  /// Handles the 'add' subcommand.
  Future<void> _handleAdd(List<String> arguments) async {
    String? versionConstraint;
    final packageNames = <String>[];
    for (var i = 0; i < arguments.length; i++) {
      final arg = arguments[i];
      if (arg == '--version') {
        if (i + 1 >= arguments.length) {
          Logger.error('--version requires a value.');
          Logger.info(
              'Usage: flutist pub add <package_name> --version <constraint>');
          exit(1);
        }
        versionConstraint = arguments[i + 1];
        i++;
      } else if (arg.startsWith('--version=')) {
        versionConstraint = arg.substring('--version='.length);
      } else {
        packageNames.add(arg);
      }
    }

    if (packageNames.isEmpty) {
      Logger.error('No package name provided.');
      Logger.info(
          'Usage: flutist pub add <package_name> [<package_name2> ...] [--version <constraint>]');
      exit(1);
    }

    if (versionConstraint != null && packageNames.length > 1) {
      Logger.error('--version can only be used with a single package.');
      Logger.info(
          'Got ${packageNames.length} packages: ${packageNames.join(', ')}');
      Logger.info(
          'Usage: flutist pub add <package_name> --version <constraint>');
      exit(1);
    }

    final pubAddArgs = versionConstraint != null
        ? ['${packageNames[0]}:$versionConstraint']
        : packageNames;

    final rootPath = Directory.current.path;
    final packageDartPath = path.join(rootPath, 'package.dart');

    // Check if package.dart exists
    if (!File(packageDartPath).existsSync()) {
      Logger.error('package.dart not found.');
      Logger.info('Run "flutist init" first to create package.dart');
      exit(1);
    }

    try {
      Logger.info('Resolving versions for: ${packageNames.join(', ')}');

      // Batch-resolve all packages in a single dart pub add call
      final versions =
          await _getAllVersions(pubAddArgs, packageNames, rootPath);

      if (versions == null) {
        exit(1);
      }

      for (final packageName in packageNames) {
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

  /// Resolves versions for [packageNames] by running `dart pub add [pubAddArgs]`
  /// in a temp project. [pubAddArgs] may carry `:constraint` suffixes that
  /// [packageNames] do not, since the resulting pubspec keys are plain names.
  Future<Map<String, String>?> _getAllVersions(
      List<String> pubAddArgs,
      List<String> packageNames,
      String rootPath) async {
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
        ['pub', 'add', ...pubAddArgs],
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
      for (final packageName in packageNames) {
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
