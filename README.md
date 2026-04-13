<div align="center">

<img src="https://raw.githubusercontent.com/seonwooke/flutist/main/assets/flutist_banner.png" alt="Flutist Banner">

**A Flutter project management framework inspired by Tuist**

[![Docs](https://img.shields.io/badge/Docs-blue.svg?logo=book&logoColor=white)](https://deepwiki.com/seonwooke/flutist)
[![pub.dev](https://img.shields.io/pub/v/flutist.svg)](https://pub.dev/packages/flutist)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.5.0%20%3C4.0.0-blue.svg)](https://dart.dev)

</div>

## 🎯 About

Flutist is a powerful project management framework for Flutter applications, inspired by [Tuist](https://tuist.io) for iOS development. It provides a structured approach to managing large-scale Flutter projects with modular architecture, centralized dependency management, and code generation capabilities.

## 📦 Installation

```bash
dart pub global activate flutist
```

**Prerequisites:** Dart SDK (>=3.5.0 <4.0.0)

## 🚀 Quick Start

### 1. Initialize a Project

```bash
cd my_flutter_project
flutist init
```

Flutist adapts based on context:

- **No `pubspec.yaml`**: Asks if you want to create a new Flutter project. If yes, runs `flutter create .` and sets up as a new project automatically. If no, exits with guidance.
- **`pubspec.yaml` exists**: Asks whether this is a **new project** or an **existing project migration**.
  - **New project**: Creates `app` module, adds it to workspace, scaffolds `lib/main.dart`
  - **Existing project**: Only creates configuration files (`project.dart`, `package.dart`) and workspace setup — preserves your existing code, `analysis_options.yaml`, and `lib/main.dart`

### 2. Create a Module

```bash
# Create a clean module (Clean Architecture)
flutist create --name login --path features --options clean

# Create a micro module (Microfeature Architecture)
flutist create --name network --path packages --options micro

# Create a lite module (Microfeature lite)
flutist create --name auth --path packages --options lite

# Create a single package (omit --options)
flutist create --name utils --path core
```

Layer packages and their dependencies are **automatically wired** in `project.dart` when you run `flutist create`.

### 3. Manage Dependencies

```bash
# Add a single dependency
flutist pub add http

# Add multiple dependencies at once
flutist pub add http dio riverpod

# Sync dependencies to all modules
flutist generate
```

### 4. Generate Code from Custom Templates

```bash
# List available templates
flutist scaffold list

# Generate from a template
flutist scaffold feature --name login
flutist scaffold feature --name login --path lib/features
```

Templates live in `flutist/templates/`. Define your own templates to match your project conventions — just like Tuist.

## 📋 Commands

| Command | Description | Usage |
|---------|-------------|-------|
| **`init`** | Initialize a new or existing project | `flutist init` |
| **`create`** | Create a new module | `flutist create --name <name> --path <path> [--options <type>]` |
| **`generate`** | Sync dependencies and regenerate files | `flutist generate` |
| **`check`** | Check architecture rules | `flutist check` |
| **`test`** | Run tests for all modules in parallel (auto-selects `flutter test` or `dart test`) | `flutist test [-m <module>]` |
| **`scaffold`** | Generate code from templates | `flutist scaffold <template> --name <name>` |
| **`pub`** | Manage dependencies | `flutist pub add <package>` |
| **`graph`** | Visualize module dependencies | `flutist graph [--format <format>]` |
| **`help`** | Show help information | `flutist help [command]` |

> **Note:** `flutist generate` manages dependencies declared in `package.dart` and `project.dart`. SDK dependencies (`flutter_localizations`, etc.) and Flutter-specific settings (`flutter: generate: true`, `flutter: uses-material-design: true`) should be added directly to each module's `pubspec.yaml` — they are preserved during generation.

For detailed documentation, visit the [documentation site](https://deepwiki.com/seonwooke/flutist).

## 📁 Project Structure

A typical Flutist project structure:

```
my_project/
├── project.dart              # Project configuration
├── package.dart              # Centralized dependencies
├── pubspec.yaml              # Workspace configuration
├── lib/                      # Root application code
│   └── main.dart
├── app/                      # Main application module
│   ├── lib/
│   │   └── app.dart
│   └── pubspec.yaml
├── features/                 # Feature modules
│   └── login/
│       ├── login_domain/
│       ├── login_data/
│       └── login_presentation/
└── flutist/
    ├── templates/            # Scaffold templates
    └── flutist_gen.dart      # Generated code
```

## 🧩 Scaffold Types

`flutist create` generates layer packages and **automatically wires their dependencies** in `project.dart`.

### Clean (`--options clean`)

3-layer Clean Architecture. Best for feature modules with clear separation of concerns.

```
flutist create --name login --path features --options clean

features/login/
├── login_domain/          # Business logic, entities, use cases
├── login_data/            # Repositories, data sources, DTOs
└── login_presentation/    # UI and state management
```

**Auto-wired:** `presentation → data → domain`

### Micro (`--options micro`)

5-layer Microfeature Architecture. Best for reusable libraries shared across features.

```
flutist create --name network --path packages --options micro

packages/network/
├── network_interface/         # Public API (abstract classes, models)
├── network_implementation/    # Concrete implementations
├── network_testing/           # Test helpers, mocks, fakes
├── network_tests/             # Unit and integration tests
└── network_example/           # Demo app for the module
```

**Auto-wired:** `implementation/testing → interface`, `tests/example → implementation + testing`

### Lite (`--options lite`)

4-layer Microfeature lite (no example). Best for internal APIs.

```
flutist create --name auth --path packages --options lite

packages/auth/
├── auth_interface/
├── auth_implementation/
├── auth_testing/
└── auth_tests/
```

**Auto-wired:** `implementation/testing → interface`, `tests → implementation + testing`

### Single package (omit `--options`)

No layers. Best for utilities, shared models, or the app shell. This is the default when `--options` is omitted.

```
flutist create --name utils --path core

core/utils/
├── lib/
│   └── utils.dart
└── pubspec.yaml
```

## ✨ Features

- **🏗️ Modular Architecture**: Organize your codebase into clear, reusable modules
- **📦 Centralized Dependencies**: Manage all dependencies in one place
- **🚀 Fast Development**: Generate boilerplate code with scaffold templates
- **🔗 Dependency Visualization**: Visualize module dependencies with graphs
- **⚡ Workspace Support**: Leverage Flutter's native workspace feature
- **🎨 Code Generation**: Create custom templates for rapid development

## 🎨 Scaffold Templates

Scaffold lets you define reusable code generation templates for your project — like Tuist scaffold.

`flutist init` creates a starter template at `flutist/templates/feature/`. From there, **you own the templates** — edit them freely to match your project conventions.

```
flutist/templates/
└── feature/                    # Template name (used in CLI)
    ├── template.yaml           # Declares attributes and what files to generate
    └── widget.dart.template    # Template file — use {{variables}} for substitution
```

### template.yaml

```yaml
description: "My custom template"

# ── Attributes ────────────────────────────────────────────────────────────────
# Variables passed from the CLI (e.g. --name login --path lib/features).
# required: true  → must be provided via CLI, or an error is shown
# required: false → optional; uses `default` if not provided via CLI
attributes:
  - name: name
    required: true
  - name: path
    required: false
    default: "lib/features"
  - name: withTest           # custom attribute: pass with --withTest true
    required: false
    default: "false"

# ── Items ─────────────────────────────────────────────────────────────────────
# Files to generate. Supports two types:
#
#   type: file   — reads a .template file, applies variable substitution
#   type: string — writes inline content directly (no .template file needed)
#
# if: "key == 'value'" — skip this item unless the condition is true
items:
  - type: file
    path: "{{path}}/{{name | snake_case}}_page.dart"
    templatePath: "page.dart.template"

  - type: string
    path: "{{path}}/{{name | snake_case}}/README.md"
    contents: |
      # {{name | pascal_case}}
      Auto-generated page.

  - type: file
    path: "{{path}}/{{name | snake_case}}_test.dart"
    templatePath: "test.dart.template"
    if: "withTest == 'true'"            # only generated when --withTest true
```

The `if:` field supports `==`, `!=`, `&&`, and `||`:

```yaml
if: "withTest == 'true'"                        # equality
if: "withTest != 'false'"                       # inequality
if: "withTest == 'true' && withMock == 'true'"  # AND
if: "style == 'bloc' || style == 'cubit'"       # OR
```

### Template variables

Use `{{variables}}` inside `.template` files and in `path` values:

| Syntax | Input `user profile` → Output |
|--------|-------------------------------|
| `{{name}}` | `user_profile` |
| `{{name \| pascal_case}}` | `UserProfile` |
| `{{name \| camel_case}}` | `userProfile` |
| `{{name \| upper_case}}` | `USER_PROFILE` |
| `{{path}}` | value of the `path` attribute |
| `{{withTest}}` | value of any custom attribute |

### Example `.template` file

```dart
// page.dart.template
import 'package:flutter/material.dart';

class {{name | pascal_case}}Page extends StatelessWidget {
  const {{name | pascal_case}}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
```

### Running scaffold

```bash
# Basic usage (uses default path from template.yaml)
flutist scaffold feature --name login

# Override path
flutist scaffold feature --name login --path lib/features

# Custom attribute defined in your template.yaml
flutist scaffold page --name home --withTest true
```

Custom attributes defined in `template.yaml` are automatically available as `--<attribute>` CLI flags. The default `feature` template has `name` and `path` — add your own attributes to match your conventions.

## 📚 Examples

### Real-World Example Projects

#### Clean Architecture Example

A complete Flutter project demonstrating Clean Architecture principles using Flutist:

🔗 **[flutist_clean_architecture](https://github.com/seonwooke/flutist_clean_architecture)**

This repository showcases:
- Clean Architecture implementation with Flutist
- Feature modules with Domain, Data, and Presentation layers
- Centralized dependency management
- Modular project structure
- Best practices for large-scale Flutter applications

#### Microfeature Architecture Example

A complete Flutter project demonstrating Microfeature Architecture principles using Flutist:

🔗 **[flutist_microfeature_architecture](https://github.com/seonwooke/flutist_microfeature_architecture)**

This repository showcases:
- Microfeature Architecture implementation with Flutist
- Reusable library modules with Interface, Implementation, Tests, and Testing layers
- Centralized dependency management
- Modular project structure

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

For development setup and guidelines, see the [documentation site](https://deepwiki.com/seonwooke/flutist).

## 📄 License

This project is licensed under the MIT License.

## 🔗 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Tuist (Inspiration)](https://tuist.io)

---

**Built with ❤️ for the Flutter community**
