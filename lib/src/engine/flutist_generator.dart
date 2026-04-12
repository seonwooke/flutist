import 'dart:io';

import '../core/core.dart';
import '../utils/utils.dart';

/// Generator for flutist_gen.dart file.
class GenFileGenerator {
  /// Generates the flutist_gen.dart file based on package.dart.
  /// If [packageData] is provided, skips re-parsing package.dart.
  /// If [projectModuleNames] is provided, only modules present in project.dart will be included.
  static void generate(String rootPath,
      {Package? packageData, List<String>? projectModuleNames}) {
    Logger.info('Generating flutist_gen.dart...');

    final Package package;
    if (packageData != null) {
      package = packageData;
    } else {
      // Parse package.dart
      final packageFile = File('$rootPath/package.dart');

      if (!packageFile.existsSync()) {
        Logger.warn('package.dart not found. Skipping gen file generation.');
        return;
      }

      try {
        final content = packageFile.readAsStringSync();
        package = parsePackageDart(content);
      } catch (e) {
        Logger.error(ErrorHelper.describe(e, '$rootPath/package.dart'));
        return;
      }
    }

    // Filter modules if projectModuleNames is provided
    final filteredPackage = projectModuleNames != null
        ? _filterPackageModules(package, projectModuleNames)
        : package;

    try {
      // Create flutist directory if not exists
      final flutistDir = Directory('$rootPath/flutist');
      if (!flutistDir.existsSync()) {
        flutistDir.createSync(recursive: true);
      }

      // Generate content and write to file
      final genContent = _buildGenContent(filteredPackage);
      final genFile = File('$rootPath/flutist/flutist_gen.dart');
      genFile.writeAsStringSync(genContent);

      Logger.success('Generated flutist_gen.dart');
    } catch (e) {
      Logger.error(ErrorHelper.describe(e, '$rootPath/flutist/flutist_gen.dart'));
    }
  }

  /// Filters package modules to only include those present in project.dart.
  static Package _filterPackageModules(
      Package package, List<String> projectModuleNames) {
    final filteredModules = package.modules
        .where((module) => projectModuleNames.contains(module.name))
        .toList();

    return Package(
      name: package.name,
      dependencies: package.dependencies,
      modules: filteredModules,
    );
  }

  /// Parses package.dart content.
  static Package parsePackageDart(String content) {
    _warnIfInlineDeclarations(content, 'package.dart');

    // Parse package name
    final nameMatch = RegExp(r"name:\s*'([^']+)'").firstMatch(content);
    final packageName = nameMatch?.group(1) ?? 'workspace';

    // Parse dependencies
    final dependencies = _parseDependencies(content);

    // Parse modules
    final modules = _parseModules(content);

    // Warn if file has Module( outside comments but parsed none
    if (modules.isEmpty && _hasModuleOutsideComments(content)) {
      Logger.warn(
          'package.dart contains Module() but none were parsed. '
          'Check that declarations use multiline format.');
    }

    return Package(
      name: packageName,
      dependencies: dependencies,
      modules: modules,
    );
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

  /// Warns if package.dart appears to use inline declarations.
  ///
  /// Detects patterns like `modules: [Module(name: 'foo')]` on a single line.
  /// Skips comment lines to avoid false positives.
  static void _warnIfInlineDeclarations(String content, String fileName) {
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('//')) continue;
      if (RegExp(r'\[.*Module\s*\(.*\).*\]').hasMatch(line) ||
          RegExp(r'\[.*Dependency\s*\(.*\).*\]').hasMatch(line)) {
        Logger.warn('$fileName appears to use inline declarations.');
        Logger.warn(
            'Flutist only parses multiline format. '
            'Split each Module/Dependency onto separate lines.');
        return;
      }
    }
  }

  /// Parses dependencies from package.dart content.
  static List<Dependency> _parseDependencies(String content) {
    final dependencies = <Dependency>[];

    final dependenciesPattern = RegExp(
      r'dependencies:\s*\[(.*?)\]',
      dotAll: true,
    );
    final match = dependenciesPattern.firstMatch(content);

    if (match == null) return dependencies;

    final dependenciesContent = match.group(1)!;

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
  static List<Module> _parseModules(String content) {
    final modules = <Module>[];

    final modulesPattern = RegExp(
      r'modules:\s*\[(.*?)\]',
      dotAll: true,
    );
    final match = modulesPattern.firstMatch(content);

    if (match == null) return modules;

    final modulesContent = match.group(1)!;

    final modulePattern = RegExp(
      r"Module\s*\(\s*name:\s*'([^']+)'\s*\)",
    );

    for (final modMatch in modulePattern.allMatches(modulesContent)) {
      final name = modMatch.group(1)!;
      modules.add(Module(name: name));
    }

    return modules;
  }

  /// Builds the content for flutist_gen.dart.
  static String _buildGenContent(Package package) {
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
      final getterName = StringCase.toCamelCase(dep.name);
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
      final getterName = StringCase.toCamelCase(module.name);
      buffer.writeln("  /// Module getter for ${module.name}");
      buffer.writeln(
          "  Module get $getterName => firstWhere((m) => m.name == '${module.name}');");
    }

    buffer.writeln('}');

    return buffer.toString();
  }

}
