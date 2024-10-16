import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../../../../partials/dialogs/adaptative_dialogs.dart';
import '../../../../partials/matrix/matrix_image_avatar.dart';
import '../../widgets/settings/conv_settings_users.dart';

class RoomParticipantsIndicator extends StatelessWidget {
  const RoomParticipantsIndicator({
    super.key,
    required this.room,
  });

  final Room room;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(future: () async {
      if (room.getParticipants().length < 8 && !room.participantListComplete) {
        await room.requestParticipants();
      }
      return true;
    }(), builder: (context, snap) {
      final participants = room.getParticipants();
      final participantsLimited = participants.take(8).toList();
      final more = participants.length != participantsLimited.length;
      return GestureDetector(
        onTap: () {
          AdaptativeDialogs.show(
              context: context,
              title: "Users",
              builder: (context) => ConvSettingsUsers(
                    room: room,
                  ));
        },
        child: participants.isEmpty
            ? const Text("No participants")
            : Stack(
                children: [
                  for (final user in participantsLimited)
                    Transform(
                      transform: Matrix4.identity()
                        ..translate(
                          30.0 * participantsLimited.indexOf(user),
                          0.0,
                          0.0,
                        ),
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).cardColor,
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: MatrixImageAvatar(
                            client: room.client,
                            url: user.avatarUrl,
                            defaultText: user.calcDisplayname(),
                          ),
                        ),
                      ),
                    ),
                  if (more)
                    Transform(
                      transform: Matrix4.identity()
                        ..translate(
                          30.0 * participantsLimited.length,
                          0.0,
                          0.0,
                        ),
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).cardColor,
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            child: const Icon(Icons.more_horiz),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      );
    });
  }
}
