import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
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
    final parser = ArgParser()
      ..addOption(
        'name',
        abbr: 'n',
        help: 'Name of the module',
        mandatory: true,
      )
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Directory path where the module will be created',
        mandatory: true,
      )
      ..addOption(
        'options',
        abbr: 'o',
        help: 'Scaffold type: clean, micro, lite (omit for single package)',
        allowed: ['clean', 'micro', 'lite'],
      );

    try {
      final result = parser.parse(arguments);

      final path = result['path'] as String;
      final name = result['name'] as String;
      final typeString = result['options'] as String?;

      // Default to simple when --options is omitted
      final scaffoldType = typeString != null
          ? ScaffoldType.fromString(typeString)
          : ScaffoldType.simple;

      Logger.info('📦 Creating module...');
      Logger.info('  Path: $path');
      Logger.info('  Name: $name');
      if (typeString != null) Logger.info('  Type: $typeString');

      _createModule(path, name, scaffoldType);

      GenFileGenerator.generate(Directory.current.path);

      Logger.success('Module created successfully!');
    } catch (e) {
      Logger.error('Failed to create module: $e');
      Logger.info(
        'Usage: flutist create --name <name> --path <path> [--options <clean|micro|lite>]',
      );
      exit(1);
    }
  }

  /// Validates module name and path for common mistakes.
  void _validateInput(String path, String name, ScaffoldType scaffoldType) {
    if (scaffoldType != ScaffoldType.simple) {
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

  }

  /// Creates the module with specified structure.
  void _createModule(String path, String name, ScaffoldType scaffoldType) {
    final currentDir = Directory.current.path;

    _validateInput(path, name, scaffoldType);
    _checkModuleExists(currentDir, path, name, scaffoldType);

    List<String> createdModulePaths = [];
    Map<String, List<String>> layerDeps = {};

    if (scaffoldType == ScaffoldType.simple) {
      _createSimpleModule(currentDir, path, name);
      createdModulePaths.add(_workspaceEntryFor(path, name));
      layerDeps[name] = [];
    } else {
      final layers = _getLayersForType(scaffoldType, name);
      _createLayeredModule(currentDir, path, name, scaffoldType, layers);

      for (final layer in layers) {
        createdModulePaths.add(_workspaceEntryFor(path, name, layer));
      }
      layerDeps = _getLayerDepsForType(scaffoldType, name);
    }

    _updateRootPubspec(currentDir, createdModulePaths);
    _updateProjectDart(currentDir, layerDeps);
    _updatePackageDart(currentDir, layerDeps.keys.toList());
  }

  /// Returns a normalized POSIX path for a workspace entry.
  /// Prevents entries like "./app" when users pass "--path .".
  String _workspaceEntryFor(String basePath, String name, [String? layer]) {
    final joined = layer == null
        ? path.posix.join(basePath, name)
        : path.posix.join(basePath, name, layer);
    return path.posix.normalize(joined);
  }

  /// Returns the layer dependency map for B6 auto-wiring.
  Map<String, List<String>> _getLayerDepsForType(
      ScaffoldType scaffoldType, String name) {
    switch (scaffoldType) {
      case ScaffoldType.clean:
        return {
          '${name}_domain': [],
          '${name}_data': ['${name}_domain'],
          '${name}_presentation': ['${name}_domain'],
        };

      case ScaffoldType.micro:
        return {
          '${name}_interface': [],
          '${name}_implementation': ['${name}_interface'],
          '${name}_testing': ['${name}_interface'],
          '${name}_tests': ['${name}_implementation', '${name}_testing'],
          '${name}_example': ['${name}_implementation', '${name}_testing'],
        };

      case ScaffoldType.lite:
        return {
          '${name}_interface': [],
          '${name}_implementation': ['${name}_interface'],
          '${name}_testing': ['${name}_interface'],
          '${name}_tests': ['${name}_implementation', '${name}_testing'],
        };

      default:
        return {};
    }
  }

  /// Creates a simple module (no layers).
  void _createSimpleModule(String currentDir, String path, String name) {
    final modulePath = '$currentDir/$path/$name';
    final moduleDir = Directory(modulePath);

    if (!moduleDir.existsSync()) {
      moduleDir.createSync(recursive: true);
    }

    _createPubspec(modulePath, name);
    _createLibFolder(modulePath, name);
    _createAnalysisOptions(modulePath, currentDir);
    _createReadme(modulePath, name, ScaffoldType.simple);

    Logger.success('Created simple module: $path/$name');
  }

  /// Creates a layered module (clean, micro, lite).
  void _createLayeredModule(
    String currentDir,
    String path,
    String name,
    ScaffoldType scaffoldType,
    List<String> layers,
  ) {
    final parentPath = '$currentDir/$path/$name';
    final parentDir = Directory(parentPath);

    if (!parentDir.existsSync()) {
      parentDir.createSync(recursive: true);
    }

    for (final layer in layers) {
      final layerPath = '$parentPath/$layer';
      final layerDir = Directory(layerPath);

      layerDir.createSync(recursive: true);

      _createPubspec(layerPath, layer);
      _createLibFolder(layerPath, layer);
      _createAnalysisOptions(layerPath, currentDir);

      if (scaffoldType == ScaffoldType.micro && layer.endsWith('_example')) {
        _createMainDart(layerPath);
      }

      _createReadme(layerPath, layer, scaffoldType);
    }

    Logger.success('Created layered module: $path/$name');
  }

  /// Creates pubspec.yaml file.
  ///
  /// Adds `flutter: sdk: flutter` for layers that typically contain Flutter UI
  /// code: _implementation and _example.
  void _createPubspec(String modulePath, String moduleName) {
    final isFlutterLayer = moduleName.endsWith('_implementation') ||
        moduleName.endsWith('_example');
    final pubspecFile = File('$modulePath/pubspec.yaml');
    final content = CreateTemplates.pubspecYaml(modulePath, moduleName,
        isFlutterModule: isFlutterLayer);
    pubspecFile.writeAsStringSync(content);
  }

  /// Creates lib/ folder with barrel file.
  void _createLibFolder(String modulePath, String moduleName) {
    final libDir = Directory('$modulePath/lib');
    if (!libDir.existsSync()) {
      libDir.createSync();
      Logger.info('  ✓ Created lib/ folder');
    }

    final barrelFile = File('$modulePath/lib/$moduleName.dart');
    if (!barrelFile.existsSync()) {
      barrelFile.writeAsStringSync('');
      Logger.info('  ✓ Created lib/$moduleName.dart');
    }
  }

  /// Creates main.dart file (for micro example layer only).
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
      final content = rootPubspecFile.readAsStringSync();
      final editor = YamlEditor(content);

      for (final modulePath in modulePaths) {
        try {
          editor.appendToList(['workspace'], modulePath);
        } catch (_) {
          // workspace section absent (e.g. fresh existing-project migration) —
          // create it in block style with the first module.
          editor.update(
            ['workspace'],
            wrapAsYamlNode([modulePath],
                collectionStyle: CollectionStyle.BLOCK),
          );
        }
        Logger.info('  ✓ Added to workspace: $modulePath');
      }

      rootPubspecFile.writeAsStringSync(editor.toString());
      Logger.success('Updated root pubspec.yaml');
    } catch (e) {
      Logger.error('Failed to update root pubspec.yaml: ${ErrorHelper.describe(e, '$currentDir/pubspec.yaml')}');
    }
  }

  /// Updates the project.dart file with new module entries.
  void _updateProjectDart(
      String currentDir, Map<String, List<String>> layerDeps) {
    Logger.info('Updating project.dart...');

    final projectFile = File('$currentDir/project.dart');

    if (!projectFile.existsSync()) {
      Logger.warn('project.dart not found. Skipping module registration.');
      return;
    }

    try {
      String content = projectFile.readAsStringSync();

      final modulesPattern = RegExp(r'modules:\s*\[');
      final match = modulesPattern.firstMatch(content);

      if (match == null) {
        Logger.warn('Could not find modules list in project.dart');
        return;
      }

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

      String beforeBracket = content.substring(0, insertIndex).trimRight();
      final afterBracket = content.substring(insertIndex);

      final moduleEntries = StringBuffer();
      for (final entry in layerDeps.entries) {
        moduleEntries.write('\n');
        moduleEntries.write(
            CreateTemplates.projectModule(entry.key, entry.value));
      }

      final newContent = '$beforeBracket$moduleEntries\n  $afterBracket';
      projectFile.writeAsStringSync(newContent);

      for (final moduleName in layerDeps.keys) {
        Logger.info('  ✓ Added to project.dart: $moduleName');
      }

      Logger.success('Updated project.dart');
    } catch (e) {
      Logger.error('Failed to update project.dart: ${ErrorHelper.describe(e, '$currentDir/project.dart')}');
    }
  }

  /// Updates the package.dart file with new module entries.
  void _updatePackageDart(String currentDir, List<String> moduleNames) {
    Logger.info('Updating package.dart...');

    final packageFile = File('$currentDir/package.dart');

    if (!packageFile.existsSync()) {
      Logger.warn('package.dart not found. Skipping module registration.');
      return;
    }

    try {
      String content = packageFile.readAsStringSync();

      final modulesPattern = RegExp(r'modules:\s*\[');
      final match = modulesPattern.firstMatch(content);

      if (match == null) {
        Logger.warn('Could not find modules list in package.dart');
        return;
      }

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

      String beforeBracket = content.substring(0, insertIndex).trimRight();
      final afterBracket = content.substring(insertIndex);

      final moduleEntries = StringBuffer();
      for (final moduleName in moduleNames) {
        moduleEntries.write('\n');
        moduleEntries.write(CreateTemplates.packageModule(moduleName));
      }

      final newContent = '$beforeBracket$moduleEntries\n  $afterBracket';
      packageFile.writeAsStringSync(newContent);

      for (final moduleName in moduleNames) {
        Logger.info('  ✓ Added to package.dart: $moduleName');
      }

      Logger.success('Updated package.dart');
    } catch (e) {
      Logger.error('Failed to update package.dart: ${ErrorHelper.describe(e, '$currentDir/package.dart')}');
    }
  }

  /// Creates analysis_options.yaml that includes root config.
  void _createAnalysisOptions(String modulePath, String rootDir) {
    final normalizedModulePath = path.normalize(modulePath);
    final normalizedRootDir = path.normalize(rootDir);

    final relativePathToRoot =
        path.relative(normalizedRootDir, from: normalizedModulePath);
    final normalizedPath = relativePathToRoot.replaceAll('\\', '/');

    final analysisOptionsFile = File('$modulePath/analysis_options.yaml');
    final content = CreateTemplates.analysisOptionsYaml(normalizedPath);

    analysisOptionsFile.writeAsStringSync(content);
    Logger.info('  ✓ Created analysis_options.yaml');
  }

  /// Creates README.md file for a module.
  void _createReadme(
      String modulePath, String moduleName, ScaffoldType scaffoldType) {
    final readmeFile = File('$modulePath/README.md');
    final content = CreateTemplates.moduleReadme(moduleName, scaffoldType);
    readmeFile.writeAsStringSync(content);
    Logger.info('  ✓ Created README.md');
  }

  /// Checks if a module with the same path and name already exists.
  void _checkModuleExists(
    String currentDir,
    String path,
    String name,
    ScaffoldType scaffoldType,
  ) {
    if (scaffoldType == ScaffoldType.simple) {
      final pubspecPath = '$currentDir/$path/$name/pubspec.yaml';
      if (File(pubspecPath).existsSync()) {
        Logger.error('Module already exists at: $path/$name');
        Logger.error('   Found: $pubspecPath');
        exit(1);
      }
    } else {
      final parentPath = '$currentDir/$path/$name';
      if (Directory(parentPath).existsSync()) {
        Logger.error('Module already exists at: $path/$name');
        Logger.error('   Directory already exists: $parentPath');
        exit(1);
      }
    }
  }

  /// Returns the list of layer names for the given scaffold type.
  List<String> _getLayersForType(ScaffoldType scaffoldType, String moduleName) {
    switch (scaffoldType) {
      case ScaffoldType.clean:
        return [
          '${moduleName}_domain',
          '${moduleName}_data',
          '${moduleName}_presentation',
        ];

      case ScaffoldType.micro:
        return [
          '${moduleName}_example',
          '${moduleName}_interface',
          '${moduleName}_implementation',
          '${moduleName}_tests',
          '${moduleName}_testing',
        ];

      case ScaffoldType.lite:
        return [
          '${moduleName}_interface',
          '${moduleName}_implementation',
          '${moduleName}_tests',
          '${moduleName}_testing',
        ];

      case ScaffoldType.simple:
        return [];

      case ScaffoldType.custom:
        return [];
    }
  }
}
