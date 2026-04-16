import 'core.dart';

/// Defines the scaffold template type used when creating a module.
/// Used exclusively by `flutist create --options` and internal logic.
/// Not stored in project.dart or package.dart.
enum ScaffoldType {
  /// Clean Architecture: Domain / Data / Presentation (3 layers).
  clean,

  /// Microfeature Architecture: Example / Interface / Implementation / Tests / Testing (5 layers).
  micro,

  /// Microfeature lite: Interface / Implementation / Tests / Testing (4 layers).
  lite,

  /// Single package with no layers.
  simple,

  /// Custom template structure.
  custom;

  /// Parses a string to [ScaffoldType].
  static ScaffoldType fromString(String value) {
    switch (value) {
      case 'clean':
        return ScaffoldType.clean;
      case 'micro':
        return ScaffoldType.micro;
      case 'lite':
        return ScaffoldType.lite;
      case 'simple':
        return ScaffoldType.simple;
      case 'custom':
        return ScaffoldType.custom;
      default:
        throw ArgumentError('Invalid scaffold type: $value');
    }
  }
}

/// Represents a module in a Flutist project.
class Module {
  /// Module name.
  final String name;

  /// Regular dependencies for 'dependencies' section.
  final List<Dependency> dependencies;

  /// Development dependencies for 'dev_dependencies' section.
  final List<Dependency> devDependencies;

  /// Sub-modules or module dependencies.
  final List<Module> modules;

  Module({
    required this.name,
    this.dependencies = const [],
    this.devDependencies = const [],
    this.modules = const [],
  });
}
