import 'dart:io';

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

      // TODO: Step 2: Generate flutist_gen.dart
      // TODO: Step 3: Parse project.dart
      // TODO: Step 4: Update pubspec.yaml files

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
}
