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

  @override
  void execute(List<String> arguments) {
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

      // Step 3: Architecture rule check (if strictMode enabled)
      if (projectData.options.strictMode) {
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
          Logger.error(
              'Generation aborted. ${errors.length} architecture violation(s) found.');
          Logger.info('Fix violations or set strictMode: false in ProjectOptions.');
          exit(1);
        }
        Logger.success('Architecture rules passed');
      }

      // Step 4: Generate flutist_gen.dart (filtered by project.dart modules)
      final projectModuleNames =
          projectData.modules.map((m) => m.name).toList();
      GenFileGenerator.generate(currentDir,
          projectModuleNames: projectModuleNames);

      // Step 4: Update pubspec.yaml files
      _updatePubspecFiles(currentDir, projectData, packageData);

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
      Logger.error('Failed to parse package.dart: $e');
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

      if (workspace is! List) return map;

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
          } catch (_) {
            // Skip unparseable pubspec.yaml
          }
        }
      }
    } catch (e) {
      Logger.warn('Failed to build module path map: $e');
    }

    return map;
  }

  /// Updates pubspec.yaml files for all modules.
  void _updatePubspecFiles(
      String currentDir, Project project, Package package) {
    Logger.info('Updating pubspec.yaml files...');

    // Build module path map from workspace once
    final modulePathMap = _buildModulePathMap(currentDir);

    for (final module in project.modules) {
      _updateModulePubspec(currentDir, module, package, modulePathMap);
    }

    Logger.success('Updated all pubspec.yaml files');
  }

  /// Updates pubspec.yaml for a single module.
  void _updateModulePubspec(
    String currentDir,
    Module module,
    Package package,
    Map<String, String> modulePathMap,
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

      // Clear and rebuild dependencies section
      _rebuildDependenciesSection(
          editor, module, package, pubspecPath, modulePathMap);

      // Clear and rebuild dev_dependencies section
      _rebuildDevDependenciesSection(editor, module, package);

      // Write back to file with formatting
      final updatedContent = _formatPubspecContent(editor.toString());
      pubspecFile.writeAsStringSync(updatedContent);
      Logger.success('  Updated ${module.name}');
    } catch (e) {
      Logger.error('Failed to update ${module.name}: $e');
    }
  }

  /// Gets version for a dependency from package.dart.
  String? _getVersionFromPackage(Package package, String dependencyName) {
    try {
      final dep = package.dependencies.firstWhere(
        (d) => d.name == dependencyName,
      );
      return dep.version;
    } catch (e) {
      return null;
    }
  }

  /// Ensures a section exists in the YAML document.
  /// If it doesn't exist, creates it as an empty map.
  void _ensureSection(YamlEditor editor, String sectionName) {
    try {
      // Try to access the section
      editor.parseAt([sectionName]);
    } catch (e) {
      // Section doesn't exist, create it
      editor.update([sectionName], {});
      Logger.info('  ✓ Created $sectionName section');
    }
  }

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
    YamlEditor editor,
    Module module,
    Package package,
    String pubspecPath,
    Map<String, String> modulePathMap,
  ) {
    // Get current dependencies to preserve SDK dependencies
    final currentDeps = <String, dynamic>{};
    try {
      final depsNode = editor.parseAt(['dependencies']);
      // Convert YamlNode value to Map
      if (depsNode.value is Map) {
        final deps = depsNode.value as Map;
        // Preserve all SDK dependencies (flutter, flutter_localizations, etc.)
        for (final entry in deps.entries) {
          if (entry.value is Map &&
              (entry.value as Map).containsKey('sdk')) {
            currentDeps[entry.key as String] = entry.value;
          }
        }
      }
    } catch (e) {
      // Section doesn't exist yet
    }

    // Collect all dependencies
    final allDeps = <String, dynamic>{};
    allDeps.addAll(currentDeps);

    // Add dependencies from project.dart
    for (final dep in module.dependencies) {
      final version = _getVersionFromPackage(package, dep.name);
      if (version != null) {
        allDeps[dep.name] = version;
        Logger.info('  ✓ Added dependency: ${dep.name} ($version)');
      }
    }

    // Add module dependencies (with calculated relative path)
    final currentModuleDir = path.dirname(pubspecPath);

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
    YamlEditor editor,
    Module module,
    Package package,
  ) {
    if (module.devDependencies.isEmpty) {
      // Remove dev_dependencies section if empty
      try {
        editor.remove(['dev_dependencies']);
      } catch (e) {
        // Section doesn't exist, that's fine
      }
      return;
    }

    // Ensure dev_dependencies section exists
    _ensureSection(editor, 'dev_dependencies');

    // Clear the section
    editor.update(['dev_dependencies'], {});

    // Add devDependencies
    for (final devDep in module.devDependencies) {
      final version = _getVersionFromPackage(package, devDep.name);
      if (version != null) {
        editor.update(['dev_dependencies', devDep.name], version);
        Logger.info('  ✓ Added dev_dependency: ${devDep.name} ($version)');
      }
    }
  }

}
