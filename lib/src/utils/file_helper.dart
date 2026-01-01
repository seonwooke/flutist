import 'dart:io';

import 'logger.dart';

/// Utility class for file and directory operations.
class FileHelper {
  /// Creates a directory at the given path if it doesn't exist.
  static Future<void> createDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      Logger.info('Created directory: $path');
    }
  }

  /// Writes content to a file at the specified path.
  static Future<void> writeFile(String path, String content) async {
    final file = File(path);
    await file.writeAsString(content);
    Logger.success('Created file: $path');
  }
}
