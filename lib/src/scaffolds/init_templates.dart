/// Template generator for project initialization.
class InitTemplates {
  /// Generates root pubspec.yaml content.
  static String pubspecYaml(String projectName, String flutistVersion) => '''
name: $projectName
description: A new Flutter project managed by Flutist.
version: 1.0.0+1
publish_to: 'none'

environment:
  sdk: ">=3.5.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutist: $flutistVersion

# Flutter Native Workspace configuration
# All packages inside the 'packages' directory will be managed together
workspace:''';

  /// Generates project.dart content.
  static String projectDart(String projectName) => '''
// ignore_for_file: unused_import

import 'package:flutist/flutist.dart';

import 'flutist/flutist_gen.dart';
import 'package.dart';

final project = Project(
  name: '$projectName',
  options: const ProjectOptions(),
  modules: [
    Module(
      name: 'app',
      type: ModuleType.simple,
      dependencies: [
        // Example)
        // package.dependencies.intl,
      ],
      devDependencies: [
        // Example)
        // package.dependencies.test,
      ],
      modules: [
        // Example)
        // package.modules.login,
      ],
    ),
  ],
);
''';

  /// Generates package.dart content.
  static String packageDart(String projectName) => '''
import 'package:flutist/flutist.dart';

final package = Package(
  name: '$projectName',
  dependencies: [
    // TODO: Add dependencies here
    Dependency(name: 'intl', version: '^20.2.0'),
    Dependency(name: 'test', version: '^1.28.0'),
  ],
  modules: [
    // TODO: Add modules here
  ],
);
''';

  /// Generates app/lib/main.dart content.
  static String appMainDart() => '''
import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  runApp(const App());
}
''';

  /// Generates app/lib/app.dart content.
  static String appAppDart() => '''
import 'package:flutter/material.dart';

/// The root widget of the application.
/// This class acts as the orchestrator for global providers, 
/// theme settings, and navigation.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutist Project',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutist App')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 64, color: Colors.deepPurple),
            SizedBox(height: 16),
            Text(
              'Welcome to your Flutist Project!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Edit "app/lib/app.dart" to start building.'),
          ],
        ),
      ),
    );
  }
}
''';

  /// Generates app/pubspec.yaml content.
  static String appPubspecYaml() => '''
name: app
version: 1.0.0
publish_to: "none"

environment:
  sdk: ">=3.5.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter

resolution: workspace
''';

  /// Generates feature template.yaml content.
  static String featureTemplateYaml() => '''
description: "Feature module with BLoC pattern"

attributes:
  - name: name
    required: true
  - name: path
    required: false
    default: "features"

items:
  - type: file
    path: "{{path}}/{{name}}/bloc/{{name}}_bloc.dart"
    templatePath: "bloc.dart.template"
  
  - type: file
    path: "{{path}}/{{name}}/bloc/{{name}}_state.dart"
    templatePath: "state.dart.template"
  
  - type: file
    path: "{{path}}/{{name}}/bloc/{{name}}_event.dart"
    templatePath: "event.dart.template"
  
  - type: file
    path: "{{path}}/{{name}}/presentation/{{name}}_screen.dart"
    templatePath: "screen.dart.template"
''';

  static String featureBlocDartTemplate() => '''
import 'package:flutter_bloc/flutter_bloc.dart';

import '{{name}}_event.dart';
import '{{name}}_state.dart';

/// BLoC for {{Name}} feature.
class {{Name}}Bloc extends Bloc<{{Name}}Event, {{Name}}State> {
  {{Name}}Bloc() : super({{Name}}Initial()) {
    on<{{Name}}Started>(_onStarted);
    on<{{Name}}Loaded>(_onLoaded);
  }

  Future<void> _onStarted(
    {{Name}}Started event,
    Emitter<{{Name}}State> emit,
  ) async {
    emit({{Name}}Loading());
    
    try {
      // TODO: Implement business logic
      
      emit({{Name}}Success());
    } catch (e) {
      emit({{Name}}Error(e.toString()));
    }
  }

  Future<void> _onLoaded(
    {{Name}}Loaded event,
    Emitter<{{Name}}State> emit,
  ) async {
    // TODO: Handle loaded event
  }
}
''';

  /// Generates feature state template content.
  static String featureStateDartTemplate() => '''
/// States for {{Name}} BLoC.
sealed class {{Name}}State {}

/// Initial state.
final class {{Name}}Initial extends {{Name}}State {}

/// Loading state.
final class {{Name}}Loading extends {{Name}}State {}

/// Success state.
final class {{Name}}Success extends {{Name}}State {}

/// Error state.
final class {{Name}}Error extends {{Name}}State {
  final String message;
  
  {{Name}}Error(this.message);
}
''';

  /// Generates feature event template content.
  static String featureEventDartTemplate() => '''
/// Events for {{Name}} BLoC.
sealed class {{Name}}Event {}

/// Event triggered when the feature starts.
final class {{Name}}Started extends {{Name}}Event {}

/// Event triggered when data is loaded.
final class {{Name}}Loaded extends {{Name}}Event {
  // TODO: Add necessary fields
}
''';

