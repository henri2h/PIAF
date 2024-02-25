import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/chat/utils/matrix/user_extension.dart';

class UserPowerLevelInfoCard extends StatelessWidget {
  const UserPowerLevelInfoCard({
    super.key,
    required this.user,
  });

  final User user;

  @override
  Widget build(BuildContext context) {
    if ([50, 100].contains(user.powerLevel)) {
      return Card(
          child: Padding(
        padding: const EdgeInsets.all(4),
        child: Text(user.powerLevelText),
      ));
    }
    return Container(width: 0);
  }
}
