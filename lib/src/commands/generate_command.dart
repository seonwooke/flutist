import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml_edit/yaml_edit.dart';

import '../core/core.dart';
import '../generator/flutist_generator.dart';
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
      final projectData = _parseProjectDart(currentDir);

      if (projectData == null) {
        Logger.error('Failed to parse project.dart');
        exit(1);
      }

      Logger.success('Parsed project.dart');
      Logger.info('  Modules: ${projectData.modules.length}');

      // Step 3: Generate flutist_gen.dart (filtered by project.dart modules)
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

      // Parse package name
      final nameMatch = RegExp(r"name:\s*'([^']+)'").firstMatch(content);
      final packageName = nameMatch?.group(1) ?? 'workspace';

      // Parse dependencies
      final dependencies = _parseDependencies(content);

      // Parse modules
      final modules = _parseModules(content);

      return Package(
        name: packageName,
        dependencies: dependencies,
        modules: modules,
      );
    } catch (e) {
      Logger.error('Failed to parse package.dart: $e');
      return null;
    }
  }

  /// Parses dependencies from package.dart content.
  List<Dependency> _parseDependencies(String content) {
    final dependencies = <Dependency>[];

    // Find dependencies array
    final dependenciesPattern = RegExp(
      r'dependencies:\s*\[(.*?)\]',
      dotAll: true,
    );
    final match = dependenciesPattern.firstMatch(content);

    if (match == null) return dependencies;

    final dependenciesContent = match.group(1)!;

    // Find each Dependency(...) entry
    final dependencyPattern = RegExp(
      r"Dependency\s*\(\s*name:\s*'([^']+)'\s*,\s*version:\s*'([^']+)'\s*\)",
    );

    for (final depMatch in dependencyPattern.allMatches(dependenciesContent)) {
      final name = depMatch.group(1)!;
      final version = depMatch.group(2)!;

      dependencies.add(Dependency(name: name, version: version));
    }

    return dependencies;
  }

  /// Parses modules from package.dart content.
  List<Module> _parseModules(String content) {
    final modules = <Module>[];

    // Find modules array
    final modulesPattern = RegExp(
      r'modules:\s*\[(.*?)\]',
      dotAll: true,
    );
    final match = modulesPattern.firstMatch(content);

    if (match == null) return modules;

    final modulesContent = match.group(1)!;

    // Find each Module(...) entry
    final modulePattern = RegExp(
      r"Module\s*\(\s*name:\s*'([^']+)'\s*,\s*type:\s*ModuleType\.(\w+)\s*\)",
    );

    for (final modMatch in modulePattern.allMatches(modulesContent)) {
      final name = modMatch.group(1)!;
      final typeString = modMatch.group(2)!;
      final type = _parseModuleType(typeString);

      modules.add(Module(name: name, type: type));
    }

    return modules;
  }

  /// Parses the project.dart file.
  Project? _parseProjectDart(String currentDir) {
    Logger.info('Parsing project.dart...');

    final projectFile = File('$currentDir/project.dart');

    if (!projectFile.existsSync()) {
      Logger.error('project.dart not found');
      return null;
    }

    try {
      final content = projectFile.readAsStringSync();

      // Parse project name
      final nameMatch = RegExp(r"name:\s*'([^']+)'").firstMatch(content);
      final projectName = nameMatch?.group(1) ?? 'workspace';

      // Parse modules
      final modules = _parseProjectModules(content);

      return Project(
        name: projectName,
        modules: modules,
      );
    } catch (e) {
      Logger.error('Failed to parse project.dart: $e');
      return null;
    }
  }

  /// Parses modules from project.dart content.
  List<Module> _parseProjectModules(String content) {
    final modules = <Module>[];

    // Find all Module(...) blocks
    final modulePattern = RegExp(
      r'Module\s*\((.*?)\),',
      dotAll: true,
    );

    for (final match in modulePattern.allMatches(content)) {
      final moduleContent = match.group(1)!;

      // Parse module name
      final nameMatch = RegExp(r"name:\s*'([^']+)'").firstMatch(moduleContent);
      if (nameMatch == null) continue;
      final name = nameMatch.group(1)!;

      // Parse module type
      final typeMatch =
          RegExp(r'type:\s*ModuleType\.(\w+)').firstMatch(moduleContent);
      if (typeMatch == null) continue;
      final type = _parseModuleType(typeMatch.group(1)!);

      // Parse dependencies
      final dependencies =
          _parseModuleDependencies(moduleContent, 'dependencies');

      // Parse devDependencies
      final devDependencies =
          _parseModuleDependencies(moduleContent, 'devDependencies');

      // Parse modules
      final moduleRefs = _parseModuleReferences(moduleContent);

      modules.add(Module(
        name: name,
        type: type,
        dependencies: dependencies,
        devDependencies: devDependencies,
        modules: moduleRefs,
      ));
    }

    return modules;
  }

  /// Parses dependency references from a module's dependencies or devDependencies array.
  List<Dependency> _parseModuleDependencies(
      String moduleContent, String fieldName) {
    final dependencies = <Dependency>[];

    // Find the dependencies array
    final arrayPattern = RegExp(
      '$fieldName:\\s*\\[(.*?)\\]',
      dotAll: true,
    );
    final match = arrayPattern.firstMatch(moduleContent);

    if (match == null) return dependencies;

    final arrayContent = match.group(1)!;

    // Find package.dependencies.xxx patterns
    final depPattern = RegExp(r'package\.dependencies\.(\w+)');

    for (final depMatch in depPattern.allMatches(arrayContent)) {
      final camelName = depMatch.group(1)!;
      // Convert camelCase back to snake_case
      final snakeName = _toSnakeCase(camelName);

      // Create a placeholder Dependency (version will be filled from package.dart later)
      dependencies.add(Dependency(name: snakeName, version: ''));
    }

    return dependencies;
  }

  /// Parses module references from a module's modules array.
  List<Module> _parseModuleReferences(String moduleContent) {
    final modules = <Module>[];

    // Find the modules array
    final arrayPattern = RegExp(
      r'modules:\s*\[(.*?)\]',
      dotAll: true,
    );
    final match = arrayPattern.firstMatch(moduleContent);

    if (match == null) return modules;

    final arrayContent = match.group(1)!;

    // Find package.modules.xxx patterns
    final modPattern = RegExp(r'package\.modules\.(\w+)');

    for (final modMatch in modPattern.allMatches(arrayContent)) {
      final camelName = modMatch.group(1)!;
      // Convert camelCase back to snake_case
      final snakeName = _toSnakeCase(camelName);

      // Create a placeholder Module (type will be filled from package.dart later)
      modules.add(Module(name: snakeName, type: ModuleType.simple));
    }

    return modules;
  }

  /// Updates pubspec.yaml files for all modules.
  void _updatePubspecFiles(
      String currentDir, Project project, Package package) {
    Logger.info('Updating pubspec.yaml files...');

    for (final module in project.modules) {
      _updateModulePubspec(currentDir, module, package);
    }

    Logger.success('Updated all pubspec.yaml files');
  }

  /// Updates pubspec.yaml for a single module.
  void _updateModulePubspec(String currentDir, Module module, Package package) {
    // Find the module's pubspec.yaml location
    final pubspecPath = _findModulePubspecPath(currentDir, module);

    if (pubspecPath == null) {
      Logger.warn('Could not find pubspec.yaml for module: ${module.name}');
      return;
    }

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
      _rebuildDependenciesSection(editor, module, package, pubspecPath);

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

  /// Finds the pubspec.yaml path for a module.
  String? _findModulePubspecPath(String currentDir, Module module) {
    // Try different possible locations based on module name pattern

    // Check if it's a simple module (e.g., 'app')
    final simplePath = '$currentDir/${module.name}/pubspec.yaml';
    if (File(simplePath).existsSync()) {
      return simplePath;
    }

    // Check if it's a layered module (e.g., 'login_example' in 'features/login/login_example')
    // Extract parent name (e.g., 'login' from 'login_example')
    final parts = module.name.split('_');
    if (parts.length >= 2) {
      // Try common base paths
      final basePaths = ['features', 'core', 'data', 'domain'];

      for (final basePath in basePaths) {
        // Try to find parent folder
        for (int i = parts.length - 1; i >= 1; i--) {
          final parentName = parts.sublist(0, i).join('_');
          final layeredPath =
              '$currentDir/$basePath/$parentName/${module.name}/pubspec.yaml';

          if (File(layeredPath).existsSync()) {
            return layeredPath;
          }
        }
      }
    }

    return null;
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
  ) {
    // Get current dependencies to preserve flutter sdk
    final currentDeps = <String, dynamic>{};
    try {
      final depsNode = editor.parseAt(['dependencies']);
      // Convert YamlNode value to Map
      if (depsNode.value is Map) {
        final deps = depsNode.value as Map;
        // Preserve flutter sdk dependency
        if (deps.containsKey('flutter')) {
          currentDeps['flutter'] = deps['flutter'];
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
    for (final modDep in module.modules) {
      // Skip self-reference
      if (modDep.name == module.name) {
        Logger.warn('  ⚠ Skipping self-reference: ${modDep.name}');
        continue;
      }

      final targetPubspecPath = _findModulePubspecPath(
        path.dirname(path.dirname(pubspecPath)), // Go to root
        modDep,
      );

      if (targetPubspecPath != null) {
        // Calculate relative path
        final currentModuleDir = path.dirname(pubspecPath);
        final targetModuleDir = path.dirname(targetPubspecPath);
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

  // MARK: - Helper

  /// Converts string to ModuleType enum.
  ModuleType _parseModuleType(String typeString) {
    switch (typeString) {
      case 'feature':
        return ModuleType.feature;
      case 'library':
        return ModuleType.library;
      case 'standard':
        return ModuleType.standard;
      case 'simple':
        return ModuleType.simple;
      default:
        throw ArgumentError('Invalid module type: $typeString');
    }
  }

  /// Converts camelCase to snake_case.
  ///
  /// Examples:
  /// - loginExample → login_example
  /// - userDomainImplementation → user_domain_implementation
  String _toSnakeCase(String camelCase) {
    return camelCase.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }
}
