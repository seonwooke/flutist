import 'dart:async';
import 'dart:io';

import 'package:flutist/flutist.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// Regression tests for what `flutist generate` is and is not allowed to
/// touch in a module's `pubspec.yaml`.
///
/// The rule under test: Flutist owns a name only if `package.dart` declares
/// it or the workspace contains a module by that name. Everything else was
/// written by the user and must survive generation byte for byte. This is
/// the guarantee that lets a team keep a local `path:` package or a Git fork
/// wired up by hand, and it had no test coverage before.
void main() {
  late Directory temp;
  late String originalCwd;

  setUp(() {
    originalCwd = Directory.current.path;
    temp = Directory.systemTemp.createTempSync('flutist_generate_test_');
    // macOS hands out /var/... symlinked to /private/var/...; resolving here
    // keeps expected relative paths comparable to what generate computes.
    temp = Directory(temp.resolveSymbolicLinksSync());
  });

  tearDown(() {
    Directory.current = originalCwd;
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  /// Writes [content] to [relativePath] under the temp workspace.
  void write(String relativePath, String content) {
    final file = File(p.join(temp.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  /// Reads a module's parsed pubspec.yaml back.
  Map readPubspec(String relativeDir) {
    final file = File(p.join(temp.path, relativeDir, 'pubspec.yaml'));
    return loadYaml(file.readAsStringSync()) as Map;
  }

  /// Lays down a root pubspec.yaml listing [modules] as workspace entries.
  void writeRootPubspec(List<String> modules) {
    write('pubspec.yaml', '''
name: root_app
version: 1.0.0+1
publish_to: 'none'

environment:
  sdk: ">=3.5.0 <4.0.0"

workspace:
${modules.map((m) => '  - $m').join('\n')}
''');
  }

  /// Lays down a module directory with the given pubspec body.
  void writeModule(String dir, String pubspec) {
    write(p.join(dir, 'pubspec.yaml'), pubspec);
  }

  /// Runs the generate pipeline with the temp workspace as cwd.
  void runGenerate({Set<String> removedDependencies = const {}}) {
    Directory.current = temp.path;
    GenerateCommand().execute([], removedDependencies: removedDependencies);
  }

  /// Runs generate and returns everything it printed, so the warning text
  /// itself can be asserted on.
  String captureGenerate({Set<String> removedDependencies = const {}}) {
    final buffer = StringBuffer();
    runZoned(
      () => runGenerate(removedDependencies: removedDependencies),
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => buffer.writeln(line),
      ),
    );
    return buffer.toString();
  }

  group('preserves what the user owns', () {
    setUp(() {
      writeRootPubspec(['mymod']);

      write('package.dart', '''
import 'package:flutist/flutist.dart';

final package = Package(
  name: 'root_app',
  dependencies: [
    Dependency(name: 'http', version: '^1.1.0'),
  ],
  modules: [
    Module(name: 'mymod'),
  ],
);
''');

      write('project.dart', '''
import 'package:flutist/flutist.dart';

final project = Project(
  name: 'root_app',
  options: const ProjectOptions(),
  modules: [
    Module(
      name: 'mymod',
      dependencies: [
        package.dependencies.http,
      ],
      devDependencies: [],
      modules: [],
    ),
  ],
);
''');

      writeModule('mymod', '''
name: mymod
version: 1.0.0+1
publish_to: 'none'

environment:
  sdk: ">=3.5.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  design_system:
    path: ../shared/design_system
  analytics:
    git:
      url: https://github.com/acme/analytics.git
      ref: main
  intl: ^0.19.0
  http: ^0.13.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

resolution: workspace
''');
    });

    test('keeps a hand-written path dependency', () {
      runGenerate();

      final deps = readPubspec('mymod')['dependencies'] as Map;
      expect(deps['design_system'], {'path': '../shared/design_system'});
    });

    test('keeps a hand-written git dependency with its ref', () {
      runGenerate();

      final deps = readPubspec('mymod')['dependencies'] as Map;
      expect(deps['analytics'], {
        'git': {
          'url': 'https://github.com/acme/analytics.git',
          'ref': 'main',
        }
      });
    });

    test('keeps sdk dependencies', () {
      runGenerate();

      final pubspec = readPubspec('mymod');
      expect((pubspec['dependencies'] as Map)['flutter'], {'sdk': 'flutter'});
      expect(
          (pubspec['dev_dependencies'] as Map)['flutter_test'],
          {'sdk': 'flutter'});
    });

    test('keeps a hosted dependency that package.dart does not declare', () {
      runGenerate();

      final deps = readPubspec('mymod')['dependencies'] as Map;
      expect(deps['intl'], '^0.19.0');
    });

    test('keeps a hand-written dev dependency', () {
      runGenerate();

      final devDeps = readPubspec('mymod')['dev_dependencies'] as Map;
      expect(devDeps['flutter_lints'], '^3.0.0');
    });

    test('keeps non-dependency sections', () {
      runGenerate();

      final pubspec = readPubspec('mymod');
      expect(pubspec['name'], 'mymod');
      expect(pubspec['publish_to'], 'none');
      expect(pubspec['resolution'], 'workspace');
      expect((pubspec['environment'] as Map)['sdk'], '>=3.5.0 <4.0.0');
    });

    test('overwrites the version of a dependency package.dart declares', () {
      runGenerate();

      final deps = readPubspec('mymod')['dependencies'] as Map;
      expect(deps['http'], '^1.1.0',
          reason: 'package.dart is the source of truth for managed versions');
    });

    test('says nothing about dropped entries when nothing is dropped', () {
      final output = captureGenerate();

      expect(output, isNot(contains('Dropped')),
          reason: 'a preserved entry must never be reported as dropped');
    });

    test('is idempotent across repeated runs', () {
      runGenerate();
      final first =
          File(p.join(temp.path, 'mymod', 'pubspec.yaml')).readAsStringSync();

      runGenerate();
      final second =
          File(p.join(temp.path, 'mymod', 'pubspec.yaml')).readAsStringSync();

      expect(second, first);
    });
  });

  group('removes what Flutist owns but project.dart does not declare', () {
    setUp(() {
      writeRootPubspec(['mymod', 'utils']);

      write('package.dart', '''
import 'package:flutist/flutist.dart';

final package = Package(
  name: 'root_app',
  dependencies: [
    Dependency(name: 'http', version: '^1.1.0'),
  ],
  modules: [
    Module(name: 'mymod'),
    Module(name: 'utils'),
  ],
);
''');

      write('project.dart', '''
import 'package:flutist/flutist.dart';

final project = Project(
  name: 'root_app',
  options: const ProjectOptions(),
  modules: [
    Module(
      name: 'mymod',
      dependencies: [],
      devDependencies: [],
      modules: [],
    ),
  ],
);
''');

      writeModule('utils', '''
name: utils

environment:
  sdk: ">=3.5.0 <4.0.0"

resolution: workspace
''');
    });

    test('drops a workspace module wired up by hand', () {
      writeModule('mymod', '''
name: mymod

environment:
  sdk: ">=3.5.0 <4.0.0"

dependencies:
  utils:
    path: ../utils

resolution: workspace
''');

      final output = captureGenerate();

      final deps = readPubspec('mymod')['dependencies'];
      expect(deps == null || !(deps as Map).containsKey('utils'), isTrue,
          reason: 'project.dart is the source of truth for module wiring');
      expect(output, contains('Dropped utils from dependencies'));
      expect(output, contains('package.modules.utils'),
          reason: 'the warning must name the declaration that would keep it');
    });

    test('drops a package.dart dependency the module does not reference', () {
      writeModule('mymod', '''
name: mymod

environment:
  sdk: ">=3.5.0 <4.0.0"

dependencies:
  http: ^1.1.0

resolution: workspace
''');

      final output = captureGenerate();

      final deps = readPubspec('mymod')['dependencies'];
      expect(deps == null || !(deps as Map).containsKey('http'), isTrue);
      expect(output, contains('Dropped http from dependencies'));
      expect(output, contains('package.dependencies.http'));
    });

    test('drops a package.dart dev dependency and says so', () {
      writeModule('mymod', '''
name: mymod

environment:
  sdk: ">=3.5.0 <4.0.0"

dev_dependencies:
  http: ^1.1.0

resolution: workspace
''');

      final output = captureGenerate();

      expect(readPubspec('mymod')['dev_dependencies'], isNull,
          reason: 'the section held nothing else, so it goes away');
      expect(output, contains('Dropped http from dev_dependencies'),
          reason: 'removing the whole section must not be silent either');
      expect(output, contains("'mymod' devDependencies list"));
    });

    test('stays quiet when project.dart already declares the dropped name',
        () {
      // auth_domain is declared on mymod in project.dart but missing from the
      // workspace, so the rebuild cannot resolve it. The advice "declare it
      // in project.dart" would point at the wrong file.
      write('project.dart', '''
import 'package:flutist/flutist.dart';

final project = Project(
  name: 'root_app',
  options: const ProjectOptions(),
  modules: [
    Module(
      name: 'mymod',
      dependencies: [],
      devDependencies: [],
      modules: [
        package.modules.utils,
      ],
    ),
  ],
);
''');
      writeRootPubspec(['mymod']); // utils dropped from the workspace
      writeModule('mymod', '''
name: mymod

environment:
  sdk: ">=3.5.0 <4.0.0"

dependencies:
  utils:
    path: ../utils

resolution: workspace
''');

      final output = captureGenerate();

      expect(output, contains('Could not find module: utils'),
          reason: 'the real problem is the missing workspace entry');
      expect(output, isNot(contains('Dropped utils')),
          reason: 'do not advise adding a declaration that already exists');
    });

    test('clears a dependency named by removedDependencies', () {
      writeModule('mymod', '''
name: mymod

environment:
  sdk: ">=3.5.0 <4.0.0"

dependencies:
  legacy_pkg: ^1.0.0

resolution: workspace
''');

      final output = captureGenerate(removedDependencies: {'legacy_pkg'});

      final deps = readPubspec('mymod')['dependencies'];
      expect(deps == null || !(deps as Map).containsKey('legacy_pkg'), isTrue,
          reason:
              'pub delete hands over names it removed from package.dart');
      expect(output, isNot(contains('Dropped legacy_pkg')),
          reason: 'pub delete already reported this removal to the user');
    });
  });

  group('emits declared path and git dependencies', () {
    void writeWorkspace({required String moduleDir}) {
      writeRootPubspec([moduleDir]);

      write('package.dart', '''
import 'package:flutist/flutist.dart';

final package = Package(
  name: 'root_app',
  dependencies: [
    Dependency.path(name: 'design_system', path: 'shared/design_system'),
    Dependency.git(
      name: 'analytics',
      url: 'https://github.com/acme/analytics.git',
      ref: 'main',
      path: 'packages/analytics',
    ),
    Dependency.git(name: 'bare', url: 'https://github.com/acme/bare.git'),
  ],
  modules: [
    Module(name: 'mymod'),
  ],
);
''');

      write('project.dart', '''
import 'package:flutist/flutist.dart';

final project = Project(
  name: 'root_app',
  options: const ProjectOptions(),
  modules: [
    Module(
      name: 'mymod',
      dependencies: [
        package.dependencies.designSystem,
        package.dependencies.analytics,
        package.dependencies.bare,
      ],
      devDependencies: [],
      modules: [],
    ),
  ],
);
''');

      writeModule(moduleDir, '''
name: mymod

environment:
  sdk: ">=3.5.0 <4.0.0"

resolution: workspace
''');
    }

    test('re-anchors a path dependency to a top-level module', () {
      writeWorkspace(moduleDir: 'mymod');

      runGenerate();

      final deps = readPubspec('mymod')['dependencies'] as Map;
      expect(deps['design_system'], {'path': '../shared/design_system'});
    });

    test('re-anchors a path dependency to a deeply nested module', () {
      writeWorkspace(moduleDir: 'features/auth/auth_data');

      runGenerate();

      final deps = readPubspec('features/auth/auth_data')['dependencies'] as Map;
      expect(deps['design_system'], {'path': '../../../shared/design_system'},
          reason:
              'package.dart declares the path once, relative to the root');
    });

    test('emits the long git form when ref or path is set', () {
      writeWorkspace(moduleDir: 'mymod');

      runGenerate();

      final deps = readPubspec('mymod')['dependencies'] as Map;
      expect(deps['analytics'], {
        'git': {
          'url': 'https://github.com/acme/analytics.git',
          'ref': 'main',
          'path': 'packages/analytics',
        }
      });
    });

    test('emits the short git form when neither ref nor path is set', () {
      writeWorkspace(moduleDir: 'mymod');

      runGenerate();

      final deps = readPubspec('mymod')['dependencies'] as Map;
      expect(deps['bare'], {'git': 'https://github.com/acme/bare.git'});
    });
  });

  group('module wiring declared in project.dart', () {
    test('writes a relative path between two workspace modules', () {
      writeRootPubspec(['features/auth/auth_data', 'packages/network']);

      write('package.dart', '''
import 'package:flutist/flutist.dart';

final package = Package(
  name: 'root_app',
  dependencies: [],
  modules: [
    Module(name: 'auth_data'),
    Module(name: 'network'),
  ],
);
''');

      write('project.dart', '''
import 'package:flutist/flutist.dart';

final project = Project(
  name: 'root_app',
  options: const ProjectOptions(),
  modules: [
    Module(
      name: 'auth_data',
      dependencies: [],
      devDependencies: [],
      modules: [
        package.modules.network,
      ],
    ),
    Module(
      name: 'network',
      dependencies: [],
      devDependencies: [],
      modules: [],
    ),
  ],
);
''');

      writeModule('features/auth/auth_data', '''
name: auth_data

environment:
  sdk: ">=3.5.0 <4.0.0"

resolution: workspace
''');
      writeModule('packages/network', '''
name: network

environment:
  sdk: ">=3.5.0 <4.0.0"

resolution: workspace
''');

      runGenerate();

      final deps = readPubspec('features/auth/auth_data')['dependencies'] as Map;
      expect(deps['network'], {'path': '../../../packages/network'});
    });
  });

  group('leaves modules outside project.dart alone', () {
    test('never rewrites a workspace module project.dart omits', () {
      writeRootPubspec(['mymod', 'untracked']);

      write('package.dart', '''
import 'package:flutist/flutist.dart';

final package = Package(
  name: 'root_app',
  dependencies: [
    Dependency(name: 'http', version: '^1.1.0'),
  ],
  modules: [
    Module(name: 'mymod'),
  ],
);
''');

      write('project.dart', '''
import 'package:flutist/flutist.dart';

final project = Project(
  name: 'root_app',
  options: const ProjectOptions(),
  modules: [
    Module(
      name: 'mymod',
      dependencies: [],
      devDependencies: [],
      modules: [],
    ),
  ],
);
''');

      writeModule('mymod', '''
name: mymod

environment:
  sdk: ">=3.5.0 <4.0.0"

resolution: workspace
''');

      const untracked = '''
name: untracked

environment:
  sdk: ">=3.5.0 <4.0.0"

dependencies:
  http: ^0.13.0

resolution: workspace
''';
      writeModule('untracked', untracked);

      runGenerate();

      final after = File(p.join(temp.path, 'untracked', 'pubspec.yaml'))
          .readAsStringSync();
      expect(after, untracked,
          reason: 'generate only walks modules declared in project.dart');
    });
  });
}
