# Changelog

All notable changes to Flutist will be documented in this file.

## [2.1.0] - 2026-04-07

### ✨ New Features

- **`flutist init`: New/existing project selection**
  - Choose between new project creation or existing project migration during init
  - Existing project: skip app module creation, skip workspace app entry, generate empty project.dart/package.dart
- **`flutist pub add`: Multi-package support**
  - Add multiple packages at once with `flutist pub add http dio`
- **Template usage guide comments for existing projects**
  - Added 3-step workflow comments and examples to `project.dart` and `package.dart`

### 🐛 Fixed

- **`flutist create`**: Fixed missing module name in simple module path (`packages/` → `packages/core`)
- **`flutist create`**: Warn and exit when layer module name suffix is entered redundantly
- **`flutist create`**: Warn and exit when last path segment matches the module name (nested path detection)
- **`flutist create`**: Auto-generate barrel file (`lib/module_name.dart`) when creating a module
- **`flutist generate`**: Cross-path module dependency resolution — removed hardcoded basePaths, now resolved dynamically via workspace scan
- **`flutist generate`**: Preserve all SDK dependencies including `flutter`, `flutter_localizations`, etc. (previously only `flutter` was preserved)
- **`flutist init`**: Do not overwrite `lib/main.dart` if it already exists
- **`flutist init`**: Do not overwrite `analysis_options.yaml` if it already exists
- **`flutist init`**: Workspace entries are now added in block style (`- path/to/module`)
- **`flutist pub add`**: Fixed format corruption where `],` was appended on the same line on repeated runs
- **`flutist pub add`**: Fixed duplicate output of `Generated flutist_gen.dart` message
- **`flutist scaffold`**: Fixed bug where `--path` option existed in docs but did not actually work
- **`flutist test`**: Print full stdout/stderr without keyword filtering on failure
- **Architecture Checker**: Allow `_example` and `_tests` of the same feature to depend on `_implementation` and `_testing` (Tuist microfeature standard)

### 🔧 Changed

- **`strictMode` behavior change**: Architecture violations are always detected and reported even when `strictMode: false`. `strictMode` only controls whether to abort on violations
  - `true` (default): Abort generate/check when violations are found (exit 1)
  - `false`: Print violations and continue (intended for migration transition period)

### 📝 Documentation

- README: Added notes on SDK dependencies and Flutter build configuration
- README: Documented directory structure per module type
- README: Documented init workflow for new and existing projects

---

## [2.0.0] - 2026-03-30

### 🚀 Breaking Changes

- **Module Type Renaming**:
  - `feature` → `clean` (Clean Architecture: Domain / Data / Presentation)
  - `library` → `micro` (Microfeature Architecture: Example / Interface / Impl / Tests / Testing)
  - `standard` → `lite` (Microfeature lite: Interface / Impl / Tests / Testing)
  - `simple` remains unchanged
- **Lite module now has 4 layers** (was 3):
  - Added Interface layer for dependency inversion
  - New structure: Interface / Implementation / Tests / Testing

### ✨ New Features

- **`flutist check` command**: Validates architecture rules for module dependencies
  - Implementation direct reference detection (with compositionRoots exception)
  - Circular dependency detection
  - Testing/Example layer reference restrictions
  - Clean module layer direction enforcement
- **`ProjectOptions` configuration**:
  - `strictMode` (default: `true`): Enforces architecture rules during `flutist generate`
  - `compositionRoots` (default: `['app']`): Modules allowed to reference Implementation directly
- **Architecture validation in `flutist generate`**:
  - When `strictMode: true`, generation aborts if violations are found
  - When `strictMode: false`, generation proceeds without validation

- **`flutist test` command**: Run tests across all modules in parallel
  - Automatically finds modules with `test/` directories
  - `--module <name>` option to test a specific module
  - Aggregated pass/fail summary with exit code 1 on failure

### 🔧 Refactored

- Removed unused `template.dart` (Template, Attribute, TemplateItem classes)
- Added `ModuleType.fromString()` to replace 3 duplicate `_parseModuleType` methods
- Added `StringCase` utility class for shared case conversions
- Extracted `ProjectParser` from `GenerateCommand` for shared parsing
- Merged `checker/`, `generator/`, `parser/` into unified `engine/` directory
- Reused `GenFileGenerator.parsePackageDart()` across commands

### 🧪 Tests

