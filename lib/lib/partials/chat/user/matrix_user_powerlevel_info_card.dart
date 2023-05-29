import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/utils/matrix/user_extension.dart';

class MatrixUserPowerLevelInfoCard extends StatelessWidget {
  const MatrixUserPowerLevelInfoCard({
    Key? key,
    required this.user,
  }) : super(key: key);

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
