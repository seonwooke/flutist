import '../core/core.dart';
import '../utils/utils.dart';

/// Template generator for module creation.
class CreateTemplates {
  /// Generates pubspec.yaml content for a module.
  ///
  /// [isFlutterModule] — if true, adds `flutter: sdk: flutter` to dependencies.
  /// Used for _implementation and _example layers that contain Flutter UI code.
  static String pubspecYaml(String modulePath, String moduleName,
      {bool isFlutterModule = false}) {
    final flutterDep =
        isFlutterModule ? '  flutter:\n    sdk: flutter\n' : '';
    return '''
name: $moduleName
description: A Flutter module
version: 1.0.0+1
publish_to: 'none'

environment:
  sdk: ">=3.5.0 <4.0.0"

dependencies:
$flutterDep
resolution: workspace
''';
  }

  /// Generates main.dart content for library example layer.
  static String mainDart(String projectName) => '''
void main() {
  // Example entry point
}
''';

  /// Generates Module entry for project.dart.
  ///
  /// [moduleRefs] - list of module names this module depends on (B6 auto-wiring).
  static String projectModule(String moduleName, [List<String> moduleRefs = const []]) {
    final modulesContent = moduleRefs.isEmpty
        ? '[]'
        : '[\n${moduleRefs.map((m) => '        package.modules.${StringCase.toCamelCase(m)},').join('\n')}\n      ]';
    return '''    Module(
      name: '$moduleName',
      dependencies: [],
      devDependencies: [],
      modules: $modulesContent,
    ),''';
  }

  /// Generates Module entry for package.dart.
  static String packageModule(String moduleName) => '''
    Module(name: '$moduleName'),''';

  /// Generates analysis_options.yaml that includes root config.
  ///
  /// [relativePath] - Path to root (e.g., "../.." for features/login/login_example)
  static String analysisOptionsYaml(String relativePath) => '''
# This module inherits lint rules from the root analysis_options.yaml
include: $relativePath/analysis_options.yaml
''';

  /// Generates README.md content for a module.
  static String moduleReadme(String moduleName, ScaffoldType scaffoldType) => '''
<div align="center">

<img src="https://raw.githubusercontent.com/seonwooke/flutist/release/1.0.0/assets/flutist_banner.png" alt="Flutist Banner" width="50%">

</div>

Module in Flutist workspace.

## 📋 Overview

This module is part of the Flutist workspace project. Dependencies are managed centrally in the root `package.dart` file.

## 🏗️ Scaffold Type

**Type:** `${scaffoldType.name}`

${_getScaffoldTypeDescription(scaffoldType)}

## 📦 Dependencies

Dependencies for this module are defined in the root `project.dart` file. To add dependencies:

1. Edit `project.dart` and add dependencies to this module's configuration
2. Run `flutist generate` to sync the changes

## 🚀 Usage

This module can be imported and used by other modules in the workspace:

```dart
import 'package:$moduleName/$moduleName.dart';
```

## 📁 Structure

${_getModuleStructure(scaffoldType, moduleName)}

## 🔧 Development

When working on this module:

1. Make your changes in the module's source files
2. Run `flutist generate` to ensure dependencies are synced
3. Test the module in isolation or as part of the main app

## 📝 Notes

- This module follows the Flutist workspace conventions
- All dependencies are managed at the workspace level
- Module-specific configuration can be found in this module's `pubspec.yaml`
''';

  static String _getScaffoldTypeDescription(ScaffoldType type) {
    switch (type) {
      case ScaffoldType.clean:
        return '''
This is a **clean module** with a 3-layer Clean Architecture:
- **Domain Layer** - Business logic and entities
- **Data Layer** - Data sources and repositories
- **Presentation Layer** - UI components and state management
''';
      case ScaffoldType.micro:
        return '''
This is a **micro module** with a 5-layer Microfeature Architecture:
- **Example Layer** - Example usage and demos
- **Interface Layer** - Public API and contracts
- **Implementation Layer** - Core implementation
- **Tests Layer** - Unit and widget tests
- **Testing Layer** - Test utilities and mocks
''';
      case ScaffoldType.lite:
        return '''
This is a **lite module** with a 4-layer Microfeature lite Architecture:
- **Interface Layer** - Public API and contracts
- **Implementation Layer** - Core functionality
- **Tests Layer** - Unit and integration tests
- **Testing Layer** - Test utilities and helpers
''';
      case ScaffoldType.simple:
        return '''
This is a **simple module** with a minimal structure:
- **lib/** - Source code directory
''';
      case ScaffoldType.custom:
        return '''
This is a **custom module** with custom template structure.
''';
    }
  }

  static String _getModuleStructure(ScaffoldType type, String moduleName) {
    switch (type) {
      case ScaffoldType.clean:
        return '''
```
$moduleName/
├── ${moduleName}_domain/     # Domain layer
│   └── lib/
├── ${moduleName}_data/       # Data layer
│   └── lib/
└── ${moduleName}_presentation/  # Presentation layer
    └── lib/
```
''';
      case ScaffoldType.micro:
        return '''
```
$moduleName/
├── ${moduleName}_example/        # Example layer
│   └── lib/
├── ${moduleName}_interface/      # Interface layer
│   └── lib/
├── ${moduleName}_implementation/ # Implementation layer
│   └── lib/
├── ${moduleName}_tests/          # Tests layer
│   └── lib/
└── ${moduleName}_testing/        # Testing layer
    └── lib/
```
''';
      case ScaffoldType.lite:
        return '''
```
$moduleName/
├── ${moduleName}_interface/      # Interface layer
│   └── lib/
├── ${moduleName}_implementation/ # Implementation layer
│   └── lib/
├── ${moduleName}_tests/          # Tests layer
│   └── lib/
└── ${moduleName}_testing/        # Testing layer
    └── lib/
```
''';
      case ScaffoldType.simple:
        return '''
```
$moduleName/
└── lib/              # Source code
```
''';
      case ScaffoldType.custom:
        return '''
```
$moduleName/
└── [Custom structure]
```
''';
    }
  }
}
