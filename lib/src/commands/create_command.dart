import 'dart:io';

import 'package:args/args.dart';

import '../core/core.dart';
import '../utils/utils.dart';
import 'commands.dart';

class CreateCommand implements BaseCommand {
  @override
  String get name => 'create';

  @override
  String get description => 'Create a new module in the Flutist project.';

  @override
  void execute(List<String> arguments) {
    // Create parser for create command
    final parser = ArgParser()
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Directory path where the module will be created',
        mandatory: true,
      )
      ..addOption(
        'name',
        abbr: 'n',
        help: 'Name of the module',
        mandatory: true,
      )
      ..addOption(
        'options',
        abbr: 'o',
        help: 'Module type: feature, library, standard, simple',
        allowed: ['feature', 'library', 'standard', 'simple'],
        mandatory: true,
      );

    try {
      // Parse arguments
      final result = parser.parse(arguments);

      // Extract values
      final path = result['path'] as String;
      final name = result['name'] as String;
      final typeString = result['options'] as String;

      // Convert to ModuleType
      final moduleType = _parseModuleType(typeString);

      // Log start
      Logger.info('📦 Creating module...');
      Logger.info('  Path: $path');
      Logger.info('  Name: $name');
      Logger.info('  Type: $moduleType');

      /// Create module
      _createModule(path, name, moduleType);

      Logger.success('✅ Module created successfully!');
    } catch (e) {
      Logger.error('Failed to create module: $e');
      Logger.info(
        'Usage: flutist create --path <path> --name <name> --options <type>',
      );
      exit(1);
    }
  }

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

  /// Creates the module with specified structure.
  /// 지정된 구조로 모듈을 생성합니다.
  void _createModule(String path, String name, ModuleType moduleType) {
    // Get layers based on module type
    final layers = _getLayersForType(moduleType, name);

    Logger.info('Layers to create: ${layers.join(", ")}');
  }

  /// Returns the list of layer names for the given module type.
  /// 주어진 모듈 타입에 대한 레이어 이름 목록을 반환합니다.
  List<String> _getLayersForType(ModuleType moduleType, String moduleName) {
    switch (moduleType) {
      case ModuleType.feature:
        // Domain, Data, Presentation
        return [
          '${moduleName}_domain',
          '${moduleName}_data',
          '${moduleName}_presentation',
        ];

      case ModuleType.library:
        // Example, Interface, Implementation, Testing, Tests
        return [
          '${moduleName}_example',
          '${moduleName}_interface',
          '${moduleName}_implementation',
          '${moduleName}_testing',
          '${moduleName}_tests',
        ];

      case ModuleType.standard:
        // Implementation, Tests, Testing
        return [
          '${moduleName}_implementation',
          '${moduleName}_tests',
          '${moduleName}_testing',
        ];

      case ModuleType.simple:
        // No layers, just the module itself
        return [];
    }
  }
}
