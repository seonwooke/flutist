import 'package:flutist/flutist.dart';

/// Centralized dependency management for the project.
/// 
/// All dependencies and modules are defined here and can be referenced
/// by individual modules in project.dart using type-safe accessors.
/// 
/// Example usage in project.dart:
/// ```dart
/// Module(
///   name: 'app',
///   dependencies: [
///     package.dependencies.http,
///     package.dependencies.provider,
///   ],
///   modules: [
///     package.modules.authentication,
///   ],
/// )
/// ```
final package = Package(
  name: 'my_flutter_project',
  
  /// External dependencies available for all modules.
  /// 
  /// After adding dependencies here, run `flutist generate` to sync
  /// them to module pubspec.yaml files.
  dependencies: [
    // HTTP client for API calls
    Dependency(name: 'http', version: '^1.1.0'),
    
    // State management
    Dependency(name: 'provider', version: '^6.1.1'),
    
    // Local storage
    Dependency(name: 'shared_preferences', version: '^2.2.2'),
    
    // JSON serialization
    Dependency(name: 'json_annotation', version: '^4.8.1'),
    
    // Testing
    Dependency(name: 'test', version: '^1.24.0'),
    Dependency(name: 'mockito', version: '^5.4.4'),
  ],
  
  /// Module definitions that can be referenced by other modules.
  /// 
  /// These modules are defined here and can be used as dependencies
  /// in project.dart to establish module relationships.
  modules: [
    // Feature modules
    Module(name: 'authentication', type: ModuleType.feature),
    Module(name: 'profile', type: ModuleType.feature),
    
    // Library modules
    Module(name: 'network', type: ModuleType.library),
    Module(name: 'storage', type: ModuleType.library),
    
    // Standard modules
    Module(name: 'models', type: ModuleType.standard),
    Module(name: 'constants', type: ModuleType.standard),
    
    // Simple modules
    Module(name: 'utils', type: ModuleType.simple),
    Module(name: 'extensions', type: ModuleType.simple),
  ],
);

