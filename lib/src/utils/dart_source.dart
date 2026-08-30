/// Helpers for reading the hand-written Dart declaration files
/// (`project.dart`, `package.dart`) that Flutist parses textually.
class DartSource {
  /// Blanks out `//` line comments, replacing them with spaces so the result
  /// has the same length and line structure as [content].
  ///
  /// Preserving offsets is what lets a caller locate a declaration in the
  /// masked text and then cut it out of the original. Commented-out
  /// declarations are invisible to the search, which matters because the
  /// `init` templates ship examples behind `//` and users leave old entries
  /// commented while experimenting.
  ///
  /// A `//` inside a string literal is left intact, so git URLs such as
  /// `url: 'https://github.com/acme/a.git'` survive.
  ///
  /// Block comments (`/* ... */`) are not handled.
  static String maskLineComments(String content) {
    return content.split('\n').map(_maskLine).join('\n');
  }

  static String _maskLine(String line) {
    String? quote;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (quote != null) {
        if (char == r'\') {
          i++; // skip the escaped character
        } else if (char == quote) {
          quote = null;
        }
        continue;
      }

      if (char == "'" || char == '"') {
        quote = char;
      } else if (char == '/' && i + 1 < line.length && line[i + 1] == '/') {
        return line.substring(0, i) + ' ' * (line.length - i);
      }
    }

    return line;
  }
}
