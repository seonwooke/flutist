import 'dart:io';

import 'package:flutist/flutist.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('flutist_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  void writeProjectDart(String content) {
    File('${tempDir.path}/project.dart').writeAsStringSync(content);
  }

  group('ProjectParser.parse', () {
    test('returns null when project.dart does not exist', () {
      final result = ProjectParser.parse(tempDir.path);
      expect(result, isNull);
    });

    test('parses project name', () {
      writeProjectDart("""
final project = Project(
  name: 'my_app',
  modules: [],
);
""");

      final result = ProjectParser.parse(tempDir.path);
      expect(result, isNotNull);
      expect(result!.name, 'my_app');
    });

    test('parses modules', () {
      writeProjectDart("""
final project = Project(
  name: 'my_app',
  modules: [
    Module(
      name: 'login',
    ),
    Module(
      name: 'network',
    ),
  ],
);
""");

      final result = ProjectParser.parse(tempDir.path);
      expect(result!.modules, hasLength(2));
      expect(result.modules[0].name, 'login');
      expect(result.modules[1].name, 'network');
    });


    test('parses module dependencies', () {
      writeProjectDart("""
final project = Project(
  name: 'my_app',
  modules: [
    Module(
      name: 'login',
      dependencies: [
        package.dependencies.http,
        package.dependencies.sharedPreferences,
      ],
    ),
  ],
);
""");

      final result = ProjectParser.parse(tempDir.path);
      final deps = result!.modules.first.dependencies;
      expect(deps, hasLength(2));
      expect(deps[0].name, 'http');
      expect(deps[1].name, 'shared_preferences');
    });

    test('parses module references', () {
      writeProjectDart("""
final project = Project(
  name: 'my_app',
  modules: [
    Module(
      name: 'login',
      modules: [
        package.modules.network,
        package.modules.models,
      ],
    ),
  ],
);
""");

      final result = ProjectParser.parse(tempDir.path);
      final modules = result!.modules.first.modules;
      expect(modules, hasLength(2));
      expect(modules[0].name, 'network');
      expect(modules[1].name, 'models');
    });
  });

  group('ProjectParser ProjectOptions parsing', () {
    test('defaults to strictMode true', () {
      writeProjectDart("""
final project = Project(
  name: 'my_app',
  modules: [],
);
""");

      final result = ProjectParser.parse(tempDir.path);
      expect(result!.options.strictMode, isTrue);
    });

    test('parses strictMode false', () {
      writeProjectDart("""
final project = Project(
  name: 'my_app',
  options: ProjectOptions(
    strictMode: false,
  ),
  modules: [],
);
""");

      final result = ProjectParser.parse(tempDir.path);
      expect(result!.options.strictMode, isFalse);
    });

    test('parses compositionRoots', () {
      writeProjectDart("""
final project = Project(
  name: 'my_app',
  options: ProjectOptions(
    compositionRoots: ['app', 'di_module'],
  ),
  modules: [],
);
""");

      final result = ProjectParser.parse(tempDir.path);
      expect(result!.options.compositionRoots, ['app', 'di_module']);
    });

    test('defaults compositionRoots to app', () {
      writeProjectDart("""
final project = Project(
  name: 'my_app',
  modules: [],
);
""");

      final result = ProjectParser.parse(tempDir.path);
      expect(result!.options.compositionRoots, ['app']);
    });
  });
}
