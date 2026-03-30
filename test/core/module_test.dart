import 'package:flutist/flutist.dart';
import 'package:test/test.dart';

void main() {
  group('ModuleType.fromString', () {
    test('parses all valid types', () {
      expect(ModuleType.fromString('clean'), ModuleType.clean);
      expect(ModuleType.fromString('micro'), ModuleType.micro);
      expect(ModuleType.fromString('lite'), ModuleType.lite);
      expect(ModuleType.fromString('simple'), ModuleType.simple);
      expect(ModuleType.fromString('custom'), ModuleType.custom);
    });

    test('throws on invalid type', () {
      expect(() => ModuleType.fromString('invalid'), throwsArgumentError);
      expect(() => ModuleType.fromString(''), throwsArgumentError);
    });

    test('is case-sensitive', () {
      expect(() => ModuleType.fromString('Clean'), throwsArgumentError);
      expect(() => ModuleType.fromString('MICRO'), throwsArgumentError);
    });

    test('rejects old 1.x type names', () {
      expect(() => ModuleType.fromString('feature'), throwsArgumentError);
      expect(() => ModuleType.fromString('library'), throwsArgumentError);
      expect(() => ModuleType.fromString('standard'), throwsArgumentError);
    });
  });

  group('Module', () {
    test('defaults to ModuleType.micro', () {
      final module = Module(name: 'test');
      expect(module.type, ModuleType.micro);
    });

    test('defaults to empty lists', () {
      final module = Module(name: 'test');
      expect(module.dependencies, isEmpty);
      expect(module.devDependencies, isEmpty);
      expect(module.modules, isEmpty);
    });
  });
}
