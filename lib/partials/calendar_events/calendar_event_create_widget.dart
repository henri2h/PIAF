import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:minestrix_chat/minestrix_chat.dart';
import 'package:minestrix_chat/partials/dialogs/adaptative_dialogs.dart';
import 'package:minestrix_chat/utils/extensions/minestrix/model/calendar_event_model.dart';
import 'package:minestrix_chat/utils/matrix_widget.dart';

import '../components/buttons/custom_future_button.dart';
import 'calendar_text_field.dart';
import 'datetime_card.dart';

class CalendarEventCreateWidget extends StatelessWidget {
  const CalendarEventCreateWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // when room == null, EditCalendarRoom create a room
    return const EditCalendarRoom(room: null);
  }

  static Future<void> show(BuildContext context) async {
    await AdaptativeDialogs.show(
        title: "Create event",
        context: context,
        builder: (context) => const EditCalendarRoom(room: null));
  }
}

class EditCalendarRoom extends StatefulWidget {
  const EditCalendarRoom({Key? key, required this.room}) : super(key: key);
  final Room? room;

  @override
  State<EditCalendarRoom> createState() => _EditCalendarRoomState();
}

class _EditCalendarRoomState extends State<EditCalendarRoom> {
  late DateTime startDate;
  late DateTime endDate;

  final nameController = TextEditingController();
  final topicController = TextEditingController();
  final placeController = TextEditingController();

  CalendarEvent? calendarEvent;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.room?.name ?? '';
    topicController.text = widget.room?.topic ?? '';

    calendarEvent = widget.room?.getEventAttendanceEvent();
    startDate = calendarEvent?.start ?? DateTime.now();
    endDate = calendarEvent?.end ?? DateTime.now();
    placeController.text = calendarEvent?.place ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CreateCalendarTextField(
          text: "Event name",
          icon: const Icon(Icons.event),
          controller: nameController,
        ),
        CreateCalendarTextField(
          text: "Event description",
          controller: topicController,
          icon: const Icon(Icons.edit),
          minLines: 3,
          maxLines: null,
        ),
        DateTimeCard(
          date: startDate,
          setTime: (DateTime result) {
            setState(() {
              startDate = result;

              if (endDate.difference(startDate).isNegative) {
                endDate = result;
              }
            });
          },
        ),
        ExpansionTile(
            title: const Text(
              "End date",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
            ),
            children: [
              DateTimeCard(
                  date: endDate,
                  setTime: (DateTime result) {
                    setState(() {
                      endDate = result;

                      if (endDate.difference(startDate).isNegative) {
                        startDate = result;
                      }
                    });
                  }),
            ]),
        CreateCalendarTextField(
          text: "Place",
          icon: const Icon(Icons.location_on),
          controller: placeController,
        ),
        Padding(
          padding:
              const EdgeInsets.only(left: 8.0, right: 8, bottom: 8, top: 40),
          child: CustomFutureButton(
            color: Theme.of(context).primaryColor,
            onPressed: () async {
              if (nameController.text.isEmpty) {
                await showOkAlertDialog(
                    context: context,
                    title: "Form invalid",
                    message: "Name cannot be empty.");
                return;
              }

              final client = Matrix.of(context).client;

              final room = widget.room ??
                  await client.createCalendarEventRoom(client,
                      name: nameController.text, topic: topicController.text);

              if (room != null) {
                if (widget.room != null) {
                  await room.waitForRoomInSync();
                }
                if (calendarEvent == null) {
                  await room.postLoad();
                  calendarEvent = room.getEventAttendanceEvent();
                }
                calendarEvent?.start = startDate;
                calendarEvent?.end = endDate;
                calendarEvent?.place = placeController.text;

                if (calendarEvent != null) {
                  room.sendCalendarEventState(calendarEvent!);
                }
              }
              if (mounted) Navigator.of(context).pop();
            },
            children: [
              Center(
                  child: Text(
                widget.room == null ? "Create" : "Edit",
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 17),
              ))
            ],
          ),
        ),
      ],
    );
  }
}
