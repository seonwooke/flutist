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

      // Get flutist package version from current package's pubspec.yaml
      final flutistVersion = await _getFlutistPackageVersion();

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
        await _mergePubspecYaml(pubspecPath, projectName, flutistVersion);
      } else {
        await FileHelper.writeFile(
          pubspecPath,
          InitTemplates.pubspecYaml(projectName, flutistVersion),
        );
      }

      await FileHelper.writeFile(
        path.join(rootPath, 'analysis_options.yaml'),
        InitTemplates.analysisOptionsYaml(),
      );

      // Read version from pubspec.yaml for README
      final pubspecContent = await File(pubspecPath).readAsString();
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

  /// Gets the flutist package version from the current package's pubspec.yaml.
  /// Priority: dart pub global list > local script path (for local development)
  Future<String> _getFlutistPackageVersion() async {
    try {
      // Priority 1: Try to get version from 'dart pub global list' (for globally installed packages)
      // This is the most common case when users run "dart pub global activate flutist"
      try {
        final result = await Process.run('dart', ['pub', 'global', 'list']);
        if (result.exitCode == 0) {
          final output = result.stdout as String;
          // Parse output like "flutist 1.0.7"
          final lines = output.split('\n');
          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.startsWith('flutist ')) {
              final parts = trimmed.split(RegExp(r'\s+'));
              if (parts.length >= 2) {
                final version = parts[1];
                if (version.isNotEmpty) {
                  return '^$version';
                }
              }
            }
          }
        }
      } catch (_) {
        // Ignore if dart pub global list fails
      }

      // Priority 2: Try to get the script location (bin/flutist.dart) for local development
      String? scriptPath;
      try {
        final scriptUri = Platform.script;
        if (scriptUri.scheme == 'file') {
          scriptPath = scriptUri.toFilePath();
        }
      } catch (_) {
        // Ignore if Platform.script fails
      }

      if (scriptPath != null && scriptPath.isNotEmpty) {
        final scriptFile = File(scriptPath);
        if (await scriptFile.exists()) {
          // Get the package root directory (go up from bin/flutist.dart to package root)
          final packageRoot = scriptFile.parent.parent;
          final pubspecFile = File(path.join(packageRoot.path, 'pubspec.yaml'));

          if (await pubspecFile.exists()) {
            final content = await pubspecFile.readAsString();
            final yamlDoc = loadYaml(content) as Map;
            final packageName = yamlDoc['name'] as String?;
            if (packageName == 'flutist') {
              final version = yamlDoc['version'] as String?;
              if (version != null) {
                return '^${version.split('+').first}';
              }
            }
          }
        }
      }
    } catch (e) {
      Logger.warn('Failed to read flutist package version: $e');
    }

    // Fallback version - this should not be reached if flutist is properly installed
    Logger.warn('Could not determine flutist version, using fallback: ^1.0.0');
    return '^1.0.0';
  }

  /// Merges Flutist configuration into existing pubspec.yaml.
  Future<void> _mergePubspecYaml(
    String pubspecPath,
    String projectName,
    String flutistVersion,
  ) async {
    Logger.info('Merging Flutist configuration into existing pubspec.yaml...');

    final content = await File(pubspecPath).readAsString();
    final editor = YamlEditor(content);
    final yamlDoc = loadYaml(content) as Map;

    // Add flutist dependency if not exists
    final dependencies = yamlDoc['dependencies'] as Map?;
    if (dependencies == null || !dependencies.containsKey('flutist')) {
      editor.update(['dependencies', 'flutist'], flutistVersion);
      Logger.info('  ✓ Added flutist dependency: $flutistVersion');
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
}
