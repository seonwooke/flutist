<div align="center">

<img src="https://raw.githubusercontent.com/seonwooke/flutist/release/1.0.0/assets/flutist_banner.png" alt="Flutist Banner">

**A Flutter project management framework inspired by Tuist**

[![Docs](https://img.shields.io/badge/Docs-blue.svg?logo=book&logoColor=white)](https://deepwiki.com/seonwooke/flutist)
[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](pubspec.yaml)
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

Flutist will ask whether this is a **new project** or an **existing project migration**:

- **New project**: Creates `app` module, adds it to workspace, scaffolds `lib/main.dart`
- **Existing project**: Only creates configuration files (`project.dart`, `package.dart`) and workspace setup — preserves your existing code, `analysis_options.yaml`, and `lib/main.dart`

### 2. Create a Module

```bash
# Create a clean module (Clean Architecture)
flutist create --path features --name login --options clean

# Create a micro module (Microfeature Architecture)
flutist create --path lib --name network --options micro

# Create a simple module
flutist create --path core --name utils --options simple
```

### 3. Manage Dependencies

```bash
# Add a dependency
flutist pub add http

# Sync dependencies to all modules
flutist generate
```

### 4. Generate Code from Templates

```bash
# List available templates
flutist scaffold list

# Generate code from a template
flutist scaffold feature --name login
```

## 📋 Commands

| Command | Description | Usage |
|---------|-------------|-------|
| **`init`** | Initialize a new or existing project | `flutist init` |
| **`create`** | Create a new module | `flutist create --path <path> --name <name> --options <type>` |
| **`generate`** | Sync dependencies and regenerate files | `flutist generate` |
| **`check`** | Check architecture rules | `flutist check` |
| **`test`** | Run tests for all modules in parallel | `flutist test` |
| **`scaffold`** | Generate code from templates | `flutist scaffold <template> --name <name>` |
| **`pub`** | Manage dependencies | `flutist pub add <package>` |
| **`graph`** | Visualize module dependencies | `flutist graph [--format <format>]` |
| **`help`** | Show help information | `flutist help [command]` |

> **Note:** `flutist generate` manages dependencies declared in `package.dart` and `project.dart`. SDK dependencies (`flutter_localizations`, etc.) and Flutter-specific settings (`flutter: generate: true`) should be added directly to each module's `pubspec.yaml` — they are preserved during generation.

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

## 🧩 Module Types

Flutist supports 4 module types, each generating a different directory structure:

### Clean (`--options clean`)

Clean Architecture with 3 layers. Best for feature modules with clear separation of concerns.

```
flutist create --path features --name login --options clean

features/login/
├── login_domain/          # Business logic, entities, use cases
│   ├── lib/
│   │   └── login_domain.dart
│   └── pubspec.yaml
├── login_data/            # Repositories, data sources, DTOs
│   ├── lib/
│   │   └── login_data.dart
│   └── pubspec.yaml
└── login_presentation/    # UI, BLoC/Cubit, pages
    ├── lib/
    │   └── login_presentation.dart
    └── pubspec.yaml
```

### Micro (`--options micro`)

Microfeature Architecture with 5 layers. Best for reusable libraries shared across features.

```
flutist create --path packages --name network --options micro

packages/network/
├── network_example/           # Demo app for the module
│   ├── lib/
│   │   ├── network_example.dart
│   │   └── main.dart
│   └── pubspec.yaml
├── network_interface/         # Public API (abstract classes, models)
│   ├── lib/
│   │   └── network_interface.dart
│   └── pubspec.yaml
├── network_implementation/    # Concrete implementations
│   ├── lib/
│   │   └── network_implementation.dart
│   └── pubspec.yaml
├── network_tests/             # Integration/unit tests
│   ├── lib/
│   │   └── network_tests.dart
│   └── pubspec.yaml
└── network_testing/           # Test helpers, mocks, fakes
    ├── lib/
    │   └── network_testing.dart
    └── pubspec.yaml
```

### Lite (`--options lite`)

Microfeature lite with 4 layers (no example). Best for internal APIs that don't need a demo app.

```
flutist create --path packages --name auth --options lite

packages/auth/
├── auth_interface/
├── auth_implementation/
├── auth_tests/
└── auth_testing/
```

### Simple (`--options simple`)

Single module with no layers. Best for utilities, shared models, or the app module itself.

```
flutist create --path packages --name core --options simple

packages/core/
├── lib/
│   └── core.dart
└── pubspec.yaml
```

## ✨ Features

- **🏗️ Modular Architecture**: Organize your codebase into clear, reusable modules
- **📦 Centralized Dependencies**: Manage all dependencies in one place
- **🚀 Fast Development**: Generate boilerplate code with scaffold templates
- **🔗 Dependency Visualization**: Visualize module dependencies with graphs
- **⚡ Workspace Support**: Leverage Flutter's native workspace feature
- **🎨 Code Generation**: Create custom templates for rapid development

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
