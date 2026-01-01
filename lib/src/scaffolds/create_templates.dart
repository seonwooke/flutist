import '../core/core.dart';

/// Template generator for module creation.
class CreateTemplates {
  /// Generates pubspec.yaml content for a module.
  static String pubspecYaml(String modulePath, String moduleName) => '''
name: $moduleName
description: A Flutter module
version: 1.0.0+1
publish_to: 'none'

environment:
  sdk: ^3.5.0

dependencies:

resolution: workspace
''';

  /// Generates main.dart content for library example layer.
  static String mainDart(String projectName) => '''
void main() {
  // Example entry point
}
''';

  /// Generates Module entry for project.dart.
  static String projectModule(String moduleName, ModuleType moduleType) => '''
    Module(
      name: '$moduleName',
      type: ModuleType.${moduleType.name},
      dependencies: [],
      devDependencies: [],
      modules: [],
    ),''';

  /// Generates Module entry for package.dart.
  static String packageModule(String moduleName, ModuleType moduleType) => '''
    Module(name: '$moduleName', type: ModuleType.${moduleType.name}),''';

  /// Generates analysis_options.yaml that includes root config.
  ///
  /// [relativePath] - Path to root (e.g., "../.." for features/login/login_example)
  static String analysisOptionsYaml(String relativePath) => '''
# This module inherits lint rules from the root analysis_options.yaml
include: $relativePath/analysis_options.yaml
''';
}
