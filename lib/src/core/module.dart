import 'core.dart';

/// Defines the structural type of a module in a Flutist project.
enum ModuleType {
  /// Feature module with Domain, Data, Presentation 3-layer structure.
  feature,

  /// Library module with Example, Implementation, Interface, Tests, Testing 5-layer structure.
  library,

  /// Standard module with Implementation, Tests, Testing 3-layer structure.
  standard,

  /// Simple module with only lib folder.
  simple,

  /// Custom module with custom template.
  custom,
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
    this.type = ModuleType.library,
    this.dependencies = const [],
    this.devDependencies = const [],
    this.modules = const [],
  });
}
