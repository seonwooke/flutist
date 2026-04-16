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
