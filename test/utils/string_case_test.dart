import 'package:flutist/flutist.dart';
import 'package:test/test.dart';

void main() {
  group('StringCase.toCamelCase', () {
    test('converts snake_case to camelCase', () {
      expect(StringCase.toCamelCase('shared_preferences'), 'sharedPreferences');
      expect(StringCase.toCamelCase('json_annotation'), 'jsonAnnotation');
    });

    test('returns single word unchanged', () {
      expect(StringCase.toCamelCase('http'), 'http');
      expect(StringCase.toCamelCase('test'), 'test');
    });

    test('handles multiple underscores', () {
      expect(
        StringCase.toCamelCase('a_b_c'),
        'aBC',
      );
    });

    test('handles empty string', () {
      expect(StringCase.toCamelCase(''), '');
    });
  });

  group('StringCase.toSnakeCase', () {
    test('converts camelCase to snake_case', () {
      expect(StringCase.toSnakeCase('sharedPreferences'), 'shared_preferences');
      expect(StringCase.toSnakeCase('jsonAnnotation'), 'json_annotation');
    });

    test('converts PascalCase to snake_case', () {
      expect(StringCase.toSnakeCase('UserProfile'), 'user_profile');
      expect(StringCase.toSnakeCase('SharedPreferences'), 'shared_preferences');
    });

    test('handles already snake_case', () {
      expect(StringCase.toSnakeCase('already_snake'), 'already_snake');
    });

    test('handles single word', () {
      expect(StringCase.toSnakeCase('http'), 'http');
    });

    test('converts spaces to underscores', () {
      expect(StringCase.toSnakeCase('my module'), 'my_module');
    });

    test('converts dashes to underscores', () {
      expect(StringCase.toSnakeCase('my-module'), 'my_module');
    });

    test('handles empty string', () {
      expect(StringCase.toSnakeCase(''), '');
    });
  });

  group('StringCase.toPascalCase', () {
    test('converts snake_case to PascalCase', () {
      expect(StringCase.toPascalCase('user_profile'), 'UserProfile');
      expect(StringCase.toPascalCase('shared_preferences'), 'SharedPreferences');
    });

    test('handles single word', () {
      expect(StringCase.toPascalCase('login'), 'Login');
    });

    test('handles empty string', () {
      expect(StringCase.toPascalCase(''), '');
    });
  });

  group('StringCase round-trip', () {
    test('toSnakeCase(toCamelCase(x)) preserves snake_case input', () {
      const inputs = [
        'shared_preferences',
        'json_annotation',
        'http',
        'test',
        'my_module',
      ];

      for (final input in inputs) {
        expect(
          StringCase.toSnakeCase(StringCase.toCamelCase(input)),
          input,
          reason: 'Round-trip failed for: $input',
        );
      }
    });
  });
}
