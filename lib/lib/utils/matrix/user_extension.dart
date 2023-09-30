import 'package:matrix/matrix.dart';

extension UserExtension on User {
  String get powerLevelText {
    if (powerLevel == 0) {
      return "User";
    } else if (powerLevel == 100) {
      return "Admin";
    } else if (powerLevel == 50) {
      return "Moderator";
    }
    return "Custom";
  }
}
