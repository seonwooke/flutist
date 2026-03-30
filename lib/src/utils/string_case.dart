/// Utility class for string case conversions.
class StringCase {
  /// Converts snake_case to camelCase.
  ///
  /// Examples:
  /// - shared_preferences → sharedPreferences
  /// - json_annotation → jsonAnnotation
  static String toCamelCase(String input) {
    final parts = input.split('_');
    if (parts.length == 1) return input;

    final first = parts.first;
    final rest = parts.skip(1).map((part) {
      if (part.isEmpty) return part;
      return part[0].toUpperCase() + part.substring(1).toLowerCase();
    });

    return first + rest.join('');
  }

  /// Converts any string to snake_case.
  ///
  /// Examples:
  /// - sharedPreferences → shared_preferences
  /// - UserProfile → user_profile
  static String toSnakeCase(String input) {
    var result = input.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );

    if (result.startsWith('_')) {
      result = result.substring(1);
    }

    result = result.replaceAll(' ', '_').replaceAll('-', '_');

    return result.toLowerCase();
  }

  /// Converts snake_case to PascalCase.
  ///
  /// Examples:
  /// - user_profile → UserProfile
  /// - login → Login
  static String toPascalCase(String input) {
    final parts = input.split('_');
    return parts.map((part) {
      if (part.isEmpty) return part;
      return part[0].toUpperCase() + part.substring(1).toLowerCase();
    }).join('');
  }
}
