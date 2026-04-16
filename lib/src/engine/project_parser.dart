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
      _warnIfInlineDeclarations(content);

      final nameMatch = RegExp(r"name:\s*'([^']+)'").firstMatch(content);
      final projectName = nameMatch?.group(1) ?? 'workspace';

      final options = _parseProjectOptions(content);
      final modules = _parseModules(content);

      if (modules.isEmpty && _hasModuleOutsideComments(content)) {
        Logger.warn(
            'project.dart contains Module() but none were parsed. '
            'Check that declarations use multiline format.');
      }

      return Project(
        name: projectName,
        options: options,
        modules: modules,
      );
    } catch (e) {
      Logger.error(ErrorHelper.describe(e, 'project.dart'));
      return null;
    }
  }

  /// Returns true if content has `Module(` on a non-comment line.
  static bool _hasModuleOutsideComments(String content) {
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('//') && trimmed.contains('Module(')) {
        return true;
      }
    }
    return false;
  }

  /// Warns if project.dart appears to use inline declarations.
  ///
  /// Detects patterns like `modules: [Module(name: 'foo')]` on a single line.
  /// Skips comment lines to avoid false positives.
  static void _warnIfInlineDeclarations(String content) {
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('//')) continue;
      if (RegExp(r'\[.*Module\s*\(.*\).*\]').hasMatch(line)) {
        Logger.warn('project.dart appears to use inline declarations.');
        Logger.warn(
            'Flutist only parses multiline format. '
            'Split each Module onto separate lines.');
        return;
      }
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

    final rawContent = match.group(1)!;
    // Strip comment lines to avoid parsing commented-out dependencies
    final arrayContent = rawContent
        .split('\n')
        .where((line) => !line.trim().startsWith('//'))
        .join('\n');
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

    final rawContent = match.group(1)!;
    // Strip comment lines to avoid parsing commented-out module references
    final arrayContent = rawContent
        .split('\n')
        .where((line) => !line.trim().startsWith('//'))
        .join('\n');
    final modPattern = RegExp(r'package\.modules\.(\w+)');

    for (final modMatch in modPattern.allMatches(arrayContent)) {
      final camelName = modMatch.group(1)!;
      final snakeName = StringCase.toSnakeCase(camelName);
      modules.add(Module(name: snakeName));
    }

    return modules;
  }
}
