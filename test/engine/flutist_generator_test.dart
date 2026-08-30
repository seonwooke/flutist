import 'package:flutist/flutist.dart';
import 'package:test/test.dart';

void main() {
  group('GenFileGenerator.parsePackageDart', () {
    test('parses package name', () {
      const content = """
final package = Package(
  name: 'my_project',
  dependencies: [],
  modules: [],
);
""";
      final result = GenFileGenerator.parsePackageDart(content);
      expect(result.name, 'my_project');
    });

    test('defaults name to workspace when missing', () {
      const content = """
final package = Package(
  dependencies: [],
  modules: [],
);
""";
      final result = GenFileGenerator.parsePackageDart(content);
      expect(result.name, 'workspace');
    });

    test('parses dependencies', () {
      const content = """
final package = Package(
  name: 'test',
  dependencies: [
    Dependency(name: 'http', version: '^1.1.0'),
    Dependency(name: 'provider', version: '^6.1.1'),
  ],
  modules: [],
);
""";
      final result = GenFileGenerator.parsePackageDart(content);
      expect(result.dependencies, hasLength(2));
      expect(result.dependencies[0].name, 'http');
      expect(result.dependencies[0].version, '^1.1.0');
      expect(result.dependencies[1].name, 'provider');
      expect(result.dependencies[1].version, '^6.1.1');
    });

    test('parses path dependencies', () {
      const content = """
final package = Package(
  name: 'test',
  dependencies: [
    Dependency.path(name: 'design_system', path: 'shared/design_system'),
  ],
  modules: [],
);
""";
      final result = GenFileGenerator.parsePackageDart(content);
      expect(result.dependencies, hasLength(1));
      expect(result.dependencies[0].name, 'design_system');
      expect(result.dependencies[0].path, 'shared/design_system');
      expect(result.dependencies[0].version, isNull);
      expect(result.dependencies[0].kind, DependencyKind.path);
    });

    test('parses git dependencies', () {
      const content = """
final package = Package(
  name: 'test',
  dependencies: [
    Dependency.git(
      name: 'analytics',
      url: 'https://github.com/acme/analytics.git',
      ref: 'main',
      path: 'packages/analytics',
    ),
  ],
  modules: [],
);
""";
      final result = GenFileGenerator.parsePackageDart(content);
      expect(result.dependencies, hasLength(1));
      expect(result.dependencies[0].name, 'analytics');
      expect(result.dependencies[0].gitUrl,
          'https://github.com/acme/analytics.git');
      expect(result.dependencies[0].gitRef, 'main');
      expect(result.dependencies[0].gitPath, 'packages/analytics');
      expect(result.dependencies[0].kind, DependencyKind.git);
    });

    test('parses git dependencies without ref or path', () {
      const content = """
final package = Package(
  name: 'test',
  dependencies: [
    Dependency.git(name: 'analytics', url: 'git@github.com:acme/a.git'),
  ],
  modules: [],
);
""";
      final result = GenFileGenerator.parsePackageDart(content);
      expect(result.dependencies, hasLength(1));
      expect(result.dependencies[0].gitUrl, 'git@github.com:acme/a.git');
      expect(result.dependencies[0].gitRef, isNull);
      expect(result.dependencies[0].gitPath, isNull);
    });

    test('parses hosted, path, and git dependencies together', () {
      const content = """
final package = Package(
  name: 'test',
  dependencies: [
    Dependency(name: 'http', version: '^1.1.0'),
    Dependency.path(name: 'design_system', path: 'shared/design_system'),
    Dependency.git(name: 'analytics', url: 'https://example.com/a.git'),
  ],
  modules: [],
);
""";
      final result = GenFileGenerator.parsePackageDart(content);
      expect(result.dependencies.map((d) => d.name),
          ['http', 'design_system', 'analytics']);
      expect(result.dependencies.map((d) => d.kind), [
        DependencyKind.hosted,
        DependencyKind.path,
        DependencyKind.git,
      ]);
    });

    test('parses named arguments in any order', () {
      const content = """
final package = Package(
  name: 'test',
  dependencies: [
    Dependency(version: '^1.1.0', name: 'http'),
    Dependency.git(ref: 'v2', url: 'https://example.com/a.git', name: 'a'),
  ],
  modules: [],
);
""";
      final result = GenFileGenerator.parsePackageDart(content);
      expect(result.dependencies, hasLength(2));
      expect(result.dependencies[0].name, 'http');
      expect(result.dependencies[0].version, '^1.1.0');
      expect(result.dependencies[1].name, 'a');
      expect(result.dependencies[1].gitRef, 'v2');
    });

    test('skips malformed declarations without dropping later ones', () {
      const content = """
final package = Package(
  name: 'test',
  dependencies: [
    Dependency.path(name: 'broken'),
    Dependency(name: 'http', version: '^1.1.0'),
  ],
  modules: [],
);
""";
      final result = GenFileGenerator.parsePackageDart(content);
      expect(result.dependencies, hasLength(1));
      expect(result.dependencies[0].name, 'http');
    });

    test('ignores commented-out dependencies', () {
      const content = """
final package = Package(
  name: 'test',
  dependencies: [
    // Example)
    // Dependency(name: 'intl', version: '^20.2.0'),
    // Dependency.path(name: 'design_system', path: 'shared/design_system'),
    // Dependency.git(
    //   name: 'analytics',
    //   url: 'https://github.com/acme/analytics.git',
    //   ref: 'main',
    // ),
    Dependency(name: 'http', version: '^1.1.0'),
  ],
  modules: [],
);
""";
      final result = GenFileGenerator.parsePackageDart(content);
      expect(result.dependencies.map((d) => d.name), ['http']);
    });

    test('ignores commented-out modules', () {
      const content = """
final package = Package(
  name: 'test',
  dependencies: [],
  modules: [
    Module(name: 'auth'),
    // Module(name: 'legacy'),
  ],
);
""";
      final result = GenFileGenerator.parsePackageDart(content);
      expect(result.modules.map((m) => m.name), ['auth']);
    });

    test('keeps the // inside a git URL', () {
      const content = """
final package = Package(
  name: 'test',
  dependencies: [
    Dependency.git(name: 'a', url: 'https://github.com/acme/a.git', ref: 'v1'),
  ],
  modules: [],
);
""";
      final result = GenFileGenerator.parsePackageDart(content);
      expect(result.dependencies, hasLength(1));
      expect(result.dependencies[0].gitUrl, 'https://github.com/acme/a.git');
      expect(result.dependencies[0].gitRef, 'v1');
    });

    test('parses modules', () {
      const content = """
final package = Package(
  name: 'test',
  dependencies: [],
  modules: [
    Module(name: 'auth'),
    Module(name: 'network'),
    Module(name: 'models'),
  ],
);
""";
      final result = GenFileGenerator.parsePackageDart(content);
      expect(result.modules, hasLength(3));
      expect(result.modules[0].name, 'auth');
      expect(result.modules[1].name, 'network');
      expect(result.modules[2].name, 'models');
    });

    test('handles empty dependencies and modules', () {
      const content = """
final package = Package(
  name: 'test',
  dependencies: [],
  modules: [],
);
""";
      final result = GenFileGenerator.parsePackageDart(content);
      expect(result.dependencies, isEmpty);
      expect(result.modules, isEmpty);
    });

    test('handles content with comments', () {
      const content = """
final package = Package(
  name: 'test',
  dependencies: [
    // HTTP client
    Dependency(name: 'http', version: '^1.1.0'),
  ],
  modules: [],
);
""";
      final result = GenFileGenerator.parsePackageDart(content);
      expect(result.dependencies, hasLength(1));
      expect(result.dependencies.first.name, 'http');
    });
  });

  group('Parser ↔ Generator round-trip', () {
    test('snake_case dependency names survive camelCase round-trip', () {
      const content = """
final package = Package(
  name: 'test',
  dependencies: [
    Dependency(name: 'shared_preferences', version: '^2.0.0'),
    Dependency(name: 'json_annotation', version: '^4.0.0'),
    Dependency(name: 'http', version: '^1.0.0'),
  ],
  modules: [],
);
""";
      final parsed = GenFileGenerator.parsePackageDart(content);

      for (final dep in parsed.dependencies) {
        final camelName = StringCase.toCamelCase(dep.name);
        final backToSnake = StringCase.toSnakeCase(camelName);
        expect(backToSnake, dep.name,
            reason: 'Round-trip failed for ${dep.name}');
      }
    });

    test('snake_case module names survive camelCase round-trip', () {
      const content = """
final package = Package(
  name: 'test',
  dependencies: [],
  modules: [
    Module(name: 'shared_module'),
    Module(name: 'network'),
    Module(name: 'user_profile'),
  ],
);
""";
      final parsed = GenFileGenerator.parsePackageDart(content);

      for (final mod in parsed.modules) {
        final camelName = StringCase.toCamelCase(mod.name);
        final backToSnake = StringCase.toSnakeCase(camelName);
        expect(backToSnake, mod.name,
            reason: 'Round-trip failed for ${mod.name}');
      }
    });
  });
}