  /// Generates feature screen template content.
  static String featureScreenDartTemplate() => '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/{{name}}_bloc.dart';
import '../bloc/{{name}}_event.dart';
import '../bloc/{{name}}_state.dart';

/// Screen for {{Name}} feature.
class {{Name}}Screen extends StatelessWidget {
  const {{Name}}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => {{Name}}Bloc()..add({{Name}}Started()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('{{Name}}'),
        ),
        body: BlocBuilder<{{Name}}Bloc, {{Name}}State>(
          builder: (context, state) {
            return switch (state) {
              {{Name}}Initial() => const Center(
                  child: Text('Welcome to {{Name}}'),
                ),
              {{Name}}Loading() => const Center(
                  child: CircularProgressIndicator(),
                ),
              {{Name}}Success() => const Center(
                  child: Text('Success!'),
                ),
              {{Name}}Error(:final message) => Center(
                  child: Text('Error: \$message'),
                ),
            };
          },
        ),
      ),
    );
  }
}
''';

  /// Generates root README.md content.
  static String rootReadme(String projectName, String version) => '''
<div align="center">

<img src="https://raw.githubusercontent.com/seonwooke/flutist/release/1.0.0/assets/flutist_banner.png" alt="Flutist Banner">

**A Flutter project managed by Flutist**

