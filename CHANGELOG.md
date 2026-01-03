# Changelog

All notable changes to Flutist will be documented in this file.

## [1.0.8] - 2025-01-02

### 🐛 Fixed
- **`flutist init` command**:
  - Fixed version detection using `dart pub global list` command instead of pubspec.yaml lookup
  - `global_packages` directory doesn't contain `pubspec.yaml`, only `pubspec.lock`
  - Now correctly reads installed flutist version from `dart pub global list` output
  - Fixes issue where version detection failed for globally installed packages via `dart pub global activate`

## [1.0.7] - 2025-01-02

### 🐛 Fixed
- **`flutist init` command**:
  - Fixed version detection when running `flutist init` after `dart pub global activate flutist`
  - Prioritized `global_packages` lookup to correctly read installed flutist version
  - Added package name validation to ensure correct `pubspec.yaml` is read
  - Simplified version detection logic by removing unnecessary directory traversal
  - Now correctly adds the installed flutist version to project dependencies instead of fallback version

## [1.0.6] - 2025-01-02

### 🔧 Improved
- **`flutist init` command**:
  - Dynamically reads flutist package version from current package's `pubspec.yaml`
  - Uses pub.dev package instead of local path reference
  - Automatically reflects version updates when `pubspec.yaml` is updated
  - Changed from hardcoded version to dynamic version reading

## [1.0.5] - 2025-01-02

### 🎨 Style
- Applied Dart formatter to example files and codebase
  - Formatted `example/flutist/flutist_gen.dart`
  - Formatted `example/package.dart`
  - Applied consistent code formatting across the project

## [1.0.4] - 2025-01-02

### 🐛 Fixed
- Fixed `flutist run` command creating `root/lib/main.dart` file
  - Added explicit `-t` flag to target `app/lib/main.dart` when running Flutter
  - Automatically detects and removes existing `root/lib/main.dart` if found
  - Prevents Flutter from auto-creating `root/lib/main.dart` file

## [1.0.3] - 2025-01-02

### 🐛 Fixed
- Fixed `flutist run` command creating unnecessary `root/lib/main.dart` file
  - Removed auto-generation logic that created `root/lib/main.dart` when missing
  - Flutter workspace automatically finds `app/lib/main.dart` when running from root directory
  - Updated README.md documentation to reflect correct behavior

## [1.0.2] - 2025-01-02

### ✨ Added
- Example directory for pub.dev with complete project structure demonstration
  - `README.md` with usage instructions and module type explanations
  - `directory_structure.md` with Microfeature Architecture visualization
  - Example `package.dart` and `project.dart` configuration files
  - Example `pubspec.yaml` with workspace configuration
  - Example `flutist_gen.dart` showing generated code structure

### 🔧 Improved
- **`flutist init` command**:
  - Prevent overwriting existing `README.md` files
  - Merge Flutist configuration into existing `pubspec.yaml` instead of overwriting
  - Automatically add `workspace` section if missing
  - Automatically add `app` module to workspace if not exists
  - Automatically add `flutist` dependency with latest version when merging
  - Fix `app.dart` import path in `main.dart` (use relative import instead of package import)
- **README.md**:
  - Add "Core Commands" section highlighting main 4 commands (`init`, `create`, `generate`, `scaffold`)
  - Add "All Commands" table at the top for quick reference
  - Improve command visibility with larger headings and bold text
  - Add `scaffold` example to Quick Start section

### 🐛 Fixed
- Fixed import path in generated `app/lib/main.dart` (changed from `package:app/app.dart` to `app.dart`)
- Fixed dependency getter names in example files (camelCase conversion: `shared_preferences` → `sharedPreferences`, `json_annotation` → `jsonAnnotation`)
- Suppressed warnings in example directory with custom `analysis_options.yaml`

## [1.0.1] - 2025-01-02

### 🐛 Fixed
- Fixed README.md banner image loading issue by using GitHub raw URL instead of relative path

## [1.0.0] - 2025-01-02

### 🎉 Initial Release

Flutist is a Flutter project management framework inspired by Tuist, providing declarative module structure and dependency management.

### ✨ Features

#### Core Commands
- **`flutist init`** - Initialize project with workspace support
- **`flutist create`** - Create modules (simple, feature, library, standard)
- **`flutist generate`** - Sync dependencies with type-safe auto-completion
- **`flutist scaffold`** - Generate code from templates (Tuist-style)
- **`flutist graph`** - Visualize module dependencies (Mermaid, DOT, ASCII)
- **`flutist run`** - Run Flutter app
- **`flutist pub`** - Manage packages

### 🏗️ Module Types
- **Simple** - Single-layer module
- **Feature** - 3-layer (Domain, Data, Presentation)
- **Library** - 5-layer (Example, Interface, Implementation, Testing, Tests)
- **Standard** - 3-layer (Implementation, Tests, Testing)

### 📦 What's Included
- Auto-generated `flutist_gen.dart` for type-safe dependencies
- Built-in feature template (BLoC pattern)
- Comprehensive `analysis_options.yaml` (100+ lint rules)
- Automatic workspace registration
- Smart relative path calculation

### 🐛 Known Issues
- iOS build requires workspace workaround (Flutter limitation)
  - **Solution**: Use Android/Web for development

### 📚 Quick Example
```bash
flutist init
flutist create --path features --name login --options library
flutist generate
flutist graph --open
```

### 🙏 Credits
Inspired by [Tuist](https://tuist.io/)

---

[1.0.0]: https://github.com/yourusername/flutist/releases/tag/v1.0.0