import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../core/core.dart';
import '../engine/engine.dart';
import '../utils/utils.dart';
import 'commands.dart';

class GenerateCommand implements BaseCommand {
  @override
  String get name => 'generate';

  @override
  String get description =>
      'Sync all pubspec.yaml files based on project.dart.';

  /// Runs the generation pipeline.
  ///
  /// [removedDependencies] names dependencies that were just deleted from
  /// package.dart by the calling command. Flutist can no longer tell from
  /// package.dart that it once owned them, so they would be mistaken for
  /// user-authored entries and left behind in each module's pubspec.yaml.
  /// Naming them here clears them out.
  @override
  void execute(
    List<String> arguments, {
    Set<String> removedDependencies = const {},
  }) {
    if (arguments.contains('--help') || arguments.contains('-h')) {
      HelpCommand().execute([name]);
      return;
    }
    Logger.info('Starting Flutist generation...');

    try {
      final currentDir = Directory.current.path;

      // Step 1: Parse package.dart
      final packageData = _parsePackageDart(currentDir);

      if (packageData == null) {
        Logger.error('Failed to parse package.dart');
        exit(1);
      }

      Logger.success('Parsed package.dart');
      Logger.info('  Dependencies: ${packageData.dependencies.length}');
      Logger.info('  Modules: ${packageData.modules.length}');

      // Step 2: Parse project.dart
      final projectData = ProjectParser.parse(currentDir);

      if (projectData == null) {
        Logger.error('Failed to parse project.dart');
        exit(1);
      }

      Logger.success('Parsed project.dart');
      Logger.info('  Modules: ${projectData.modules.length}');

      // Step 3: Architecture rule check (always runs; strictMode controls whether to abort)
      Logger.info('Checking architecture rules...');
      final checker = ArchitectureChecker(
        project: projectData,
        package: packageData,
      );
      final results = checker.check();
      final errors = results
          .where((r) => r.severity == CheckSeverity.error)
          .toList();

      if (errors.isNotEmpty) {
        Logger.info('');
        for (final error in errors) {
          Logger.error('[ERROR] ${error.rule}');
          Logger.error('  ${error.message}');
          Logger.info('');
        }
        if (projectData.options.strictMode) {
          Logger.error(
              'Generation aborted. ${errors.length} architecture violation(s) found.');
          Logger.info('Fix violations or set strictMode: false in ProjectOptions.');
          exit(1);
        } else {
          Logger.warn(
              '${errors.length} architecture violation(s) found. Continuing because strictMode is false.');
        }
      } else {
        Logger.success('Architecture rules passed');
      }

      // Step 4: Generate flutist_gen.dart (pass pre-parsed package to avoid re-parsing)
      final projectModuleNames =
          projectData.modules.map((m) => m.name).toList();
      GenFileGenerator.generate(currentDir,
          packageData: packageData, projectModuleNames: projectModuleNames);

      // Step 4: Update pubspec.yaml files
      _updatePubspecFiles(
          currentDir, projectData, packageData, removedDependencies);

      Logger.success('Generation completed!');
    } catch (e) {
      Logger.error('Generation failed: $e');
      exit(1);
    }
  }

  /// Parses the package.dart file.
  Package? _parsePackageDart(String currentDir) {
    Logger.info('Parsing package.dart...');

    final packageFile = File('$currentDir/package.dart');

    if (!packageFile.existsSync()) {
      Logger.error('package.dart not found');
      return null;
    }

    try {
      final content = packageFile.readAsStringSync();
      return GenFileGenerator.parsePackageDart(content);
    } catch (e) {
      Logger.error(ErrorHelper.describe(e, 'package.dart'));
      return null;
    }
  }



