import 'dart:io';

import 'package:io/ansi.dart';

/// Utility class for logging messages to the terminal with colors.
class Logger {
  /// Prints a success message in green.
  static void success(String message) {
    print(green.wrap('✅ $message'));
  }

  /// Prints an error message in red to stderr.
  static void error(String message) {
    stderr.writeln(red.wrap('❌ [Error] $message'));
  }

  /// Prints an informational message in blue.
  static void info(String message) {
    print(blue.wrap('🔹 $message'));
  }

  /// Prints a warning message in yellow.
  static void warn(String message) {
    print(yellow.wrap('⚠️ $message'));
  }

  /// Prints the Flutist banner.
  static void banner() {
    print('''
╔══════════════════════════════════════════════════════════════╗
║                    Flutist CLI Tool                          ║
║         Flutter Workspace & Module Management                ║
╚══════════════════════════════════════════════════════════════╝
''');
  }
}
