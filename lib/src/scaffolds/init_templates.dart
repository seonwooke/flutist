class InitTemplates {
  static String pubspecYaml(String projectName) => '''
name: $projectName
description: A new Flutter project managed by Flutist.
version: 1.0.0+1
publish_to: 'none'

environment:
  sdk: ^3.5.0

dependencies:
  flutter:
    sdk: flutter
  flutist:
    path: ../flutist

# Flutter Native Workspace configuration
# All packages inside the 'packages' directory will be managed together
workspace:
''';

  static String projectDart(String projectName) => '''
// ignore_for_file: unused_import

import 'package:flutist/flutist.dart';

import 'flutist/flutist_gen.dart';
import 'package.dart';

final project = Project(
  name: '$projectName',
  options: const ProjectOptions(),
  modules: [
    // Example)
    Module(
      name: 'app',
      type: ModuleType.simple,
      dependencies: [
        // Example)
        // package.dependencies.intl,
      ],
      devDependencies: [
        // package.dependencies.test,
      ],
      modules: [
        // package.modules.login,
      ],
    ),
  ],
);
''';

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

  static String appMainDart() => '''
import 'package:flutter/material.dart';
import 'package:app/app.dart';

void main() {
  runApp(const App());
}
''';

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

  static String appPubspecYaml() => '''
name: app
version: 1.0.0
publish_to: "none"

environment:
  sdk: ^3.5.0

dependencies:
  flutter:
    sdk: flutter

resolution: workspace
''';

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
/// {{Name}} 기능을 위한 BLoC.
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

  static String featureStateDartTemplate() => '''
/// States for {{Name}} BLoC.
/// {{Name}} BLoC의 상태들.
sealed class {{Name}}State {}

/// Initial state.
/// 초기 상태.
final class {{Name}}Initial extends {{Name}}State {}

/// Loading state.
/// 로딩 상태.
final class {{Name}}Loading extends {{Name}}State {}

/// Success state.
/// 성공 상태.
final class {{Name}}Success extends {{Name}}State {}

/// Error state.
/// 에러 상태.
final class {{Name}}Error extends {{Name}}State {
  final String message;
  
  {{Name}}Error(this.message);
}
''';

  static String featureEventDartTemplate() => '''
/// Events for {{Name}} BLoC.
/// {{Name}} BLoC의 이벤트들.
sealed class {{Name}}Event {}

/// Event triggered when the feature starts.
/// 기능이 시작될 때 트리거되는 이벤트.
final class {{Name}}Started extends {{Name}}Event {}

/// Event triggered when data is loaded.
/// 데이터가 로드될 때 트리거되는 이벤트.
final class {{Name}}Loaded extends {{Name}}Event {
  // TODO: Add necessary fields
}
''';

  static String featureScreenDartTemplate() => '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/{{name}}_bloc.dart';
import '../bloc/{{name}}_event.dart';
import '../bloc/{{name}}_state.dart';

/// Screen for {{Name}} feature.
/// {{Name}} 기능을 위한 화면.
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
    prefer_const_literals_to_create_immutables: true
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
