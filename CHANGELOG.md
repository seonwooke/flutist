# Changelog

All notable changes to Flutist will be documented in this file.

## [2.1.0] - 2026-04-07

### ✨ New Features

- **`flutist init`: 신규/기존 프로젝트 선택**
  - 초기화 시 새 프로젝트 / 기존 프로젝트 마이그레이션을 선택할 수 있음
  - 기존 프로젝트: app 모듈 생성 스킵, workspace app 항목 스킵, 빈 project.dart/package.dart 생성
- **`flutist pub add`: 다중 패키지 지원**
  - `flutist pub add http dio` 형태로 한 번에 여러 패키지 추가 가능
- **기존 프로젝트용 템플릿 사용 가이드 주석**
  - `project.dart`, `package.dart`에 워크플로우 3단계 주석 및 예시 추가

### 🐛 Fixed

- **`flutist create`**: simple 모듈 경로에 모듈 이름 누락 수정 (`packages/` → `packages/core`)
- **`flutist create`**: 레이어 모듈명 suffix 중복 입력 시 경고 및 종료
- **`flutist create`**: path 마지막 세그먼트가 name과 같을 때 중첩 경고 및 종료
- **`flutist create`**: 모듈 생성 시 barrel file(`lib/module_name.dart`) 자동 생성
- **`flutist generate`**: cross-path 모듈 의존성 해석 — 하드코딩된 basePaths 제거, workspace 스캔으로 동적 해석
- **`flutist generate`**: `flutter`, `flutter_localizations` 등 모든 SDK 의존성 보존 (기존에는 `flutter`만 보존)
- **`flutist init`**: `lib/main.dart` 이미 존재하면 덮어쓰지 않음
- **`flutist init`**: `analysis_options.yaml` 이미 존재하면 덮어쓰지 않음
- **`flutist init`**: workspace 항목이 block style로 추가됨 (`- path/to/module`)
- **`flutist pub add`**: 반복 실행 시 `],`가 같은 줄에 붙는 포맷 깨짐 수정
- **`flutist pub add`**: `Generated flutist_gen.dart` 메시지 중복 출력 수정
- **`flutist scaffold`**: `--path` 옵션이 문서에만 존재하고 실제 동작하지 않던 버그 수정
- **`flutist test`**: 실패 시 키워드 필터링 없이 전체 stdout/stderr 출력
- **아키텍처 체커**: 같은 피처의 `_example`, `_tests`가 `_implementation`, `_testing`에 의존하는 것을 허용 (Tuist microfeature 표준)

### 🔧 Changed

- **`strictMode` 동작 변경**: `strictMode: false`여도 아키텍처 위반을 항상 감지하고 출력함. `strictMode`는 위반 시 중단 여부만 제어
  - `true` (기본): 위반 발견 시 generate/check 중단 (exit 1)
  - `false`: 위반 출력 후 계속 진행 (마이그레이션 과도기용)

### 📝 Documentation

- README: SDK 의존성 및 Flutter 빌드 설정 관련 주의사항 추가
- README: 모듈 타입별 디렉토리 구조 문서화
- README: init 워크플로우 (신규/기존 프로젝트) 문서화

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