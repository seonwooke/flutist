/// Configuration options for a Flutist project.
class ProjectOptions {
  /// Whether to enforce architecture rules during `flutist generate`.
  ///
  /// When `true` (default), `flutist generate` will abort if architecture
  /// violations are detected (e.g., direct implementation references).
  /// When `false`, generation proceeds without validation.
  final bool strictMode;

  /// Modules allowed to directly reference Implementation layers.
  ///
  /// Composition roots (e.g., app module with DI container) need to bind
  /// Interface to Implementation, so they must reference both.
  /// Defaults to `['app']`.
  final List<String> compositionRoots;

  const ProjectOptions({
    this.strictMode = true,
    this.compositionRoots = const ['app'],
  });
}