- Added unit test suite (61 tests):
  - `StringCase` case conversion + round-trip verification
  - `ModuleType.fromString()` validation + old name rejection
  - `ArchitectureChecker` all 5 rules + edge cases
  - `ProjectParser` file I/O + options parsing
  - `GenFileGenerator` package.dart parsing + round-trip verification

### 📦 Migration Guide

Update all references to old module type names:

```dart
// Before (1.x)
Module(name: 'login', type: ModuleType.feature)
Module(name: 'network', type: ModuleType.library)
Module(name: 'models', type: ModuleType.standard)

// After (2.0.0)
Module(name: 'login', type: ModuleType.clean)
Module(name: 'network', type: ModuleType.micro)
Module(name: 'models', type: ModuleType.lite)
```

Update CLI commands:

```bash
# Before
flutist create --options feature

# After
flutist create --options clean
```

## [1.1.3] - 2025-01-02

### 📝 Documentation
- Simplified README.md to core content (removed detailed documentation for future docs site)
- Added Docs badge with book icon linking to DeepWiki documentation
- Updated all documentation links to https://deepwiki.com/seonwooke/flutist
- Updated pubspec.yaml documentation field to point to DeepWiki

## [1.1.2] - 2025-01-02

### 📝 Documentation
- Updated README.md version badge to reflect current version (1.1.1)
- Fixed project structure documentation:
  - Corrected `main.dart` location to `root/lib/main.dart` (was incorrectly shown in `app/lib/main.dart`)
  - Clarified that `app.dart` belongs in `app/lib/app.dart`
- Removed `dart test` section from Development Setup (tests not yet implemented)
- Fixed duplicate `lib/` directory in project structure example

## [1.1.1] - 2025-01-02

### ✨ Added
- **Clean Architecture example repository**:
  - Added link to `flutist_clean_architecture` repository in README.md Examples section
  - Added Real-World Examples section to example/README.md
  - Showcases Clean Architecture implementation using Flutist

### 🔧 Improved
- **`flutist generate` command**:
  - Automatically removes deleted modules from `package.dart` when module files are not found
  - When a module's pubspec.yaml cannot be found (e.g., `home_domain`), extracts base module name (e.g., `home`) and removes it from `package.dart`
  - Ensures `package.dart` stays in sync with actual file system structure
  - Filters `flutist_gen.dart` modules to only include those present in `project.dart`
  - Modules removed from `project.dart` are now also removed from `flutist_gen.dart`

### 🐛 Fixed
- Fixed logging message format in generate command

## [1.1.0] - 2025-01-02

### 🚀 Major Changes
- **Project structure update**: Moved `main.dart` from `app/lib/main.dart` to `lib/main.dart`
  - Root `lib/main.dart` now imports and runs app from `package:app/app.dart`
  - App module is automatically added as a path dependency in root `pubspec.yaml`
  - Enables direct execution with `flutter run` from root directory
  - Removed `flutist run` command - use `flutter run` directly instead

### ✨ Added
- Root `lib/main.dart` generation in `flutist init` command
- Automatic app module dependency management in root `pubspec.yaml`

### 🗑️ Removed
- **BREAKING**: `flutist run` command has been removed
  - Users should use `flutter run` directly from the project root
  - This change simplifies the toolchain and aligns with standard Flutter workflows

### 🔧 Changed
- `flutist init` now creates `lib/main.dart` in root directory instead of `app/lib/main.dart`
- Root `pubspec.yaml` template now includes app module as path dependency
- Run command references removed from documentation and help text

## [1.0.10] - 2025-01-02

### 🐛 Fixed
- **`flutist generate` command**:
  - Fixed empty dependencies section being converted from `dependencies:` to `dependencies: {}`
  - Now preserves original format when dependencies section is empty
  - Empty dependencies sections are formatted as `dependencies:` instead of `dependencies: {}`
  - Files with unchanged dependencies no longer show unnecessary format changes

## [1.0.9] - 2025-01-02

### 🐛 Fixed
- **`flutist create` command**:
  - Fixed incorrect `analysis_options.yaml` include path for layered modules (feature, library, standard)
  - Now uses `path.relative()` to correctly calculate relative path from module to root directory
  - Previously calculated depth based on `moduleRelativePath`, which was incorrect for layered modules
  - Example: `features/book_detail/book_detail_domain` now correctly uses `../../../analysis_options.yaml` instead of `../../analysis_options.yaml`

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