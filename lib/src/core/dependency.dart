/// Represents a dependency in a Flutist project.
/// Can be either a pub.dev package or an internal module.
class Dependency {
  /// Dependency name.
  final String name;

  /// Version constraint (e.g., '^1.0.0', 'any').
  final String version;

  Dependency({
    required this.name,
    required this.version,
  });
}
