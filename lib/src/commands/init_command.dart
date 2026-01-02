import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../core/core.dart';
import '../generator/flutist_generator.dart';
import '../parser/parser.dart';
import '../scaffolds/init_templates.dart';
import '../utils/utils.dart';
import 'commands.dart';

class InitCommand implements BaseCommand {
  @override
  String get name => 'init';

  @override
  String get description =>
      'Initialize a new Flutist project with Workspace support.';

  @override
  void execute(List<String> arguments) async {
    try {
      Logger.banner();

      final rootPath = Directory.current.path;
      final projectName = path.basename(rootPath);

      // 1. Check if Flutter project exists
      final pubspecExists = File('$rootPath/pubspec.yaml').existsSync();

      if (!pubspecExists) {
        // Ask user if they want to create Flutter project
        Logger.warn('No Flutter project found in current directory.');
        Logger.info('Do you want to create a new Flutter project? (y/n)');

        final answer = stdin.readLineSync()?.toLowerCase();

        if (answer == 'y' || answer == 'yes') {
          Logger.info('Creating Flutter project...');

          final result = await Process.run(
            'flutter',
            ['create', '.', '--project-name', projectName],
            workingDirectory: rootPath,
          );

          if (result.exitCode != 0) {
            Logger.error('Failed to create Flutter project');
            exit(1);
          }

          // Remove files and folders created by flutter create
          await _removeFilesAndFolders(rootPath);

          Logger.success('Flutter project created');
        } else {
          Logger.error('Flutist requires a Flutter project.');
          Logger.info('Run "flutter create ." first, then "flutist init"');
          exit(1);
        }
      }

      Logger.info('Initializing Flutist project...');

      // 2. Create root configuration files
      await FileHelper.writeFile(
        path.join(rootPath, 'project.dart'),
        InitTemplates.projectDart(projectName),
      );
      await FileHelper.writeFile(
        path.join(rootPath, 'package.dart'),
        InitTemplates.packageDart(projectName),
      );

      // Handle pubspec.yaml: merge if exists, create if not
      final pubspecPath = path.join(rootPath, 'pubspec.yaml');
      if (pubspecExists) {
        await _mergePubspecYaml(pubspecPath, projectName);
      } else {
        await FileHelper.writeFile(
          pubspecPath,
          InitTemplates.pubspecYaml(projectName),
        );
      }

      await FileHelper.writeFile(
        path.join(rootPath, 'analysis_options.yaml'),
        InitTemplates.analysisOptionsYaml(),
      );

      // Read version from pubspec.yaml for README
      final pubspecContent =
          await File(pubspecPath).readAsString();
      final versionMatch =
          RegExp(r'version:\s*([^\s]+)').firstMatch(pubspecContent);
      final version = versionMatch?.group(1) ?? '1.0.0+1';

      // Only create README.md if it doesn't exist
      final readmePath = path.join(rootPath, 'README.md');
      if (!File(readmePath).existsSync()) {
        await FileHelper.writeFile(
          readmePath,
          InitTemplates.rootReadme(projectName, version),
        );
      } else {
        Logger.info('README.md already exists, skipping...');
      }

      // 3. Scaffolding default "app" module
      final appBasePath = path.join(rootPath, 'app');
      final appLibPath = path.join(appBasePath, 'lib');

      await Directory(appLibPath).create(recursive: true);

      // Create main.dart
      await FileHelper.writeFile(
        path.join(appLibPath, 'main.dart'),
        InitTemplates.appMainDart(),
      );

      // Create app.dart
      await FileHelper.writeFile(
        path.join(appLibPath, 'app.dart'),
        InitTemplates.appAppDart(),
      );

      // Create app/pubspec.yaml
      await FileHelper.writeFile(
        path.join(appBasePath, 'pubspec.yaml'),
        InitTemplates.appPubspecYaml(),
      );

      // 4. Add "app" module to workspace (if not already added)
      await _ensureAppInWorkspace(rootPath);

      // 5. Create example templates
      await _createExampleTemplates(rootPath);

      // 6. Generate flutist_gen.dart
      GenFileGenerator.generate(rootPath);

      Logger.success('Flutist initialization complete!');
      Logger.info('Next: Run "flutter pub get" to install dependencies');
    } catch (e) {
      Logger.error('Initialization failed: $e');
    }
  }

  Future<void> _removeFilesAndFolders(String rootPath) async {
    // Remove files and folders created by flutter create
    final libDir = Directory(path.join(rootPath, 'lib'));
    final testDir = Directory(path.join(rootPath, 'test'));
    final pubspecFile = File(path.join(rootPath, 'pubspec.yaml'));
    final analysisOptionsFile =
        File(path.join(rootPath, 'analysis_options.yaml'));
    final readmeFile = File(path.join(rootPath, 'README.md'));

    // Remove lib folder and all its contents
    if (libDir.existsSync()) {
      await libDir.delete(recursive: true);
      Logger.info('Removed lib folder');
    }

    // Remove test folder and all its contents
    if (testDir.existsSync()) {
      await testDir.delete(recursive: true);
      Logger.info('Removed test folder');
    }

    // Remove pubspec.yaml
    if (pubspecFile.existsSync()) {
      await pubspecFile.delete();
      Logger.info('Removed pubspec.yaml');
    }

    // Remove analysis_options.yaml
    if (analysisOptionsFile.existsSync()) {
      await analysisOptionsFile.delete();
      Logger.info('Removed analysis_options.yaml');
    }

    // Remove README.md
    if (readmeFile.existsSync()) {
      await readmeFile.delete();
      Logger.info('Removed README.md');
    }
  }

