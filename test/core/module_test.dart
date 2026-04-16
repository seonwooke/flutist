import 'package:flutist/flutist.dart';
import 'package:test/test.dart';

void main() {
  group('ScaffoldType.fromString', () {
    test('parses all valid types', () {
      expect(ScaffoldType.fromString('clean'), ScaffoldType.clean);
      expect(ScaffoldType.fromString('micro'), ScaffoldType.micro);
      expect(ScaffoldType.fromString('lite'), ScaffoldType.lite);
      expect(ScaffoldType.fromString('simple'), ScaffoldType.simple);
      expect(ScaffoldType.fromString('custom'), ScaffoldType.custom);
    });

    test('throws on invalid type', () {
      expect(() => ScaffoldType.fromString('invalid'), throwsArgumentError);
      expect(() => ScaffoldType.fromString(''), throwsArgumentError);
    });

    test('is case-sensitive', () {
      expect(() => ScaffoldType.fromString('Clean'), throwsArgumentError);
      expect(() => ScaffoldType.fromString('MICRO'), throwsArgumentError);
    });

    test('rejects old 1.x type names', () {
      expect(() => ScaffoldType.fromString('feature'), throwsArgumentError);
      expect(() => ScaffoldType.fromString('library'), throwsArgumentError);
      expect(() => ScaffoldType.fromString('standard'), throwsArgumentError);
    });
  });

  group('Module', () {
    test('defaults to empty lists', () {
      final module = Module(name: 'test');
      expect(module.dependencies, isEmpty);
      expect(module.devDependencies, isEmpty);
      expect(module.modules, isEmpty);
    });
  });
}
