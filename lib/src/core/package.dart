import 'core.dart';

/// Central package configuration in a Flutist project.
/// Defines all available dependencies and modules that can be referenced by individual modules.
/// Typically defined in 'package.dart' for centralized dependency management.
class Package {
  /// Package name (typically matches workspace or project name).
  final String name;

  /// Regular dependencies available for modules to use.
  final List<Dependency> dependencies;

  /// All modules defined in this package.
  final List<Module> modules;

  Package({
    required this.name,
    this.dependencies = const [],
    this.modules = const [],
  });
}
