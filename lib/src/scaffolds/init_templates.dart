class InitTemplates {
  static String pubspecYaml(String projectName) => '''
name: $projectName
description: A new Flutter project managed by Flutist.
version: 1.0.0+1
publish_to: 'none'

environment:
  sdk: ^3.5.0

dependencies:
  flutist:
    path: ../flutist

# Flutter Native Workspace configuration
# All packages inside the 'packages' directory will be managed together
workspace:
''';

  static String projectDart(String projectName) => '''
import 'package:flutist/flutist.dart';

final project = Project(
  name: '$projectName',
  options: const ProjectOptions(
    useCustomTemplate: false,
  ),
  modules: [
    Module(
      name: 'app',
      type: ModuleType.simple,
      dependencies: [
        // Example)
        // package.dependencies.intl,
        // package.devDependencies.test,
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
  ],
  devDependencies: [
    // TODO: Add dev dependencies here
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
}
