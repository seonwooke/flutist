import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml_edit/yaml_edit.dart';

import '../core/core.dart';
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

      // Step 2: Generate flutist_gen.dart
      _generateFlutistGen(currentDir, packageData);

      // Step 3: Parse project.dart
      final projectData = _parseProjectDart(currentDir);

      if (projectData == null) {
        Logger.error('Failed to parse project.dart');
        exit(1);
      }

      Logger.success('Parsed project.dart');
      Logger.info('  Modules: ${projectData.modules.length}');

      // Step 4: Update pubspec.yaml files
      _updatePubspecFiles(currentDir, projectData, packageData);

      Logger.success('Generation completed!');
    } catch (e) {
      Logger.error('Generation failed: $e');
      exit(1);
    }
  }

  /// Parses the package.dart file.
  /// package.dart 파일을 파싱합니다.
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
  /// package.dart 내용에서 dependencies를 파싱합니다.
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
  /// package.dart 내용에서 modules를 파싱합니다.
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

  /// Generates the flutist_gen.dart file.
  /// flutist_gen.dart 파일을 생성합니다.
  void _generateFlutistGen(String currentDir, Package package) {
    Logger.info('Generating flutist_gen.dart...');

    // Create flutist directory if not exists
    final flutistDir = Directory('$currentDir/flutist');
    if (!flutistDir.existsSync()) {
      flutistDir.createSync(recursive: true);
    }

    // Generate content
    final content = _buildFlutistGenContent(package);

    // Write to file
    final genFile = File('$currentDir/flutist/flutist_gen.dart');
    genFile.writeAsStringSync(content);

    Logger.success('Generated flutist_gen.dart');
  }

  /// Builds the content for flutist_gen.dart.
  /// flutist_gen.dart의 내용을 생성합니다.
  String _buildFlutistGenContent(Package package) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// Generated by Flutist');
    buffer.writeln();
    buffer.writeln("import 'package:flutist/flutist.dart';");
    buffer.writeln();

    // Dependencies Extension
    buffer.writeln('/// Extension for package.dependencies.xxx access');
    buffer.writeln('extension PackageDependenciesX on List<Dependency> {');

    for (final dep in package.dependencies) {
      final getterName = _toCamelCase(dep.name);
      buffer.writeln("  /// Dependency getter for ${dep.name}");
      buffer.writeln(
          "  Dependency get $getterName => firstWhere((d) => d.name == '${dep.name}');");
    }

    buffer.writeln('}');
    buffer.writeln();

    // Modules Extension
    buffer.writeln('/// Extension for package.modules.xxx access');
    buffer.writeln('extension PackageModulesX on List<Module> {');

    for (final module in package.modules) {
      final getterName = _toCamelCase(module.name);
      buffer.writeln("  /// Module getter for ${module.name}");
      buffer.writeln(
          "  Module get $getterName => firstWhere((m) => m.name == '${module.name}');");
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  /// Parses the project.dart file.
  /// project.dart 파일을 파싱합니다.
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
  /// project.dart 내용에서 modules를 파싱합니다.
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
  /// 모듈의 dependencies 또는 devDependencies 배열에서 의존성 참조를 파싱합니다.
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
  /// 모듈의 modules 배열에서 모듈 참조를 파싱합니다.
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
  /// 모든 모듈의 pubspec.yaml 파일을 업데이트합니다.
  void _updatePubspecFiles(
      String currentDir, Project project, Package package) {
    Logger.info('Updating pubspec.yaml files...');

    for (final module in project.modules) {
      _updateModulePubspec(currentDir, module, package);
    }

    Logger.success('Updated all pubspec.yaml files');
  }

  /// Updates pubspec.yaml for a single module.
  /// 단일 모듈의 pubspec.yaml을 업데이트합니다.
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
      Logger.success('  ✅ Updated ${module.name}');
    } catch (e) {
      Logger.error('Failed to update ${module.name}: $e');
    }
  }

  /// Finds the pubspec.yaml path for a module.
  /// 모듈의 pubspec.yaml 경로를 찾습니다.
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
  /// package.dart에서 의존성의 버전을 가져옵니다.
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
  /// YAML 문서에 섹션이 존재하는지 확인합니다.
  /// 존재하지 않으면 빈 맵으로 생성합니다.
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
  /// pubspec.yaml 내용을 포맷팅하여 적절한 빈 줄을 보장합니다.
  String _formatPubspecContent(String content) {
    // Convert inline maps to multiline
    content = _convertInlineMapsToMultiline(content);

    // Reorder sections and add blank lines
    return _reorderSections(content);
  }

  /// Converts inline YAML maps to multiline format.
  /// inline YAML 맵을 multiline 형식으로 변환합니다.
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
  /// pubspec.yaml의 섹션을 재정렬하여 적절한 구조를 보장합니다.
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
  /// dependencies 섹션을 완전히 재구성합니다.
  void _rebuildDependenciesSection(
    YamlEditor editor,
    Module module,
    Package package,
    String pubspecPath,
  ) {
    // Ensure dependencies section exists
    _ensureSection(editor, 'dependencies');

    // Get current dependencies to preserve flutter sdk
    final currentDeps = <String, dynamic>{};
    try {
      final depsNode = editor.parseAt(['dependencies']);
      // YamlNode의 value를 Map으로 변환
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

    // Clear the section and add flutter back
    editor.update(['dependencies'], currentDeps);

    // Add dependencies from project.dart
    for (final dep in module.dependencies) {
      final version = _getVersionFromPackage(package, dep.name);
      if (version != null) {
        editor.update(['dependencies', dep.name], version);
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

        editor.update(['dependencies', modDep.name], {'path': relativePath});
        Logger.info('  ✓ Added module: ${modDep.name} (path: $relativePath)');
      } else {
        Logger.warn('  ⚠ Could not find module: ${modDep.name}');
      }
    }
  }

  /// Rebuilds the dev_dependencies section completely.
  /// dev_dependencies 섹션을 완전히 재구성합니다.
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
  /// 문자열을 ModuleType enum으로 변환합니다.
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

  /// Converts snake_case to camelCase.
  /// snake_case를 camelCase로 변환합니다.
  ///
  /// Examples:
  /// - login_example → loginExample
  /// - user_domain_implementation → userDomainImplementation
  String _toCamelCase(String snakeCase) {
    final parts = snakeCase.split('_');
    if (parts.length == 1) return snakeCase;

    final first = parts.first;
    final rest = parts.skip(1).map((part) {
      if (part.isEmpty) return part;
      return part[0].toUpperCase() + part.substring(1);
    });

    return first + rest.join('');
  }

  /// Converts camelCase to snake_case.
  /// camelCase를 snake_case로 변환합니다.
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
