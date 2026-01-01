import 'core.dart';

/// Root configuration of a Flutist project.
/// Top-level structure that defines the entire project with its modules and settings.
class Project {
  /// Project name (typically matches root project directory name).
  final String name;

  /// Project configuration options.
  final ProjectOptions options;

  /// List of modules in this project.
  final List<Module> modules;

  Project({
    required this.name,
    this.options = const ProjectOptions(),
    this.modules = const [],
  });
}
