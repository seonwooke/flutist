import 'dart:io';

import '../core/core.dart';
import '../utils/utils.dart';

/// Parses project.dart file into a [Project] object.
class ProjectParser {
  /// Parses the project.dart file in [currentDir].
  static Project? parse(String currentDir) {
    final projectFile = File('$currentDir/project.dart');

    if (!projectFile.existsSync()) {
      Logger.error('project.dart not found');
      return null;
    }

    try {
      final content = projectFile.readAsStringSync();

      _checkDeprecatedTypeField(content);

      final nameMatch = RegExp(r"name:\s*'([^']+)'").firstMatch(content);
      final projectName = nameMatch?.group(1) ?? 'workspace';

      final options = _parseProjectOptions(content);
      final modules = _parseModules(content);

      return Project(
        name: projectName,
        options: options,
        modules: modules,
      );
    } catch (e) {
      Logger.error('Failed to parse project.dart: $e');
      return null;
    }
  }

  /// Checks for deprecated 'type:' field and exits with migration guidance.
  static void _checkDeprecatedTypeField(String content) {
    final typePattern = RegExp(r"type:\s*ModuleType\.\w+");
    final match = typePattern.firstMatch(content);
    if (match == null) return;

    final namePattern = RegExp(r"name:\s*'([^']+)'");
    final names = namePattern.allMatches(content).map((m) => m.group(1)!).toList();
    final moduleName = names.length > 1 ? names[1] : 'unknown';

    Logger.error(
      "project.dart uses deprecated 'type:' field (introduced in v2.x).\n"
      "  Module: $moduleName\n"
      "  → Remove 'type: ModuleType.xxx,' from all Module entries in project.dart.\n"
      "  → See: https://github.com/seonwooke/flutist/blob/main/CHANGELOG.md",
    );
    exit(1);
  }

  /// Parses ProjectOptions from project.dart content.
  static ProjectOptions _parseProjectOptions(String content) {
    final strictMatch =
        RegExp(r'strictMode:\s*(true|false)').firstMatch(content);
    final strictMode = strictMatch?.group(1) != 'false';

    final rootsMatch = RegExp(
      r"compositionRoots:\s*\[(.*?)\]",
      dotAll: true,
    ).firstMatch(content);

    var compositionRoots = const ['app'];
    if (rootsMatch != null) {
      final rootsContent = rootsMatch.group(1)!;
      final roots = RegExp(r"'([^']+)'")
          .allMatches(rootsContent)
          .map((m) => m.group(1)!)
          .toList();
      if (roots.isNotEmpty) {
        compositionRoots = roots;
      }
    }

    return ProjectOptions(
      strictMode: strictMode,
      compositionRoots: compositionRoots,
    );
  }

  /// Parses all Module blocks from project.dart content.
  static List<Module> _parseModules(String content) {
    final modules = <Module>[];

    final modulePattern = RegExp(
      r'Module\s*\((.*?)\),',
      dotAll: true,
    );

    for (final match in modulePattern.allMatches(content)) {
      final moduleContent = match.group(1)!;

      final nameMatch = RegExp(r"name:\s*'([^']+)'").firstMatch(moduleContent);
      if (nameMatch == null) continue;
      final name = nameMatch.group(1)!;

      final dependencies =
          _parseModuleDependencies(moduleContent, 'dependencies');
      final devDependencies =
          _parseModuleDependencies(moduleContent, 'devDependencies');
      final moduleRefs = _parseModuleReferences(moduleContent);

      modules.add(Module(
        name: name,
        dependencies: dependencies,
        devDependencies: devDependencies,
        modules: moduleRefs,
      ));
    }

    return modules;
  }

  /// Parses dependency references from a module's field.
  static List<Dependency> _parseModuleDependencies(
    String moduleContent,
    String fieldName,
  ) {
    final dependencies = <Dependency>[];

    final arrayPattern = RegExp(
      '$fieldName:\\s*\\[(.*?)\\]',
      dotAll: true,
    );
    final match = arrayPattern.firstMatch(moduleContent);
    if (match == null) return dependencies;

    final arrayContent = match.group(1)!;
    final depPattern = RegExp(r'package\.dependencies\.(\w+)');

    for (final depMatch in depPattern.allMatches(arrayContent)) {
      final camelName = depMatch.group(1)!;
      final snakeName = StringCase.toSnakeCase(camelName);
      dependencies.add(Dependency(name: snakeName, version: ''));
    }

    return dependencies;
  }

  /// Parses module references from a module's modules array.
  static List<Module> _parseModuleReferences(String moduleContent) {
    final modules = <Module>[];

    final arrayPattern = RegExp(
      r'modules:\s*\[(.*?)\]',
      dotAll: true,
    );
    final match = arrayPattern.firstMatch(moduleContent);
    if (match == null) return modules;

    final arrayContent = match.group(1)!;
    final modPattern = RegExp(r'package\.modules\.(\w+)');

    for (final modMatch in modPattern.allMatches(arrayContent)) {
      final camelName = modMatch.group(1)!;
      final snakeName = StringCase.toSnakeCase(camelName);
      modules.add(Module(name: snakeName));
    }

    return modules;
  }
}
