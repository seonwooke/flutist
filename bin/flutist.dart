import 'package:args/args.dart';
import 'package:flutist/flutist.dart';

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    // TODO: Print help message
  }

  try {
    final ArgParser parser = ArgParser();
    final argResults = parser.parse(arguments);
    final commandName = argResults.arguments[0];

    switch (commandName) {
      case 'init':
        // TODO:
        // tuist init
        // - arguments 길이가 2일 경우에는 두 번쨰 인자로 프로젝트 생성
        // - arguments 길이가 1일 경우에는 현재 path의 이름으로 프로젝트 초기화
        InitCommand().execute(argResults);
        break;
      case 'generate':
        // tuist generate
        // - project.dart 파일을 보고 모든 pubspec.yaml 파일을 업데이트
        // - package.dart 파일을 보고 패키지 generate 파일 생성
        GenerateCommand().execute(argResults);
        break;
      case 'create':
        // TODO:
        // tuist create --name <module_name> --path <path> --type <type>
        CreateCommand().execute(argResults);
        break;
      default:
        break;
    }
  } catch (e) {}
}
