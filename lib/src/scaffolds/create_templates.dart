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
  flutter:
    sdk: flutter

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
    ),''';
}
