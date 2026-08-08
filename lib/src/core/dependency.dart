/// The source a [Dependency] resolves from.
enum DependencyKind {
  /// A package published on pub.dev, pinned by a version constraint.
  hosted,

  /// A package on the local filesystem, referenced by path.
  path,

  /// A package in a Git repository.
  git,
}

/// Represents a dependency in a Flutist project.
///
/// A dependency resolves from one of three sources:
///
/// ```dart
/// Dependency(name: 'http', version: '^1.1.0');
/// Dependency.path(name: 'design_system', path: 'shared/design_system');
/// Dependency.git(
///   name: 'analytics',
///   url: 'https://github.com/acme/analytics.git',
///   ref: 'main',
/// );
/// ```
///
/// Only one of [version], [path], or [gitUrl] is set; [kind] reports which.
class Dependency {
  /// Dependency name.
  final String name;

  /// Version constraint (e.g., '^1.0.0', 'any').
  /// Only set for [DependencyKind.hosted].
  final String? version;

  /// Package location on the local filesystem, relative to the project root
  /// (the directory holding `package.dart`).
  ///
  /// Flutist rewrites this into a path relative to each consuming module when
  /// generating that module's `pubspec.yaml`, so the same declaration works
  /// from every module regardless of how deeply it is nested.
  ///
  /// Only set for [DependencyKind.path].
  final String? path;

  /// Git repository URL. Only set for [DependencyKind.git].
  final String? gitUrl;

  /// Git ref (branch, tag, or commit). Only set for [DependencyKind.git].
  final String? gitRef;

  /// Package location inside the Git repository, for repositories that hold
  /// more than one package. Only set for [DependencyKind.git].
  final String? gitPath;

  const Dependency._({
    required this.name,
    this.version,
    this.path,
    this.gitUrl,
    this.gitRef,
    this.gitPath,
  });

  /// A package published on pub.dev.
  const Dependency({
    required String name,
    required String version,
  }) : this._(name: name, version: version);

  /// A package on the local filesystem.
  ///
  /// [path] is relative to the project root, not to the module that uses it.
  const Dependency.path({
    required String name,
    required String path,
  }) : this._(name: name, path: path);

  /// A package in a Git repository.
  ///
  /// [ref] pins a branch, tag, or commit. [path] points at a package nested
  /// inside the repository.
  const Dependency.git({
    required String name,
    required String url,
    String? ref,
    String? path,
  }) : this._(name: name, gitUrl: url, gitRef: ref, gitPath: path);

  /// The source this dependency resolves from.
  DependencyKind get kind {
    if (gitUrl != null) return DependencyKind.git;
    if (path != null) return DependencyKind.path;
    return DependencyKind.hosted;
  }
}
