// ignore_for_file: unused_import

import 'package:flutist/flutist.dart';

import 'flutist/flutist_gen.dart';
import 'package.dart';

/// Project configuration defining all modules and their relationships.
///
/// This file defines:
/// - Which modules are part of the project
/// - Dependencies between modules
/// - External package dependencies for each module
///
/// After modifying this file, run `flutist generate` to sync changes
/// to module pubspec.yaml files.
final project = Project(
  name: 'my_flutter_project',
  options: const ProjectOptions(),

  /// All modules in the project.
  ///
  /// Modules are organized hierarchically, with dependencies
  /// defined using package.dependencies and package.modules.
  modules: [
    // Main application module
    Module(
      name: 'app',
      type: ModuleType.simple,
      dependencies: [
        // State management
        package.dependencies.provider,
      ],
      devDependencies: [
        // Testing
        package.dependencies.test,
      ],
      modules: [
        // App depends on authentication feature
        package.modules.authentication,
        package.modules.profile,
      ],
    ),

    // Authentication clean module
    Module(
      name: 'authentication',
      type: ModuleType.clean,
      dependencies: [
        // HTTP client for API calls
        package.dependencies.http,
        // Local storage for tokens
        package.dependencies.sharedPreferences,
        // State management
        package.dependencies.provider,
      ],
      devDependencies: [
        package.dependencies.test,
        package.dependencies.mockito,
      ],
      modules: [
        // Authentication depends on network library
        package.modules.network,
        // And models for data structures
        package.modules.models,
      ],
    ),

    // Profile clean module
    Module(
      name: 'profile',
      type: ModuleType.clean,
      dependencies: [
        package.dependencies.http,
        package.dependencies.provider,
      ],
      devDependencies: [
        package.dependencies.test,
      ],
      modules: [
        package.modules.network,
        package.modules.models,
        package.modules.storage,
      ],
    ),

    // Network micro module
    Module(
      name: 'network',
      type: ModuleType.micro,
      dependencies: [
        package.dependencies.http,
        package.dependencies.jsonAnnotation,
      ],
      devDependencies: [
        package.dependencies.test,
        package.dependencies.mockito,
      ],
      modules: [
        // Network depends on utils for helpers
        package.modules.utils,
      ],
    ),

    // Storage micro module
    Module(
      name: 'storage',
      type: ModuleType.micro,
      dependencies: [
        package.dependencies.sharedPreferences,
      ],
      devDependencies: [
        package.dependencies.test,
      ],
      modules: [],
    ),

    // Models lite module
    Module(
      name: 'models',
      type: ModuleType.lite,
      dependencies: [
        package.dependencies.jsonAnnotation,
      ],
      devDependencies: [
        package.dependencies.test,
      ],
      modules: [
        package.modules.utils,
      ],
    ),

    // Constants lite module
    Module(
      name: 'constants',
      type: ModuleType.lite,
      dependencies: [],
      devDependencies: [],
      modules: [],
    ),

    // Utils simple module
    Module(
      name: 'utils',
      type: ModuleType.simple,
      dependencies: [],
      devDependencies: [],
      modules: [],
    ),

    // Extensions simple module
    Module(
      name: 'extensions',
      type: ModuleType.simple,
      dependencies: [],
      devDependencies: [],
      modules: [],
    ),
  ],
);
