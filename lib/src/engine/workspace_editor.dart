import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../utils/utils.dart';

/// Utility class for editing workspace configuration in pubspec.yaml.
class WorkspaceEditor {
  /// Adds a module to the workspace configuration in pubspec.yaml.
  ///
  /// [rootPath] - Root directory path of the project.
  /// [modulePath] - Path where the module is located.
  /// [moduleName] - Name of the module.
  static Future<void> addModuleToWorkspace(
    String rootPath,
    String modulePath,
    String moduleName,
  ) async {
    final pubspecFile = File(path.join(rootPath, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) return;

    final content = await pubspecFile.readAsString();
    final editor = YamlEditor(content);

    await _addModuleToWorkspace(rootPath, modulePath, moduleName, editor);

    await pubspecFile.writeAsString(editor.toString());
    Logger.success('Added module to workspace: $moduleName');
  }

  /// Adds a module to the workspace configuration.
  static Future<void> _addModuleToWorkspace(
    String rootPath,
    String modulePath,
    String moduleName,
    YamlEditor editor,
  ) async {
    final relativeModulePath = moduleName;

    try {
      editor.appendToList(['workspace'], relativeModulePath);
    } catch (e) {
      editor.update(
        ['workspace'],
        wrapAsYamlNode([relativeModulePath],
            collectionStyle: CollectionStyle.BLOCK),
      );
    }
  }
}