  /// Builds a map of module name → absolute directory path by scanning
  /// workspace entries in root pubspec.yaml and reading each module's
  /// pubspec.yaml name field.
  Map<String, String> _buildModulePathMap(String currentDir) {
    final map = <String, String>{};
    final rootPubspecFile = File('$currentDir/pubspec.yaml');

    if (!rootPubspecFile.existsSync()) return map;

    try {
      final content = rootPubspecFile.readAsStringSync();
      final yamlDoc = loadYaml(content) as Map;
      final workspace = yamlDoc['workspace'];

      if (workspace == null) {
        Logger.warn(
            'No `workspace:` section in pubspec.yaml. Add modules via `flutist create` before running generate.');
        return map;
      }
      if (workspace is! List) {
        Logger.warn(
            '`workspace:` in pubspec.yaml is not a list. Generation will skip module resolution.');
        return map;
      }

      for (final entry in workspace) {
        final entryPath = '$currentDir/$entry';
        final pubspecFile = File('$entryPath/pubspec.yaml');

        if (pubspecFile.existsSync()) {
          try {
            final pubspecContent = pubspecFile.readAsStringSync();
            final pubspecYaml = loadYaml(pubspecContent) as Map;
            final name = pubspecYaml['name'] as String?;
            if (name != null) {
              map[name] = entryPath;
            }
          } catch (e) {
            Logger.warn('Skipped unparseable pubspec.yaml at $entryPath: $e');
          }
        }
      }
    } catch (e) {
      Logger.warn('Failed to build module path map: $e');
    }

    return map;
  }

  /// Updates pubspec.yaml files for all modules.
  void _updatePubspecFiles(String currentDir, Project project, Package package,
      Set<String> removedDependencies) {
    Logger.info('Updating pubspec.yaml files...');

    // Build module path map from workspace once
    final modulePathMap = _buildModulePathMap(currentDir);

    for (final module in project.modules) {
      _updateModulePubspec(
          currentDir, module, package, modulePathMap, removedDependencies);
    }

    Logger.success('Updated all pubspec.yaml files');
  }

  /// Updates pubspec.yaml for a single module.
  void _updateModulePubspec(
    String currentDir,
    Module module,
    Package package,
    Map<String, String> modulePathMap,
    Set<String> removedDependencies,
  ) {
    // Find the module's pubspec.yaml location
    final moduleDirPath = modulePathMap[module.name];

    if (moduleDirPath == null) {
      Logger.warn('Could not find module: ${module.name}');
      return;
    }

    final pubspecPath = '$moduleDirPath/pubspec.yaml';

    Logger.info('Updating ${module.name}/pubspec.yaml...');

    final pubspecFile = File(pubspecPath);

    if (!pubspecFile.existsSync()) {
      Logger.warn('pubspec.yaml not found: $pubspecPath');
      return;
    }

    try {
      final content = pubspecFile.readAsStringSync();
      final editor = YamlEditor(content);

      // Names Flutist owns. Anything outside this set was written by the
      // user and is preserved as-is.
      final managedNames =
          _managedNames(package, modulePathMap, removedDependencies);

      // Clear and rebuild dependencies section
      _rebuildDependenciesSection(currentDir, editor, module, package,
          pubspecPath, modulePathMap, managedNames);

      // Clear and rebuild dev_dependencies section
      _rebuildDevDependenciesSection(
          currentDir, editor, module, package, pubspecPath, managedNames);

      // Write back to file with formatting
      final updatedContent = _formatPubspecContent(editor.toString());
      pubspecFile.writeAsStringSync(updatedContent);
      Logger.success('  Updated ${module.name}');
    } catch (e) {
      Logger.error('Failed to update ${module.name}: $e');
    }
  }

  /// Gets the declaration for a dependency from package.dart.
  Dependency? _lookupDependency(Package package, String dependencyName) {
    for (final dep in package.dependencies) {
      if (dep.name == dependencyName) return dep;
    }
    return null;
  }

  /// Every name Flutist manages: dependencies and modules declared in
  /// package.dart, plus every module present in the workspace.
  ///
  /// Entries in a module's pubspec.yaml whose name falls outside this set
  /// were added by the user (a local path package, a git package, a
  /// hand-written pub dependency) and must survive generation untouched.
  Set<String> _managedNames(
    Package package,
    Map<String, String> modulePathMap,
    Set<String> removedDependencies,
  ) {
    return <String>{
      ...package.dependencies.map((d) => d.name),
      ...package.modules.map((m) => m.name),
      ...modulePathMap.keys,
      ...removedDependencies,
    };
  }

  /// Builds the pubspec.yaml value for [dep] as seen from [moduleDirPath].
  ///
  /// Path dependencies are declared in package.dart relative to the project
  /// root, so the path is re-anchored to the consuming module here.
  dynamic _pubspecValueFor(
    String currentDir,
    Dependency dep,
    String moduleDirPath,
  ) {
    switch (dep.kind) {
      case DependencyKind.hosted:
        return dep.version;

      case DependencyKind.path:
        final absolute = path.normalize(path.join(currentDir, dep.path!));
        return {'path': path.relative(absolute, from: moduleDirPath)};

      case DependencyKind.git:
        if (dep.gitRef == null && dep.gitPath == null) {
          return {'git': dep.gitUrl};
        }
        return {
          'git': {
            'url': dep.gitUrl,
            if (dep.gitRef != null) 'ref': dep.gitRef,
            if (dep.gitPath != null) 'path': dep.gitPath,
          }
        };
    }
  }

