import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../engine/engine.dart';
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

      // Determine isNewProject based on context
      bool isNewProject;

      if (!pubspecExists) {
        // No pubspec.yaml — ask to create Flutter project
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

          // Implicitly a new project — skip Q2
          isNewProject = true;
          Logger.info('Setting up as new project...');
        } else {
          Logger.info('Run "flutter create ." first, then "flutist init"');
          exit(0);
        }
      } else {
        // pubspec.yaml exists — ask new project or migration
        Logger.info('Is this a new project or an existing project migration?');
        Logger.info('  1) New project');
        Logger.info('  2) Existing project migration');
        final projectTypeAnswer = stdin.readLineSync()?.trim();
        isNewProject = projectTypeAnswer != '2';

        if (isNewProject) {
          Logger.info('Setting up as new project...');
        } else {
          Logger.info('Setting up as existing project migration...');
        }
      }

      // Get flutist package version from current package's pubspec.yaml
      final flutistVersion = await _getFlutistPackageVersion();

      // 2. Create root configuration files
      await FileHelper.writeFile(
        path.join(rootPath, 'project.dart'),
        InitTemplates.projectDart(projectName, isNewProject: isNewProject),
      );
      await FileHelper.writeFile(
        path.join(rootPath, 'package.dart'),
        InitTemplates.packageDart(projectName, isNewProject: isNewProject),
      );

      // Handle pubspec.yaml: merge if exists, create if not
      final pubspecPath = path.join(rootPath, 'pubspec.yaml');
      if (pubspecExists) {
        await _mergePubspecYaml(
          pubspecPath,
          projectName,
          flutistVersion,
          isNewProject: isNewProject,
        );
      } else {
        await FileHelper.writeFile(
          pubspecPath,
          InitTemplates.pubspecYaml(projectName, flutistVersion),
        );
      }

      final analysisOptionsPath = path.join(rootPath, 'analysis_options.yaml');
      if (!File(analysisOptionsPath).existsSync()) {
        await FileHelper.writeFile(
          analysisOptionsPath,
          InitTemplates.analysisOptionsYaml(),
        );
      } else {
        Logger.info('analysis_options.yaml already exists, skipping...');
      }

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

      if (isNewProject) {
        // 3. Scaffolding default "app" module (new project only)
        final appBasePath = path.join(rootPath, 'app');
        final appLibPath = path.join(appBasePath, 'lib');

        await Directory(appLibPath).create(recursive: true);

        // Create app.dart (main.dart is now in root/lib/)
        await FileHelper.writeFile(
          path.join(appLibPath, 'app.dart'),
          InitTemplates.appAppDart(),
        );

        // Create app/pubspec.yaml
        await FileHelper.writeFile(
          path.join(appBasePath, 'pubspec.yaml'),
          InitTemplates.appPubspecYaml(),
        );

        // 4. Create root/lib/main.dart (only if it doesn't exist)
        final rootLibPath = path.join(rootPath, 'lib');
        await Directory(rootLibPath).create(recursive: true);
        final mainDartPath = path.join(rootLibPath, 'main.dart');
        if (!File(mainDartPath).existsSync()) {
          await FileHelper.writeFile(
            mainDartPath,
            InitTemplates.rootMainDart(),
          );
        } else {
          Logger.info('lib/main.dart already exists, skipping...');
        }

        // 5. Add "app" module to workspace and dependencies
        await _ensureAppInWorkspace(rootPath);
        await _ensureAppInDependencies(pubspecPath);
      }

      // 6. Create example templates
      await _createExampleTemplates(rootPath);

      // 7. Generate flutist_gen.dart
      GenFileGenerator.generate(rootPath);

      Logger.success('Flutist initialization complete!');
      Logger.info('Next: Run "flutter pub get" to install dependencies');
    } catch (e) {
      Logger.error('Initialization failed: $e');
    }
  }

  Future<void> _removeFilesAndFolders(String rootPath) async {
    // Remove files and folders created by flutter create
    // Note: We keep lib/ folder as it will contain main.dart
    final testDir = Directory(path.join(rootPath, 'test'));
    final pubspecFile = File(path.join(rootPath, 'pubspec.yaml'));
    final analysisOptionsFile =
        File(path.join(rootPath, 'analysis_options.yaml'));
    final readmeFile = File(path.join(rootPath, 'README.md'));

    // Remove test folder and all its contents

    if (testDir.existsSync()) {
      await testDir.delete(recursive: true);
      Logger.info('Removed test folder');
    }

    // Remove pubspec.yaml (we'll create our own)
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

    await FileHelper.writeFile(
      path.join(featureDir, 'template.yaml'),
      InitTemplates.featureTemplateYaml(),
    );

    await FileHelper.writeFile(
      path.join(featureDir, 'widget.dart.template'),
      InitTemplates.featureWidgetDartTemplate(),
    );
  }

  /// Gets the flutist package version from the current package's pubspec.yaml.
  /// Priority: running script's pubspec.yaml > dart pub global list
  Future<String> _getFlutistPackageVersion() async {
    try {
      // Priority 1: Read version from the running script's own pubspec.yaml.
      // This is always accurate regardless of which version is globally installed.
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

      // Priority 2: Fall back to 'dart pub global list' if script path is unavailable.
      try {
        final result = await Process.run('dart', ['pub', 'global', 'list']);
        if (result.exitCode == 0) {
          final output = result.stdout as String;
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
    String flutistVersion, {
    required bool isNewProject,
  }) async {
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

    if (isNewProject) {
      // Add app dependency if not exists (new project only)
      if (dependencies == null || !dependencies.containsKey('app')) {
        editor.update(['dependencies', 'app'], {'path': 'app'});
        Logger.info('  ✓ Added app dependency: path: app');
      } else {
        Logger.info('  ✓ app dependency already exists');
      }
    }

    // Ensure flutter.uses-material-design is set
    final flutterSection = yamlDoc['flutter'] as Map?;
    if (flutterSection == null || flutterSection['uses-material-design'] != true) {
      editor.update(['flutter', 'uses-material-design'], true);
      Logger.info('  ✓ Added flutter.uses-material-design: true');
    } else {
      Logger.info('  ✓ flutter.uses-material-design already set');
    }

    if (isNewProject) {
      // Ensure workspace section exists with app (block style: "- item" not "[item]")
      final workspace = yamlDoc['workspace'];
      if (workspace is List) {
        if (!workspace.contains('app')) {
          editor.appendToList(['workspace'], 'app');
          Logger.info('  ✓ Added app to workspace');
        } else {
          Logger.info('  ✓ app already in workspace');
        }
      } else {
        editor.update(
          ['workspace'],
          wrapAsYamlNode(['app'], collectionStyle: CollectionStyle.BLOCK),
        );
        Logger.info('  ✓ Added workspace section with app');
      }
    }
    // For existing project migration: intentionally skip creating the workspace
    // section. An empty `workspace: []` makes `flutter pub get` fail, and the
    // section will be created on demand by WorkspaceEditor when the first
    // module is added via `flutist create`.

    // Ensure blank line before workspace section
    var result = editor.toString();
    result = result.replaceAllMapped(
      RegExp(r'([^\n])\nworkspace:'),
      (match) => '${match.group(1)}\n\nworkspace:',
    );

    await File(pubspecPath).writeAsString(result);
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
    );
  }

  /// Ensures app module is in dependencies as path dependency.
  Future<void> _ensureAppInDependencies(String pubspecPath) async {
    final pubspecFile = File(pubspecPath);
    if (!await pubspecFile.exists()) return;

    final content = await pubspecFile.readAsString();
    final editor = YamlEditor(content);
    final yamlDoc = loadYaml(content) as Map;

    // Add app dependency if not exists
    final dependencies = yamlDoc['dependencies'] as Map?;
    if (dependencies == null || !dependencies.containsKey('app')) {
      editor.update(['dependencies', 'app'], {'path': 'app'});
      Logger.info('  ✓ Added app dependency: path: app');
    } else {
      Logger.info('  ✓ app dependency already exists');
    }

    await pubspecFile.writeAsString(editor.toString());
  }
}
