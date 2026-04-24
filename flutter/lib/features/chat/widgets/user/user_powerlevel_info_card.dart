import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/utils/matrix/user_extension.dart';

class UserPowerLevelInfoCard extends StatelessWidget {
  const UserPowerLevelInfoCard({
    super.key,
    required this.user,
  });

  final User user;

  @override
  Widget build(BuildContext context) {
    if ([50, 100].contains(user.powerLevel)) {
      return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Text(user.powerLevelText,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
          ));
    }
    return Container(width: 0);
  }
}
