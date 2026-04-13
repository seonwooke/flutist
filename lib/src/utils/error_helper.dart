import 'dart:io';

/// User-friendly error message helper.
class ErrorHelper {
  /// Returns a user-friendly description of [e] relative to [filePath].
  static String describe(Object e, String filePath) {
    if (e is FileSystemException) {
      return 'Cannot access $filePath — ${e.message}';
    }
    if (e is FormatException) {
      return 'Format error in $filePath — use multiline declarations (Flutist does not parse inline syntax)';
    }
    return e.toString();
  }
}