  /// Creates example scaffold templates.
  Future<void> _createExampleTemplates(String rootPath) async {
    Logger.info('Creating example templates...');

    final templatesDir = path.join(rootPath, 'flutist', 'templates');

    /// Feature template (BLoC pattern)
    await _createFeatureTemplate(templatesDir);

    Logger.success('Created example templates');
  }

  /// Creates feature template with BLoC pattern.
  Future<void> _createFeatureTemplate(String templatesDir) async {
    final featureDir = path.join(templatesDir, 'feature');
    await Directory(featureDir).create(recursive: true);

    // template.yaml
    await FileHelper.writeFile(
      path.join(featureDir, 'template.yaml'),
      InitTemplates.featureTemplateYaml(),
    );

    // bloc.dart.template
    await FileHelper.writeFile(
      path.join(featureDir, 'bloc.dart.template'),
      InitTemplates.featureBlocDartTemplate(),
    );

    // state.dart.template
    await FileHelper.writeFile(
      path.join(featureDir, 'state.dart.template'),
      InitTemplates.featureStateDartTemplate(),
    );

    // event.dart.template
    await FileHelper.writeFile(
      path.join(featureDir, 'event.dart.template'),
      InitTemplates.featureEventDartTemplate(),
    );

      // screen.dart.template
      await FileHelper.writeFile(
        path.join(featureDir, 'screen.dart.template'),
        InitTemplates.featureScreenDartTemplate(),
      );
  }

  /// Merges Flutist configuration into existing pubspec.yaml.
  Future<void> _mergePubspecYaml(String pubspecPath, String projectName) async {
    Logger.info('Merging Flutist configuration into existing pubspec.yaml...');

    final content = await File(pubspecPath).readAsString();
    final editor = YamlEditor(content);
    final yamlDoc = loadYaml(content) as Map;

    // Add flutist dependency if not exists
    final dependencies = yamlDoc['dependencies'] as Map?;
    if (dependencies == null || !dependencies.containsKey('flutist')) {
      try {
        final latestVersion = await _getFlutistLatestVersion();
        editor.update(['dependencies', 'flutist'], latestVersion);
        Logger.info('  ✓ Added flutist dependency: $latestVersion');
      } catch (e) {
        Logger.warn('  ⚠ Failed to get flutist version, using ^1.0.1');
        editor.update(['dependencies', 'flutist'], '^1.0.1');
      }
    } else {
      Logger.info('  ✓ flutist dependency already exists');
    }

    // Ensure workspace section exists
    if (!yamlDoc.containsKey('workspace')) {
      editor.update(['workspace'], []);
      Logger.info('  ✓ Added workspace section');
    }

    // Add app to workspace if not exists
    final workspace = yamlDoc['workspace'];
    if (workspace is List) {
      if (!workspace.contains('app')) {
        editor.appendToList(['workspace'], 'app');
        Logger.info('  ✓ Added app to workspace');
      } else {
        Logger.info('  ✓ app already in workspace');
      }
    } else {
      // workspace exists but is not a list, replace it
      editor.update(['workspace'], ['app']);
      Logger.info('  ✓ Updated workspace section with app');
    }

    await File(pubspecPath).writeAsString(editor.toString());
    Logger.success('Merged pubspec.yaml');
  }

  /// Ensures app module is in workspace, avoiding duplicates.
  Future<void> _ensureAppInWorkspace(String rootPath) async {
    final pubspecFile = File(path.join(rootPath, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) return;

    final content = await pubspecFile.readAsString();
    final yamlDoc = loadYaml(content) as Map;
    final workspace = yamlDoc['workspace'];

    if (workspace is List && workspace.contains('app')) {
      Logger.info('app already in workspace, skipping...');
      return;
    }

    await WorkspaceEditor.addModuleToWorkspace(
      rootPath,
      'app',
      'app',
      ModuleType.simple,
    );
  }

  /// Gets the latest version of flutist from pub.dev.
  Future<String> _getFlutistLatestVersion() async {
    try {
      final result = await Process.run(
        'dart',
        ['pub', 'deps', '--style=compact', '--json'],
        workingDirectory: Directory.current.path,
      );

      if (result.exitCode == 0) {
        // Try to get version from pub.dev
        final pubResult = await Process.run(
          'dart',
          ['pub', 'add', 'flutist', '--dry-run'],
          workingDirectory: Directory.current.path,
        );

        if (pubResult.exitCode == 0) {
          final output = pubResult.stdout.toString();
          final versionMatch = RegExp(r'flutist\s+(\S+)').firstMatch(output);
          if (versionMatch != null) {
            return versionMatch.group(1)!;
          }
        }
      }
    } catch (e) {
      Logger.warn('Failed to get flutist version: $e');
    }

    // Fallback: use current version or latest known version
    return '^1.0.1';
  }
}