[![Version](https://img.shields.io/badge/version-$version-blue.svg)](pubspec.yaml)
[![Flutter](https://img.shields.io/badge/Flutter-^3.5.0-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.5.0%20%3C4.0.0-blue.svg)](https://dart.dev)

</div>

## 📋 About

$projectName is a Flutter workspace project built with Flutist, a powerful project management framework for Flutter applications. This project follows a modular architecture pattern, making it easy to scale and maintain.

## ✨ Features

- 🏗️ **Modular Architecture** - Organized codebase with clear module separation
- 📦 **Workspace Management** - Centralized dependency management
- 🎨 **Code Generation** - Scaffold templates for rapid development
- 🔗 **Dependency Graph** - Visualize module dependencies
- 🚀 **Fast Development** - Streamlined workflow with Flutist CLI

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (^3.5.0 or higher)
- Dart SDK (^3.5.0 or higher)
- Flutist CLI installed

### Installation

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Generate workspace files:**
   ```bash
   flutist generate
   ```

3. **Run the application:**
   ```bash
   flutist run
   ```

## 📁 Project Structure

```
$projectName/
├── app/                    # Main application module
├── project.dart            # Project configuration
├── package.dart            # Centralized dependencies
├── pubspec.yaml            # Root workspace configuration
├── analysis_options.yaml   # Linting rules
├── flutist/
│   ├── templates/          # Scaffold templates
│   └── flutist_gen.dart    # Generated code (auto-generated)
└── README.md               # This file
```

### Key Files

- **`project.dart`** - Defines all modules and their dependencies
- **`package.dart`** - Central repository for all package dependencies
- **`pubspec.yaml`** - Workspace configuration for Flutter
- **`flutist/templates/`** - Custom scaffold templates for code generation

## 🛠️ Available Commands

| Command | Description |
|---------|-------------|
| `flutist init` | Initialize a new Flutist project |
| `flutist create` | Create a new module in the project |
| `flutist generate` | Sync all pubspec.yaml files based on project.dart |
| `flutist run` | Run the Flutter app from root |
| `flutist pub add <package>` | Add a dependency to package.dart |
| `flutist scaffold <template>` | Generate code from templates |
| `flutist graph` | Generate dependency graph visualization |
| `flutist help` | Show help information |

### Examples

```bash
# Create a new feature module
flutist create --path features --name login --options feature

# Add a new dependency
flutist pub add http

# Generate code from template
flutist scaffold feature --name user_profile

# Visualize dependencies
flutist graph --format mermaid
```

## 📦 Module Types

This project supports different module types:

- **`feature`** - Feature module with Domain, Data, Presentation layers
- **`library`** - Library module with Example, Implementation, Interface, Tests, Testing layers
- **`standard`** - Standard module with Implementation, Tests, Testing layers
- **`simple`** - Simple module with only lib folder
- **`custom`** - Custom module with custom template

## 🔧 Development

### Adding Dependencies

Dependencies are managed centrally in `package.dart`. To add a new dependency:

```bash
flutist pub add <package_name>
```

Then run `flutist generate` to sync the changes to all modules.

### Creating Modules

```bash
# Create a simple module
flutist create --path lib --name utils --options simple

# Create a feature module
flutist create --path features --name authentication --options feature
```

### Code Generation

Use scaffold templates to generate boilerplate code:

```bash
# List available templates
flutist scaffold list

# Generate from template
flutist scaffold feature --name login
```

## 📚 Documentation

For more information about Flutist, visit the [official documentation](https://github.com/flutist/flutist).

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

---

**Built with ❤️ using Flutist**
''';

  /// Generates root analysis_options.yaml content.
  static String analysisOptionsYaml() => '''
# This file configures the static analysis for this Dart project.
# No external packages required - all rules are defined here.

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.mocks.dart"
    - "**/generated/**"
    - "build/**"
  
  errors:
    # Treat missing required parameters as errors
    missing_required_param: error
    missing_return: error
    
    # Warnings
    unused_import: warning
    unused_local_variable: warning
    dead_code: warning
  
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true

linter:
  rules:
    # === ERROR PREVENTION ===
    # Avoid common mistakes
    avoid_empty_else: true
    avoid_print: true
    avoid_relative_lib_imports: true
    avoid_returning_null_for_future: true
    avoid_slow_async_io: true
    avoid_types_as_parameter_names: true
    cancel_subscriptions: true
    close_sinks: true
    control_flow_in_finally: true
    empty_statements: true
    hash_and_equals: true
    iterable_contains_unrelated_type: true
    list_remove_unrelated_type: true
    literal_only_boolean_expressions: true
    no_adjacent_strings_in_list: true
    no_duplicate_case_values: true
    test_types_in_equals: true
    throw_in_finally: true
    unrelated_type_equality_checks: true
    valid_regexps: true
    
    # === STYLE ===
    # Declarations
    always_declare_return_types: true
    annotate_overrides: true
    avoid_init_to_null: true
    avoid_null_checks_in_equality_operators: true
    avoid_return_types_on_setters: true
    camel_case_extensions: true
    camel_case_types: true
    constant_identifier_names: true
    curly_braces_in_flow_control_structures: true
    empty_catches: true
    empty_constructor_bodies: true
    file_names: true
    implementation_imports: true
    library_names: true
    library_prefixes: true
    non_constant_identifier_names: true
    null_closures: true
    package_prefixed_library_names: true
    prefer_generic_function_type_aliases: true
    slash_for_doc_comments: true
    type_init_formals: true
    
    # === USAGE ===
    # Collections
    avoid_function_literals_in_foreach_calls: true
    prefer_collection_literals: true
    prefer_contains: true
    prefer_for_elements_to_map_fromIterable: true
    prefer_function_declarations_over_variables: true
    prefer_if_null_operators: true
    prefer_inlined_adds: true
    prefer_is_empty: true
    prefer_is_not_empty: true
    prefer_iterable_whereType: true
    prefer_spread_collections: true
    
    # Strings
    prefer_adjacent_string_concatenation: true
    prefer_interpolation_to_compose_strings: true
    prefer_single_quotes: true
    unnecessary_brace_in_string_interps: true
    unnecessary_string_escapes: true
    unnecessary_string_interpolations: true
    
    # Functions/Methods
    avoid_bool_literals_in_conditional_expressions: true
    avoid_catches_without_on_clauses: false
    avoid_catching_errors: true
    avoid_positional_boolean_parameters: true
    avoid_renaming_method_parameters: true
    avoid_returning_null_for_void: true
    avoid_void_async: true
    prefer_void_to_null: true
    use_to_and_as_if_applicable: true
    
    # Variables
    avoid_shadowing_type_parameters: true
    prefer_final_fields: true
    prefer_final_in_for_each: true
    prefer_final_locals: true
    prefer_typing_uninitialized_variables: true
    unnecessary_late: true
    
    # === OPTIMIZATION ===
    await_only_futures: true
    cascade_invocations: false
    no_leading_underscores_for_local_identifiers: true
    prefer_asserts_in_initializer_lists: true
    prefer_conditional_assignment: true
    prefer_const_constructors: true
    prefer_const_constructors_in_immutables: true
    prefer_const_declarations: true
    prefer_const_literals_to_create_immutables: true
    prefer_constructors_over_static_methods: true
    prefer_foreach: true
    prefer_if_elements_to_conditional_expressions: true
    prefer_initializing_formals: true
    prefer_null_aware_operators: true
    sort_constructors_first: true
    unawaited_futures: true
    unnecessary_await_in_return: true
    unnecessary_null_aware_assignments: true
    unnecessary_null_in_if_null_operators: true
    unnecessary_overrides: true
    unnecessary_parenthesis: true
    unnecessary_this: true
    use_string_buffers: true
    
    # === FLUTTER SPECIFIC ===
    avoid_unnecessary_containers: true
    avoid_web_libraries_in_flutter: true
    no_logic_in_create_state: true
    sized_box_for_whitespace: true
    sort_child_properties_last: true
    use_build_context_synchronously: true
    use_full_hex_values_for_flutter_colors: true
    use_key_in_widget_constructors: true
    
    # === CLEANUP ===
    directives_ordering: true
    unnecessary_const: true
    unnecessary_new: true
    unnecessary_nullable_for_final_variable_declarations: true
    unnecessary_statements: true
    use_function_type_syntax_for_parameters: true
    use_rethrow_when_possible: true
''';
}
