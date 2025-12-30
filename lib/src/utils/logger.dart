import 'dart:io';

import 'package:io/ansi.dart';

/// A utility class for logging messages to the terminal with colors.
///
/// Flutist 로깅 유틸리티 클래스입니다.
class Logger {
  /// Prints a success message in green
  /// 초록색으로 성공 메시지를 출력합니다.
  static void success(String message) {
    print(green.wrap('✅ $message'));
  }

  /// Prints an error message in red to stderr.
  /// 빨간색으로 에러 메시지를 출력합니다.
  static void error(String message) {
    stderr.writeln(red.wrap('❌ Error: $message'));
  }

  /// Prints an informational message in blue.
  /// 파란색으로 정보 메시지를 출력합니다.
  static void info(String message) {
    print(blue.wrap('🔹 $message'));
  }

  /// Prints a warning message in yellow.
  /// 노란색으로 경고 메시지를 출력합니다.
  static void warn(String message) {
    print(yellow.wrap('⚠️ $message'));
  }
}