  /// Human-readable summary of a resolved dependency, for the generation log.
  String _describeDependency(Dependency dep, dynamic value) {
    switch (dep.kind) {
      case DependencyKind.hosted:
        return '${dep.name} ($value)';
      case DependencyKind.path:
        return '${dep.name} (path: ${(value as Map)['path']})';
      case DependencyKind.git:
        return '${dep.name} (git: ${dep.gitUrl})';
    }
  }

  /// Collects entries in [section] that Flutist does not manage, so they can
  /// be written back untouched.
  Map<String, dynamic> _preservedEntries(
    YamlEditor editor,
    String section,
    Set<String> managedNames,
  ) {
    final preserved = <String, dynamic>{};

    try {
      final node = editor.parseAt([section]);
      if (node.value is Map) {
        for (final entry in (node.value as Map).entries) {
          final name = entry.key as String;
          if (!managedNames.contains(name)) {
            preserved[name] = entry.value;
          }
        }
      }
    } catch (e) {
      // Section doesn't exist yet
    }

    return preserved;
  }

  /// Ensures a section exists in the YAML document.
  /// If it doesn't exist, creates it as an empty map.
  /// Formats pubspec.yaml content to ensure proper blank lines.
  String _formatPubspecContent(String content) {
    // Convert inline maps to multiline
    content = _convertInlineMapsToMultiline(content);

    // Reorder sections and add blank lines
    return _reorderSections(content);
  }

  /// Converts inline YAML maps to multiline format.
  String _convertInlineMapsToMultiline(String content) {
    // Convert dev_dependencies: {key: value} to multiline
    final devDepsPattern = RegExp(r'dev_dependencies:\s*\{([^}]+)\}');
    content = content.replaceAllMapped(devDepsPattern, (match) {
      final items = match.group(1)!.split(',');
      final buffer = StringBuffer('dev_dependencies:\n');

      for (final item in items) {
        final trimmed = item.trim();
        if (trimmed.isNotEmpty) {
          buffer.writeln('  $trimmed');
        }
      }

      return buffer.toString().trimRight();
    });

    // Convert dependencies: {} to dependencies: (empty section)
    content = content.replaceAll(
      RegExp(r'^dependencies:\s*\{\s*\}', multiLine: true),
      'dependencies:',
    );

    // Convert dependencies: {key: value} to multiline (if any)
    final depsPattern =
        RegExp(r'^dependencies:\s*\{([^}]+)\}', multiLine: true);
    content = content.replaceAllMapped(depsPattern, (match) {
      final items = match.group(1)!.split(',');
      final buffer = StringBuffer('dependencies:\n');

      for (final item in items) {
        final trimmed = item.trim();
        if (trimmed.isNotEmpty) {
          buffer.writeln('  $trimmed');
        }
      }

      return buffer.toString().trimRight();
    });

    return content;
  }

  /// Reorders sections in pubspec.yaml to ensure proper structure.
  String _reorderSections(String content) {
    final lines = content.split('\n');
    final sections = <String, List<String>>{
      'header': [],
      'environment': [],
      'dependencies': [],
      'dev_dependencies': [],
      'resolution': [],
    };

    String currentSection = 'header';

    for (final line in lines) {
      final trimmed = line.trim();

      // Skip empty lines during parsing (we'll add them back properly)
      if (trimmed.isEmpty) {
        continue;
      }

      if (trimmed.startsWith('environment:')) {
        currentSection = 'environment';
        sections[currentSection]!.add(line);
      } else if (trimmed.startsWith('dependencies:')) {
        currentSection = 'dependencies';
        sections[currentSection]!.add(line);
      } else if (trimmed.startsWith('dev_dependencies:')) {
        currentSection = 'dev_dependencies';
        sections[currentSection]!.add(line);
      } else if (trimmed.startsWith('resolution:')) {
        currentSection = 'resolution';
        sections[currentSection]!.add(line);
      } else {
        sections[currentSection]!.add(line);
      }
    }

    // Build final content with proper order and exactly one blank line between sections
    final result = <String>[];

    // Header
    if (sections['header']!.isNotEmpty) {
      result.addAll(sections['header']!);
    }

    // Environment (with one blank line before)
    if (sections['environment']!.isNotEmpty) {
      result.add('');
      result.addAll(sections['environment']!);
    }

    // Dependencies (with one blank line before)
    if (sections['dependencies']!.isNotEmpty) {
      result.add('');
      result.addAll(sections['dependencies']!);
    }

    // Dev Dependencies (with one blank line before)
    if (sections['dev_dependencies']!.isNotEmpty) {
      result.add('');
      result.addAll(sections['dev_dependencies']!);
    }

    // Resolution (with one blank line before)
    if (sections['resolution']!.isNotEmpty) {
      result.add('');
      result.addAll(sections['resolution']!);
    }

    return result.join('\n');
  }

