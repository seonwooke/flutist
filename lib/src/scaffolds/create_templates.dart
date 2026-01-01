import '../core/core.dart';

class CreateTemplates {
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

  static String mainDart(String projectName) => '''
void main() {
  // Example entry point
}
''';

  static String projectModule(String moduleName, ModuleType moduleType) => '''
    Module(
      name: '$moduleName',
      type: ModuleType.${moduleType.name},
      dependencies: [],
      devDependencies: [],
      modules: [],
    ),''';

  static String packageModule(String moduleName, ModuleType moduleType) => '''
    Module(name: '$moduleName', type: ModuleType.${moduleType.name}),''';

  /// Generates analysis_options.yaml that includes root config.
  /// root 설정을 include하는 analysis_options.yaml을 생성합니다.
  ///
  /// [relativePath] - Path to root (e.g., "../.." for features/login/login_example)
  static String analysisOptionsYaml(String relativePath) => '''
# This module inherits lint rules from the root analysis_options.yaml
include: $relativePath/analysis_options.yaml
''';
}
