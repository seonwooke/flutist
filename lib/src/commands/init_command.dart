import 'dart:io';

import 'package:path/path.dart' as path;

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
      await FileHelper.writeFile(
        path.join(rootPath, 'pubspec.yaml'),
        InitTemplates.pubspecYaml(projectName),
      );
      await FileHelper.writeFile(
        path.join(rootPath, 'analysis_options.yaml'),
        InitTemplates.analysisOptionsYaml(),
      );

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

      // 4. Add "app" module to workspace
      await WorkspaceEditor.addModuleToWorkspace(
        rootPath,
        'app',
        'app',
        ModuleType.simple,
      );

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
  /// 예제 스캐폴드 템플릿을 생성합니다.
  Future<void> _createExampleTemplates(String rootPath) async {
    Logger.info('Creating example templates...');

    final templatesDir = path.join(rootPath, 'flutist', 'templates');

    /// Feature template (BLoC pattern)
    await _createFeatureTemplate(templatesDir);

    Logger.success('Created example templates');
  }

  /// Creates feature template with BLoC pattern.
  /// BLoC 패턴 기능 템플릿을 생성합니다.
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
}
