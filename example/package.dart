import 'package:flutist/flutist.dart';

/// Centralized dependency management for the project.
///
/// Add dependencies here and reference them in project.dart via
/// package.dependencies.<name> and package.modules.<name>.
///
/// After modifying, run `flutist generate` to sync pubspec.yaml files.
final package = Package(
  name: 'my_flutter_project',

  dependencies: [
    // Network
    Dependency(name: 'http', version: '^1.1.0'),

    // Testing
    Dependency(name: 'test', version: '^1.24.0'),
    Dependency(name: 'mockito', version: '^5.4.4'),
  ],

  /// All modules in the workspace.
  /// Layer packages are declared individually (no type: field in 3.0.0).
  modules: [
    // App shell
    Module(name: 'app'),

    // auth — clean architecture (3 layers)
    Module(name: 'auth_domain'),
    Module(name: 'auth_data'),
    Module(name: 'auth_presentation'),

    // network — lite architecture (4 layers)
    Module(name: 'network_interface'),
    Module(name: 'network_implementation'),
    Module(name: 'network_testing'),
    Module(name: 'network_tests'),

    // Shared utilities
    Module(name: 'utils'),
  ],
);
