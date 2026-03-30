import 'core.dart';

/// Defines the structural type of a module in a Flutist project.
enum ModuleType {
  /// Clean Architecture module with Domain, Data, Presentation 3-layer structure.
  clean,

  /// Microfeature Architecture module with Example, Interface, Implementation, Tests, Testing 5-layer structure.
  micro,

  /// Microfeature lite module with Interface, Implementation, Tests, Testing 4-layer structure.
  lite,

  /// Simple module with only lib folder.
  simple,

  /// Custom module with custom template.
  custom;

  /// Parses a string to [ModuleType].
  static ModuleType fromString(String value) {
    switch (value) {
      case 'clean':
        return ModuleType.clean;
      case 'micro':
        return ModuleType.micro;
      case 'lite':
        return ModuleType.lite;
      case 'simple':
        return ModuleType.simple;
      case 'custom':
        return ModuleType.custom;
      default:
        throw ArgumentError('Invalid module type: $value');
    }
  }
}

/// Represents a module in a Flutist project.
class Module {
  /// Module name.
  final String name;

  /// Module type.
  final ModuleType type;

  /// Regular dependencies for 'dependencies' section.
  final List<Dependency> dependencies;

  /// Development dependencies for 'dev_dependencies' section.
  final List<Dependency> devDependencies;

  /// Sub-modules or module dependencies.
  final List<Module> modules;

  Module({
    required this.name,
    this.type = ModuleType.micro,
    this.dependencies = const [],
    this.devDependencies = const [],
    this.modules = const [],
  });
}
