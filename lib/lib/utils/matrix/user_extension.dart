import 'package:matrix/matrix.dart';

extension UserExtension on User {
  String get powerLevelText {
    return powerLevel == 100 ? "admin" : "moderator";
  }
}
