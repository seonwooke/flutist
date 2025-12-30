import 'package:args/args.dart';

/// The base interface for all Flutist CLI commands.
///
/// Flutist 명령어의 기본 인터페이스입니다.
abstract class BaseCommand {
  /// The name of the command (e.g., 'init').
  /// 명령어의 이름 (예: 'init').
  String get name;

  /// A brief description of what the command does.
  /// 명령어의 설명.
  String get description;

  /// Executes the command with the given parsed arguments.
  /// 주어진 파싱된 인자로 명령어를 실행합니다.
  void execute(ArgResults arguments);
}
