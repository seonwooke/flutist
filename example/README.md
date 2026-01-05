# Flutist Example

This example demonstrates a Flutter project structure using Flutist with Microfeature Architecture.

## 📁 Directory Structure

See [directory_structure.md](./directory_structure.md) for a detailed visualization of the project structure.

## 📋 Configuration Files

### `package.dart`
Centralized dependency management. All dependencies and modules are defined here.

### `project.dart`
Project configuration that defines all modules and their relationships.

### `pubspec.yaml`
Root workspace configuration that includes all modules.

## 🚀 Getting Started

1. **Initialize a new Flutist project:**
   ```bash
   flutist init
   ```

2. **Create modules:**
   ```bash
   # Create a feature module
   flutist create --path features --name authentication --options feature
   
   # Create a library module
   flutist create --path lib --name network --options library
   
   # Create a standard module
   flutist create --path core --name models --options standard
   
   # Create a simple module
   flutist create --path core --name utils --options simple
   ```

3. **Configure dependencies in `package.dart`:**
   ```dart
   final package = Package(
     name: 'my_project',
     dependencies: [
       Dependency(name: 'http', version: '^1.1.0'),
       Dependency(name: 'provider', version: '^6.1.1'),
     ],
     modules: [
       Module(name: 'authentication', type: ModuleType.feature),
       Module(name: 'network', type: ModuleType.library),
     ],
   );
   ```

4. **Configure modules in `project.dart`:**
   ```dart
   final project = Project(
     name: 'my_project',
     modules: [
       Module(
         name: 'app',
         type: ModuleType.simple,
         dependencies: [
           package.dependencies.provider,
         ],
         modules: [
           package.modules.authentication,
         ],
       ),
       Module(
         name: 'authentication',
         type: ModuleType.feature,
         dependencies: [
           package.dependencies.http,
         ],
         modules: [
           package.modules.network,
         ],
       ),
     ],
   );
   ```

5. **Generate and sync:**
   ```bash
   flutist generate
   ```

## 📚 Module Types

### Feature Module
3-layer architecture: Domain, Data, Presentation
- Use for user-facing features with complex business logic

### Library Module
5-layer architecture: Example, Interface, Implementation, Testing, Tests
- Use for reusable libraries and shared utilities

### Standard Module
3-layer architecture: Implementation, Tests, Testing
- Use for domain models and shared business logic

### Simple Module
Single layer: lib/
- Use for simple utilities and the main app module

## 🔗 Module Dependencies

Modules can depend on:
- External packages (defined in `package.dart`)
- Other modules (defined in `package.dart`)

See the example files for detailed configuration.

## 📚 Real-World Examples

### Clean Architecture Example

For a complete real-world example demonstrating Clean Architecture with Flutist, check out:

🔗 **[flutist_clean_architecture](https://github.com/seonwooke/flutist_clean_architecture)**

This repository provides a production-ready example of:
- Clean Architecture patterns
- Feature module organization
- Dependency management
- Best practices for Flutter projects using Flutist

