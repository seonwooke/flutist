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
    
    // Authentication feature module
    Module(
      name: 'authentication',
      type: ModuleType.feature,
      dependencies: [
        // HTTP client for API calls
        package.dependencies.http,
        // Local storage for tokens
        package.dependencies.shared_preferences,
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
    
    // Profile feature module
    Module(
      name: 'profile',
      type: ModuleType.feature,
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
    
    // Network library module
    Module(
      name: 'network',
      type: ModuleType.library,
      dependencies: [
        package.dependencies.http,
        package.dependencies.json_annotation,
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
    
    // Storage library module
    Module(
      name: 'storage',
      type: ModuleType.library,
      dependencies: [
        package.dependencies.shared_preferences,
      ],
      devDependencies: [
        package.dependencies.test,
      ],
      modules: [],
    ),
    
    // Models standard module
    Module(
      name: 'models',
      type: ModuleType.standard,
      dependencies: [
        package.dependencies.json_annotation,
      ],
      devDependencies: [
        package.dependencies.test,
      ],
      modules: [
        package.modules.utils,
      ],
    ),
    
    // Constants standard module
    Module(
      name: 'constants',
      type: ModuleType.standard,
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

