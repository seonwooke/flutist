import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../core/core.dart';
import '../generator/flutist_generator.dart';
import '../scaffolds/create_templates.dart';
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

      // Create module
      _createModule(path, name, moduleType);

      // Generate flutist_gen.dart
      GenFileGenerator.generate(Directory.current.path);

      Logger.success('Module created successfully!');
    } catch (e) {
      Logger.error('Failed to create module: $e');
      Logger.info(
        'Usage: flutist create --path <path> --name <name> --options <type>',
      );
      exit(1);
    }
  }

  /// Creates the module with specified structure.
  /// 지정된 구조로 모듈을 생성합니다.
  void _createModule(String path, String name, ModuleType moduleType) {
    // Get current working directory
    final currentDir = Directory.current.path;

    // Check if module already exists
    _checkModuleExists(currentDir, path, name, moduleType);

    // Store created module paths for workspace update
    List<String> createdModulePaths = [];
    List<String> createdModuleNames = [];

    if (moduleType == ModuleType.simple) {
      // Simple: Create directly in path (no layers)
      _createSimpleModule(currentDir, path, name);
      createdModuleNames.add(name);
    } else {
      // Other types: Create parent folder + layers
      final layers = _getLayersForType(moduleType, name);
      _createLayeredModule(currentDir, path, name, moduleType, layers);

      // Add all layer paths
      for (final layer in layers) {
        createdModulePaths.add('$path/$name/$layer');
        createdModuleNames.add(layer);
      }
    }

    // Update root pubspec.yaml workspace
    _updateRootPubspec(currentDir, createdModulePaths);

    // Update project.dart modules
    _updateProjectDart(currentDir, createdModuleNames, moduleType);

    // Update package.dart modules
    _updatePackageDart(currentDir, createdModuleNames, moduleType);
  }

  /// Creates a simple module (no layers).
  /// 단순 모듈을 생성합니다 (레이어 없음).
  void _createSimpleModule(String currentDir, String path, String name) {
    final modulePath = '$currentDir/$path';
    final moduleDir = Directory(modulePath);

    // Create directory if not exists
    if (!moduleDir.existsSync()) {
      moduleDir.createSync(recursive: true);
    }

    // Create pubspec.yaml
    _createPubspec(modulePath, name);

    // Create lib/ folder
    _createLibFolder(modulePath);

    Logger.success('Created simple module: $path');
  }

  /// Creates a layered module (feature, library, standard).
  /// 레이어가 있는 모듈을 생성합니다 (feature, library, standard).
  void _createLayeredModule(
    String currentDir,
    String path,
    String name,
    ModuleType moduleType,
    List<String> layers,
  ) {
    // Create parent folder (e.g., features/login/)
    final parentPath = '$currentDir/$path/$name';
    final parentDir = Directory(parentPath);

    if (!parentDir.existsSync()) {
      parentDir.createSync(recursive: true);
    }

    // Create each layer
    for (final layer in layers) {
      final layerPath = '$parentPath/$layer';
      final layerDir = Directory(layerPath);

      // Create layer directory
      layerDir.createSync(recursive: true);

      // Create pubspec.yaml
      _createPubspec(layerPath, layer);

      // Create lib/ folder
      _createLibFolder(layerPath);

      // Create main.dart for library example layer
      if (moduleType == ModuleType.library && layer.endsWith('_example')) {
        _createMainDart(layerPath);
      }
    }

    Logger.success('Created layered module: $path/$name');
  }

  /// Creates pubspec.yaml file.
  /// pubspec.yaml 파일을 생성합니다.
  void _createPubspec(String modulePath, String moduleName) {
    final pubspecFile = File('$modulePath/pubspec.yaml');
    final content = CreateTemplates.pubspecYaml(modulePath, moduleName);

    pubspecFile.writeAsStringSync(content);
  }

  /// Creates lib/ folder.
  /// lib/ 폴더를 생성합니다.
  void _createLibFolder(String modulePath) {
    final libDir = Directory('$modulePath/lib');
    if (!libDir.existsSync()) {
      libDir.createSync();
      Logger.info('  ✓ Created lib/ folder');
    }
  }

  /// Creates main.dart file (for library example layer only).
  /// main.dart 파일을 생성합니다 (library의 example 레이어만).
  void _createMainDart(String layerPath) {
    final mainFile = File('$layerPath/lib/main.dart');
    final content = CreateTemplates.mainDart(layerPath);

    mainFile.writeAsStringSync(content);
    Logger.info('  ✓ Created lib/main.dart');
  }

  /// Updates the root pubspec.yaml file with the new module paths.
  /// root pubspec.yaml 파일을 업데이트하여 새로운 모듈 경로를 추가합니다.
  void _updateRootPubspec(String currentDir, List<String> modulePaths) {
    Logger.info('Updating root pubspec.yaml...');

    final rootPubspecFile = File('$currentDir/pubspec.yaml');

    if (!rootPubspecFile.existsSync()) {
      Logger.warn('Root pubspec.yaml not found. Skipping workspace update.');
      return;
    }

    try {
      // Read current content
      final content = rootPubspecFile.readAsStringSync();
      final editor = YamlEditor(content);

      // Add each module path to workspace
      for (final modulePath in modulePaths) {
        editor.appendToList(['workspace'], modulePath);
        Logger.info('  ✓ Added to workspace: $modulePath');
      }

      // Write back to file
      rootPubspecFile.writeAsStringSync(editor.toString());
      Logger.success('Updated root pubspec.yaml');
    } catch (e) {
      Logger.error('Failed to update root pubspec.yaml: $e');
    }
  }

  /// Updates the project.dart file with new module entries.
  /// project.dart 파일에 새 모듈 항목을 추가합니다.
  void _updateProjectDart(
    String currentDir,
    List<String> moduleNames,
    ModuleType moduleType,
  ) {
    Logger.info('Updating project.dart...');

    final projectFile = File('$currentDir/project.dart');

    if (!projectFile.existsSync()) {
      Logger.warn('project.dart not found. Skipping module registration.');
      return;
    }

    try {
      // Read current content
      String content = projectFile.readAsStringSync();

      // Find the modules list
      final modulesPattern = RegExp(r'modules:\s*\[');
      final match = modulesPattern.firstMatch(content);

      if (match == null) {
        Logger.warn('Could not find modules list in project.dart');
        return;
      }

      // Find the closing bracket of modules list
      int bracketCount = 0;
      int startIndex = match.end;
      int insertIndex = -1;

      for (int i = startIndex; i < content.length; i++) {
        if (content[i] == '[') {
          bracketCount++;
        } else if (content[i] == ']') {
          if (bracketCount == 0) {
            insertIndex = i;
            break;
          }
          bracketCount--;
        }
      }

      if (insertIndex == -1) {
        Logger.warn('Could not find closing bracket for modules list');
        return;
      }

      // Get the content before the closing bracket and trim whitespace
      String beforeBracket = content.substring(0, insertIndex).trimRight();
      final afterBracket = content.substring(insertIndex);

      // Generate module entries
      final moduleEntries = StringBuffer();
      for (final moduleName in moduleNames) {
        moduleEntries.write('\n'); // Add newline before each module
        moduleEntries
            .write(CreateTemplates.projectModule(moduleName, moduleType));
      }

      // Combine
      final newContent = '$beforeBracket$moduleEntries\n  $afterBracket';

      // Write back to file
      projectFile.writeAsStringSync(newContent);

      for (final moduleName in moduleNames) {
        Logger.info('  ✓ Added to project.dart: $moduleName');
      }

      Logger.success('Updated project.dart');
    } catch (e) {
      Logger.error('Failed to update project.dart: $e');
    }
  }

  /// Updates the package.dart file with new module entries.
  /// package.dart 파일에 새 모듈 항목을 추가합니다.
  void _updatePackageDart(
    String currentDir,
    List<String> moduleNames,
    ModuleType moduleType,
  ) {
    Logger.info('Updating package.dart...');

    final packageFile = File('$currentDir/package.dart');

    if (!packageFile.existsSync()) {
      Logger.warn('package.dart not found. Skipping module registration.');
      return;
    }

    try {
      // Read current content
      String content = packageFile.readAsStringSync();

      // Find the modules list in Package
      final modulesPattern = RegExp(r'modules:\s*\[');
      final match = modulesPattern.firstMatch(content);

      if (match == null) {
        Logger.warn('Could not find modules list in package.dart');
        return;
      }

      // Find the closing bracket of modules list
      int bracketCount = 0;
      int startIndex = match.end;
      int insertIndex = -1;

      for (int i = startIndex; i < content.length; i++) {
        if (content[i] == '[') {
          bracketCount++;
        } else if (content[i] == ']') {
          if (bracketCount == 0) {
            insertIndex = i;
            break;
          }
          bracketCount--;
        }
      }

      if (insertIndex == -1) {
        Logger.warn('Could not find closing bracket for modules list');
        return;
      }

      // Get the content before the closing bracket and trim whitespace
      String beforeBracket = content.substring(0, insertIndex).trimRight();
      final afterBracket = content.substring(insertIndex);

      // Generate module entries
      final moduleEntries = StringBuffer();
      for (final moduleName in moduleNames) {
        moduleEntries.write('\n'); // Add newline before each module
        moduleEntries
            .write(CreateTemplates.packageModule(moduleName, moduleType));
      }

      // Combine
      final newContent = '$beforeBracket$moduleEntries\n  $afterBracket';

      // Write back to file
      packageFile.writeAsStringSync(newContent);

      for (final moduleName in moduleNames) {
        Logger.info('  ✓ Added to package.dart: $moduleName');
      }

      Logger.success('Updated package.dart');
    } catch (e) {
      Logger.error('Failed to update package.dart: $e');
    }
  }
  // MARK: - Helper

  /// Checks if a module with the same path and name already exists.
  /// 동일한 경로와 이름의 모듈이 이미 존재하는지 확인합니다.
  void _checkModuleExists(
    String currentDir,
    String path,
    String name,
    ModuleType moduleType,
  ) {
    if (moduleType == ModuleType.simple) {
      // Check if pubspec.yaml exists in path
      final pubspecPath = '$currentDir/$path/pubspec.yaml';
      if (File(pubspecPath).existsSync()) {
        Logger.error('Module already exists at: $path');
        Logger.error('   Found: $pubspecPath');
        exit(1);
      }
    } else {
      // Check if parent directory exists
      final parentPath = '$currentDir/$path/$name';
      if (Directory(parentPath).existsSync()) {
        Logger.error('Module already exists at: $path/$name');
        Logger.error('   Directory already exists: $parentPath');
        exit(1);
      }
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
