import 'package:flutist/flutist.dart';
import 'package:test/test.dart';

void main() {
  group('DartSource.maskLineComments', () {
    test('preserves length so offsets stay valid', () {
      const content = """
final package = Package(
  dependencies: [
    // Dependency(name: 'intl', version: '^20.2.0'),
    Dependency(name: 'http', version: '^1.1.0'),
  ],
);
""";
      final masked = DartSource.maskLineComments(content);
      expect(masked.length, content.length);
      expect(masked.split('\n').length, content.split('\n').length);
    });

    test('blanks commented declarations but keeps real ones', () {
      const content =
          "    // Dependency(name: 'intl', version: '^1.0.0'),\n"
          "    Dependency(name: 'http', version: '^1.1.0'),";
      final masked = DartSource.maskLineComments(content);

      expect(masked.contains('intl'), isFalse);
      expect(masked.contains("Dependency(name: 'http', version: '^1.1.0')"),
          isTrue);
    });

    test('leaves the // inside a single-quoted string', () {
      const content = "url: 'https://github.com/acme/a.git',";
      expect(DartSource.maskLineComments(content), content);
    });

    test('leaves the // inside a double-quoted string', () {
      const content = 'url: "https://github.com/acme/a.git",';
      expect(DartSource.maskLineComments(content), content);
    });

    test('masks a trailing comment that follows a string', () {
      const content = "url: 'https://a.git', // the analytics package";
      final masked = DartSource.maskLineComments(content);

      expect(masked.contains('analytics'), isFalse);
      expect(masked.trimRight(), "url: 'https://a.git',");
      expect(masked.length, content.length);
    });

    test('finds the real declaration, not an earlier commented one', () {
      const content = """
    // Dependency.path(name: 'design_system', path: 'examples/x'),
    Dependency.path(name: 'design_system', path: 'shared/design_system'),
""";
      final masked = DartSource.maskLineComments(content);
      final index = masked.indexOf('Dependency.path');

      // The offset from the masked text must land on the real declaration
      // when applied to the original.
      expect(content.substring(index),
          startsWith("Dependency.path(name: 'design_system', "
              "path: 'shared/design_system')"));
    });

    test('handles an escaped quote inside a string', () {
      const content = r"desc: 'it\'s fine', // trailing";
      final masked = DartSource.maskLineComments(content);

      expect(masked.contains('trailing'), isFalse);
      expect(masked.contains(r"it\'s fine"), isTrue);
    });

    test('leaves comment-free content untouched', () {
      const content = "Dependency(name: 'http', version: '^1.1.0'),";
      expect(DartSource.maskLineComments(content), content);
    });
  });
}