  /// Rebuilds the dependencies section completely.
  void _rebuildDependenciesSection(
    String currentDir,
    YamlEditor editor,
    Module module,
    Package package,
    String pubspecPath,
    Map<String, String> modulePathMap,
    Set<String> managedNames,
  ) {
    final currentModuleDir = path.dirname(pubspecPath);

    // Entries Flutist does not own (SDK deps like flutter, and anything the
    // user added by hand) are carried over untouched.
    final allDeps = <String, dynamic>{};
    allDeps.addAll(_preservedEntries(editor, 'dependencies', managedNames));

    // Add dependencies from project.dart
    for (final dep in module.dependencies) {
      final declared = _lookupDependency(package, dep.name);
      if (declared == null) {
        Logger.warn('  ⚠ Not declared in package.dart: ${dep.name}');
        continue;
      }
      final value = _pubspecValueFor(currentDir, declared, currentModuleDir);
      allDeps[dep.name] = value;
      Logger.info(
          '  ✓ Added dependency: ${_describeDependency(declared, value)}');
    }

    // Add module dependencies (with calculated relative path)

    for (final modDep in module.modules) {
      // Skip self-reference
      if (modDep.name == module.name) {
        Logger.warn('  ⚠ Skipping self-reference: ${modDep.name}');
        continue;
      }

      final targetModuleDir = modulePathMap[modDep.name];

      if (targetModuleDir != null) {
        // Calculate relative path
        final relativePath =
            path.relative(targetModuleDir, from: currentModuleDir);

        allDeps[modDep.name] = {'path': relativePath};
        Logger.info('  ✓ Added module: ${modDep.name} (path: $relativePath)');
      } else {
        Logger.warn('  ⚠ Could not find module: ${modDep.name}');
      }
    }

    // Update dependencies section (even if empty, we'll format it in _formatPubspecContent)
    try {
      editor.update(['dependencies'], allDeps);
    } catch (e) {
      // Section doesn't exist, create it
      editor.update(['dependencies'], allDeps);
    }
  }

  /// Rebuilds the dev_dependencies section completely.
  void _rebuildDevDependenciesSection(
    String currentDir,
    YamlEditor editor,
    Module module,
    Package package,
    String pubspecPath,
    Set<String> managedNames,
  ) {
    final currentModuleDir = path.dirname(pubspecPath);

    // Preserve existing entries that flutist does not manage
    // (SDK deps like flutter_test, user-added deps like flutter_lints, and
    // any local path or git package the user wired up by hand).
    final preserved =
        _preservedEntries(editor, 'dev_dependencies', managedNames);

    if (module.devDependencies.isEmpty && preserved.isEmpty) {
      // Remove dev_dependencies section only if truly empty
      try {
        editor.remove(['dev_dependencies']);
      } catch (e) {
        // Section doesn't exist, that's fine
      }
      return;
    }

    // Collect all dev dependencies: preserved first, then flutist-managed
    final allDevDeps = <String, dynamic>{};
    allDevDeps.addAll(preserved);

    for (final devDep in module.devDependencies) {
      final declared = _lookupDependency(package, devDep.name);
      if (declared == null) {
        Logger.warn('  ⚠ Not declared in package.dart: ${devDep.name}');
        continue;
      }
      final value = _pubspecValueFor(currentDir, declared, currentModuleDir);
      allDevDeps[devDep.name] = value;
      Logger.info(
          '  ✓ Added dev_dependency: ${_describeDependency(declared, value)}');
    }

    // Update dev_dependencies section
    try {
      editor.update(['dev_dependencies'], allDevDeps);
    } catch (e) {
      editor.update(['dev_dependencies'], allDevDeps);
    }
  }

}
