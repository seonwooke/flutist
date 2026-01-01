/// Flutist - A declarative Flutter project management framework.
///
/// Flutist provides tools for managing Flutter projects with a declarative
/// approach, inspired by Tuist. It supports module creation, dependency
/// management, code generation, and visualization.
///
/// ## Features
///
/// - **Module Management**: Create and organize modules with predefined architectures
/// - **Type-Safe Dependencies**: Auto-completion for dependencies and modules
/// - **Code Scaffolding**: Generate code from customizable templates
/// - **Dependency Graphs**: Visualize module relationships
/// - **Workspace Support**: Built on Flutter's native workspace feature
///
/// ## Usage
///
/// ```bash
/// # Install Flutist
/// dart pub global activate flutist
///
/// # Initialize a new project
/// flutist init
///
/// # Create a module
/// flutist create --path features --name login --options library
///
/// # Sync dependencies
/// flutist generate
///
/// # Visualize dependencies
/// flutist graph --open
/// ```
///
/// For more information, visit: https://github.com/yourusername/flutist
library;

export 'src/commands/commands.dart';
export 'src/core/core.dart';
export 'src/parser/parser.dart';
export 'src/utils/utils.dart';
