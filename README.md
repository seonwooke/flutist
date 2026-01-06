<div align="center">

<img src="https://raw.githubusercontent.com/seonwooke/flutist/release/1.0.0/assets/flutist_banner.png" alt="Flutist Banner">

**A Flutter project management framework inspired by Tuist**

[![Version](https://img.shields.io/badge/version-1.1.2-blue.svg)](pubspec.yaml)
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

### 1. Initialize a New Project

```bash
cd my_flutter_project
flutist init
```

### 2. Create a Module

```bash
# Create a feature module
flutist create --path features --name login --options feature

# Create a simple module
flutist create --path lib --name utils --options simple
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
| **`init`** | Initialize a new Flutist project | `flutist init` |
| **`create`** | Create a new module | `flutist create --path <path> --name <name> --options <type>` |
| **`generate`** | Sync dependencies and regenerate files | `flutist generate` |
| **`scaffold`** | Generate code from templates | `flutist scaffold <template> --name <name>` |
| **`pub`** | Manage dependencies | `flutist pub add <package>` |
| **`graph`** | Visualize module dependencies | `flutist graph [--format <format>]` |
| **`help`** | Show help information | `flutist help [command]` |

For detailed documentation, visit the [documentation site](#) (coming soon).

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

For development setup and guidelines, see the [documentation site](#) (coming soon).

## 📄 License

This project is licensed under the MIT License.

## 🔗 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Tuist (Inspiration)](https://tuist.io)

---

**Built with ❤️ for the Flutter community**
