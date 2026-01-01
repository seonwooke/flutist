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
}
