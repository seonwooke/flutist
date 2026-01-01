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
      final rootPath = Directory.current.path;
      final projectName = path.basename(rootPath);

      Logger.info('Initializing Flutist project...');

      // 1. Create root configuration files
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

      // 2. Scaffolding default "app" module
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

      // 3. Add "app" module to workspace
      await WorkspaceEditor.addModuleToWorkspace(
        rootPath,
        'app',
        'app',
        ModuleType.simple,
      );

      // 4. Generate flutist_gen.dart ✨ 추가!
      GenFileGenerator.generate(rootPath);

      Logger.success('Flutist initialization complete!');
      Logger.info('Next: Run "flutter pub get" to install dependencies');
    } catch (e) {
      Logger.error('Initialization failed: $e');
    }
  }
}
