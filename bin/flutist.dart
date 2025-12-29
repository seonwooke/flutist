import 'package:flutist/flutist.dart';

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    // TODO: Print help message
  }

  final command = arguments[0];

  switch (command) {
    case 'init':
      // TODO:
      // tuist init
      // - arguments 길이가 2일 경우에는 두 번쨰 인자로 프로젝트 생성
      // - arguments 길이가 1일 경우에는 현재 path의 이름으로 프로젝트 초기화
      await InitCommand.run(arguments);
      break;
    case 'generate':
      // tuist generate
      // - project.dart 파일을 보고 모든 pubspec.yaml 파일을 업데이트
      // - package.dart 파일을 보고 패키지 generate 파일 생성
      await GenerateCommand.run(arguments);
      break;
    case 'create':
      // TODO:
      // tuist create --name <module_name> --path <path> --type <type>
      await CreateCommand.run(arguments);
      break;
    default:
      break;
  }
}
