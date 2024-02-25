import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:piaf/chat/utils/poll/json/event_poll_start.dart';
import 'package:piaf/chat/utils/poll/poll.dart';

class PollWidget extends StatefulWidget {
  final Event event;
  final Timeline timeline;
  const PollWidget({super.key, required this.event, required this.timeline});

  @override
  PollWidgetState createState() => PollWidgetState();
}

class PollWidgetState extends State<PollWidget> {
  late Poll poll;
  @override
  void initState() {
    super.initState();
    poll = Poll(e: widget.event, t: widget.timeline);
  }

  @override
  Widget build(BuildContext context) {
    EventPollStart start = poll.poll;
    bool isEnded = poll.isEnded;
    Map<String, int> responses = poll.responsesMap;

    // get the value wich get the max of responses
    int max = 0;
    List<String> maxValues = [];

    // get the max value only on poll end
    if (isEnded && responses.isNotEmpty) {
      for (var entry in responses.entries) {
        if (entry.value > max) {
          max = entry.value;
          maxValues = [entry.key];
        } else if (entry.value == max) {
          maxValues.add(entry.key);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.poll, size: 24),
              const SizedBox(width: 6),
              Text(start.question?.text ?? "",
                  style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
        for (PollAnswer answer in start.answers ?? [])
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: isEnded && maxValues.contains(answer.id)
                      ? const BorderSide(color: Colors.green)
                      : BorderSide.none),
              child: RadioListTile<String>(
                  groupValue: poll.userResponse?.answers?.isNotEmpty == true
                      ? poll.userResponse?.answers?.first
                      : "",
                  value: answer.id,
                  onChanged: (value) async {
                    await poll.answer(value);
                  },
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(answer.text ?? ""),
                      Row(
                        children: [
                          if (isEnded && maxValues.contains(answer.id))
                            const Padding(
                              padding: EdgeInsets.only(right: 4.0),
                              child: Icon(Icons.celebration,
                                  color: Colors.green, size: 18),
                            ),
                          Text(
                              (responses[answer.id] ?? 0).toString() +
                                  ((responses[answer.id] ?? 0) < 2
                                      ? " vote"
                                      : " votes"),
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.normal)),
                        ],
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: LinearProgressIndicator(
                            color: Colors.green,
                            minHeight: 6,
                            value: (responses[answer.id] ?? 0) /
                                (responses.isNotEmpty
                                    ? responses.length
                                    : 1)), // prevent division by zero
                      )
                    ],
                  )),
            ),
          ),
        if (isEnded)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Final result based on ${responses.length} votes",
                style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }
}
