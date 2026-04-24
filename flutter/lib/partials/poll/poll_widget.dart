import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

class PollWidget extends StatefulWidget {
  final Event event;
  final Timeline timeline;
  const PollWidget({super.key, required this.event, required this.timeline});

  @override
  PollWidgetState createState() => PollWidgetState();
}

class PollWidgetState extends State<PollWidget> {
  late PollEventContent poll;
  @override
  void initState() {
    super.initState();
    poll = widget.event.parsedPollEventContent;
  }

  @override
  Widget build(BuildContext context) {
    var start = poll.pollStartContent;
    var isEnded = widget.event.getPollHasBeenEnded(widget.timeline);
    var responses = widget.event.getPollResponses(widget.timeline);

    // get the value wich get the max of responses
    List<String> maxValues = [];

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
              Text(start.question.mText, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
        for (var answer in start.answers)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: isEnded && maxValues.contains(answer.id)
                      ? const BorderSide(color: Colors.green)
                      : BorderSide.none),
              child: RadioListTile<String>(
                  value: answer.id,
                  onChanged: (value) async {
                    // await poll.answer(value);
                  },
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(answer.mText),
                      Row(
                        children: [
                          if (isEnded && maxValues.contains(answer.id))
                            const Padding(
                              padding: EdgeInsets.only(right: 4.0),
                              child: Icon(Icons.celebration,
                                  color: Colors.green, size: 18),
                            ),
                          Text("${responses[answer.id] ?? 0} votes",
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
                            value: ((responses[answer.id]?.length ?? 0) *
                                1.0)), // prevent division by zero
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
