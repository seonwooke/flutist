import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:yaml_edit/yaml_edit.dart';

import '../core/core.dart';
import '../engine/engine.dart';
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
        help: 'Module type: clean, micro, lite, simple',
        allowed: ['clean', 'micro', 'lite', 'simple'],
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
      final moduleType = ModuleType.fromString(typeString);

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

  /// Validates module name and path for common mistakes.
  void _validateInput(String path, String name, ModuleType moduleType) {
    // Warn if name already contains a layer suffix (e.g., --name auth_implementation)
    if (moduleType != ModuleType.simple) {
      final layerSuffixes = [
        '_implementation', '_interface', '_domain', '_data',
        '_presentation', '_example', '_tests', '_testing',
      ];
      for (final suffix in layerSuffixes) {
        if (name.endsWith(suffix)) {
          Logger.warn(
            '⚠ Module name "$name" already contains layer suffix "$suffix".');
          Logger.warn(
            '  This will produce "$name$suffix" layers. '
            'Did you mean --name ${name.substring(0, name.length - suffix.length)}?');
          exit(1);
        }
      }
    }

    // Warn if path's last segment matches name (e.g., --path features/auth --name auth)
    if (moduleType != ModuleType.simple) {
      final pathSegments = path.split('/');
      if (pathSegments.isNotEmpty && pathSegments.last == name) {
        Logger.warn(
          '⚠ Path "$path" already ends with module name "$name".');
        Logger.warn(
          '  This will create "$path/$name/" with extra nesting. '
          'Did you mean --path ${pathSegments.sublist(0, pathSegments.length - 1).join('/')}?');
        exit(1);
      }
    }
  }

  /// Creates the module with specified structure.
  void _createModule(String path, String name, ModuleType moduleType) {
    // Get current working directory
    final currentDir = Directory.current.path;

    // Validate input for common mistakes
    _validateInput(path, name, moduleType);

    // Check if module already exists
    _checkModuleExists(currentDir, path, name, moduleType);

    // Store created module paths for workspace update
    List<String> createdModulePaths = [];
    List<String> createdModuleNames = [];

    if (moduleType == ModuleType.simple) {
      // Simple: Create directly in path (no layers)
      _createSimpleModule(currentDir, path, name);
      createdModulePaths.add('$path/$name');
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
  void _createSimpleModule(String currentDir, String path, String name) {
    final modulePath = '$currentDir/$path/$name';
    final moduleDir = Directory(modulePath);

    // Create directory if not exists
    if (!moduleDir.existsSync()) {
      moduleDir.createSync(recursive: true);
    }

    // Create pubspec.yaml
    _createPubspec(modulePath, name);

    // Create lib/ folder with barrel file
    _createLibFolder(modulePath, name);

    // Create analysis_options.yaml
    _createAnalysisOptions(modulePath, currentDir);

    // Create README.md
    _createReadme(modulePath, name, ModuleType.simple);

    Logger.success('Created simple module: $path/$name');
  }

  /// Creates a layered module (feature, library, standard).
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

      // Create lib/ folder with barrel file
      _createLibFolder(layerPath, layer);

      // Create analysis_options.yaml
      _createAnalysisOptions(layerPath, currentDir);

      // Create main.dart for library example layer
      if (moduleType == ModuleType.micro && layer.endsWith('_example')) {
        _createMainDart(layerPath);
      }

      // Create README.md for each layer
      _createReadme(layerPath, layer, moduleType);
    }

    Logger.success('Created layered module: $path/$name');
  }

  /// Creates pubspec.yaml file.
  void _createPubspec(String modulePath, String moduleName) {
    final pubspecFile = File('$modulePath/pubspec.yaml');
    final content = CreateTemplates.pubspecYaml(modulePath, moduleName);

    pubspecFile.writeAsStringSync(content);
  }

  /// Creates lib/ folder with barrel file.
  void _createLibFolder(String modulePath, String moduleName) {
    final libDir = Directory('$modulePath/lib');
    if (!libDir.existsSync()) {
      libDir.createSync();
      Logger.info('  ✓ Created lib/ folder');
    }

    // Create barrel file (lib/module_name.dart)
    final barrelFile = File('$modulePath/lib/$moduleName.dart');
    if (!barrelFile.existsSync()) {
      barrelFile.writeAsStringSync('');
      Logger.info('  ✓ Created lib/$moduleName.dart');
    }
  }

  /// Creates main.dart file (for library example layer only).
  void _createMainDart(String layerPath) {
    final mainFile = File('$layerPath/lib/main.dart');
    final content = CreateTemplates.mainDart(layerPath);

    mainFile.writeAsStringSync(content);
    Logger.info('  ✓ Created lib/main.dart');
  }

  /// Updates the root pubspec.yaml file with the new module paths.
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

  /// Creates analysis_options.yaml that includes root config.
  void _createAnalysisOptions(String modulePath, String rootDir) {
    // Calculate relative path from modulePath to rootDir
    // Normalize both paths to handle any path separator differences
    final normalizedModulePath = path.normalize(modulePath);
    final normalizedRootDir = path.normalize(rootDir);

    // Calculate the relative path
    final relativePathToRoot =
        path.relative(normalizedRootDir, from: normalizedModulePath);
    // Convert path separators to forward slashes for consistency
    final normalizedPath = relativePathToRoot.replaceAll('\\', '/');

    final analysisOptionsFile = File('$modulePath/analysis_options.yaml');
    final content = CreateTemplates.analysisOptionsYaml(normalizedPath);

    analysisOptionsFile.writeAsStringSync(content);
    Logger.info('  ✓ Created analysis_options.yaml');
  }

  /// Creates README.md file for a module.
  void _createReadme(
      String modulePath, String moduleName, ModuleType moduleType) {
    final readmeFile = File('$modulePath/README.md');
    final content = CreateTemplates.moduleReadme(moduleName, moduleType);

    readmeFile.writeAsStringSync(content);
    Logger.info('  ✓ Created README.md');
  }

  /// Checks if a module with the same path and name already exists.
  void _checkModuleExists(
    String currentDir,
    String path,
    String name,
    ModuleType moduleType,
  ) {
    if (moduleType == ModuleType.simple) {
      // Check if pubspec.yaml exists in path/name
      final pubspecPath = '$currentDir/$path/$name/pubspec.yaml';
      if (File(pubspecPath).existsSync()) {
        Logger.error('Module already exists at: $path/$name');
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

  /// Returns the list of layer names for the given module type.
  List<String> _getLayersForType(ModuleType moduleType, String moduleName) {
    switch (moduleType) {
      case ModuleType.clean:
        // Domain, Data, Presentation
        return [
          '${moduleName}_domain',
          '${moduleName}_data',
          '${moduleName}_presentation',
        ];

      case ModuleType.micro:
        // Example, Interface, Implementation, Tests, Testing
        return [
          '${moduleName}_example',
          '${moduleName}_interface',
          '${moduleName}_implementation',
          '${moduleName}_tests',
          '${moduleName}_testing',
        ];

      case ModuleType.lite:
        // Interface, Implementation, Tests, Testing
        return [
          '${moduleName}_interface',
          '${moduleName}_implementation',
          '${moduleName}_tests',
          '${moduleName}_testing',
        ];

      case ModuleType.simple:
        // No layers, just the module itself
        return [];

      case ModuleType.custom:
        // No layers, just the module itself
        return [];
    }
  }
}
