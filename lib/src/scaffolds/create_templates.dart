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
  sdk: ">=3.5.0 <4.0.0"

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

  /// Generates README.md content for a module.
  static String moduleReadme(String moduleName, ModuleType moduleType) => '''
<div align="center">

<img src="https://raw.githubusercontent.com/seonwooke/flutist/release/1.0.0/assets/flutist_banner.png" alt="Flutist Banner" width="50%">

</div>

Module in Flutist workspace.

## 📋 Overview

This module is part of the Flutist workspace project. Dependencies are managed centrally in the root `package.dart` file.

## 🏗️ Module Type

**Type:** `${moduleType.name}`

${_getModuleTypeDescription(moduleType)}

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

${_getModuleStructure(moduleType, moduleName)}

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

  static String _getModuleTypeDescription(ModuleType type) {
    switch (type) {
      case ModuleType.feature:
        return '''
This is a **feature module** with a 3-layer architecture:
- **Domain Layer** - Business logic and entities
- **Data Layer** - Data sources and repositories
- **Presentation Layer** - UI components and state management
''';
      case ModuleType.library:
        return '''
This is a **library module** with a 5-layer architecture:
- **Example Layer** - Example usage and demos
- **Implementation Layer** - Core implementation
- **Interface Layer** - Public API and contracts
- **Tests Layer** - Unit and widget tests
- **Testing Layer** - Test utilities and mocks
''';
      case ModuleType.standard:
        return '''
This is a **standard module** with a 3-layer architecture:
- **Implementation Layer** - Core functionality
- **Tests Layer** - Unit and integration tests
- **Testing Layer** - Test utilities and helpers
''';
      case ModuleType.simple:
        return '''
This is a **simple module** with a minimal structure:
- **lib/** - Source code directory
''';
      case ModuleType.custom:
        return '''
This is a **custom module** with custom template structure.
''';
    }
  }

  static String _getModuleStructure(ModuleType type, String moduleName) {
    switch (type) {
      case ModuleType.feature:
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
      case ModuleType.library:
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
      case ModuleType.standard:
        return '''
```
$moduleName/
├── ${moduleName}_implementation/ # Implementation layer
│   └── lib/
├── ${moduleName}_tests/          # Tests layer
│   └── lib/
└── ${moduleName}_testing/        # Testing layer
    └── lib/
```
''';
      case ModuleType.simple:
        return '''
```
$moduleName/
└── lib/              # Source code
```
''';
      case ModuleType.custom:
        return '''
```
$moduleName/
└── [Custom structure]
```
''';
    }
  }
}
