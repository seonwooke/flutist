import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml_edit/yaml_edit.dart';

import '../core/core.dart';
import '../utils/utils.dart';

/// Utility class for editing workspace configuration in pubspec.yaml.
class WorkspaceEditor {
  /// Adds a module to the workspace configuration in pubspec.yaml.
  ///
  /// [rootPath] - Root directory path of the project.
  /// [modulePath] - Path where the module is located.
  /// [moduleName] - Name of the module.
  /// [moduleType] - Type of the module.
  static Future<void> addModuleToWorkspace(
    String rootPath,
    String modulePath,
    String moduleName,
    ModuleType moduleType,
  ) async {
    final pubspecFile = File(path.join(rootPath, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) return;

    final content = await pubspecFile.readAsString();
    final editor = YamlEditor(content);

    switch (moduleType) {
      case ModuleType.feature:
        break;
      case ModuleType.library:
        break;
      case ModuleType.standard:
        break;
      case ModuleType.simple:
        await _addSimpleModuleToWorkspace(
          rootPath,
          modulePath,
          moduleName,
          editor,
        );
        break;
      case ModuleType.custom:
        break;
    }

    await pubspecFile.writeAsString(editor.toString());
    Logger.success('Added module to workspace: $moduleName');
  }

  /// Adds a simple module to the workspace configuration.
  static Future<void> _addSimpleModuleToWorkspace(
    String rootPath,
    String modulePath,
    String moduleName,
    YamlEditor editor,
  ) async {
    final relativeModulePath = moduleName;

    try {
      editor.appendToList(['workspace'], relativeModulePath);
    } catch (e) {
      editor.update(['workspace'], [relativeModulePath]);
    }
  }
}
