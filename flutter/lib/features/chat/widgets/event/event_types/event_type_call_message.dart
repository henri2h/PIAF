import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:piaf/utils/date_time_extension.dart';

import '../../../../../partials/matrix/matrix_user_avatar.dart';

class EventTypeCallMessage extends StatelessWidget {
  const EventTypeCallMessage(this.event, {super.key, required this.timeline});

  final Event event;
  final Timeline? timeline;

  @override
  Widget build(BuildContext context) {
    if (timeline == null) return const Text("call event");
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Builder(builder: (context) {
        final e = timeline!.events.where((element) =>
            element.type != EventTypes.CallInvite &&
            element.content.tryGet("call_id") ==
                event.content.tryGet("call_id"));

        final myUserId = event.room.client.userID;
        final callMade = event.senderId == myUserId;

        final answers =
            e.where((element) => element.type == EventTypes.CallAnswer);

        final answer = answers
            .where((element) => element.senderId == myUserId)
            .firstOrNull;
        final answerFromOthers =
            answers.where((element) => element.senderId != myUserId);

        final hangup = e
            .where((element) =>
                element.type == EventTypes.CallHangup &&
                element.senderId == myUserId)
            .firstOrNull;
        final senderHangup = e
            .where((element) =>
                element.type == EventTypes.CallHangup &&
                element.senderId != myUserId)
            .firstOrNull;

        final reject = e
            .where((element) =>
                element.type == EventTypes.CallReject &&
                element.senderId == myUserId)
            .firstOrNull;

        Icon icon = const Icon(Icons.call);
        String text = "Call made";

        if (answer != null &&
            (hangup != null ||
                (event.room.summary.mJoinedMemberCount == 2 &&
                    senderHangup != null))) {
          // either we hangup or the other user hanged up
          icon = const Icon(Icons.call_end);
          if (callMade && answerFromOthers.isEmpty) {
            text = "No answers";
          } else {
            final start =
                (callMade ? event.originServerTs : answer.originServerTs);
            final h =
                hangup ?? senderHangup; // Event of the first hangup of the call

            final duration = h!.originServerTs.difference(start);
            text = "Call duration ${duration.toShortString}";
          }
        } else if (reject != null) {
          icon = const Icon(Icons.call_end, color: Colors.red);
          text = "You rejected the call";
        } else if (answer != null || callMade) {
          icon = const Icon(Icons.call, color: Colors.green);
          text = callMade ? "You started the call" : "In the call";
        } else if (event.room.summary.mJoinedMemberCount == 2 && !callMade) {
          if (answer == null && hangup == null) {
            // we didn't answered

            // we missed the call
            if (senderHangup != null) {
              icon = const Icon(Icons.phone_missed, color: Colors.red);
              text = "Call missed";
            }
          }
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            children: [
              ListTile(
                leading: MatrixUserAvatar.fromUser(
                    event.senderFromMemoryOrFallback,
                    client: event.room.client),
                title: Text(event.senderFromMemoryOrFallback.calcDisplayname()),
                subtitle: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(event.originServerTs.timeSinceAWeekOrDuration),
                    if (text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    if (text.isNotEmpty) Text(text)
                  ],
                ),
                trailing: icon,
              ),
            ],
          ),
        );
      }),
    ));
  }
}
