import 'dart:io';

import 'logger.dart';

/// A utility class to handle file and directory operations.
///
/// Flutist 파일과 디렉토리 작업을 처리하는 유틸리티 클래스입니다.
class FileHelper {
  /// Creates a directory at the given path if it doesn't exist.
  /// 주어진 경로에 디렉토리를 생성합니다.
  static Future<void> createDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      Logger.info('Created directory: $path');
    }
  }

  /// Writes content to a file at the specified path.
  /// 주어진 경로에 파일을 생성하고 내용을 작성합니다.
  static Future<void> writeFile(String path, String content) async {
    final file = File(path);
    await file.writeAsString(content);
    Logger.success('Created file: $path');
  }
}
