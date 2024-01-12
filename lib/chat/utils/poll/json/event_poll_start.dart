import 'package:json_annotation/json_annotation.dart';
import 'package:matrix/matrix.dart';

import 'package:minestrix/chat/config/extensible_types.dart';
import 'package:minestrix/chat/config/matrix_types.dart';
import 'package:minestrix/chat/utils/extensible_event/extensible_event_content.dart';

part 'event_poll_start.g.dart';

abstract class PollKind {
  static const String disclosed = "org.matrix.msc3381.poll.disclosed";
  static const String undisclosed = "org.matrix.msc3381.poll.undisclosed";
}

enum PollKindEnum {
  @JsonValue(PollKind.disclosed)
  disclosed,
  @JsonValue(PollKind.undisclosed)
  undisclosed
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)

/// A class to parse the poll start event content
class EventPollStart {
  PollKindEnum? kind;
  ExtensibleEventContent? question;

  @JsonKey(name: ExtensibleTypes.message)
  List<ExtensibleEventContent>? message;

  List<PollAnswer>? answers = [];

  @JsonKey(name: "max_selections")
  int? maxSelections;

  EventPollStart();

  factory EventPollStart.fromEvent(Event e) => _$EventPollStartFromJson(
      e.content.tryGetMap(MatrixEventTypes.pollStart) ?? {});
  Map<String, dynamic> toJson() => _$EventPollStartToJson(this);
}

@JsonSerializable()
class PollAnswer {
  String id = "";

  @JsonKey(name: ExtensibleTypes.text)
  String? text;

  PollAnswer();

  factory PollAnswer.fromJson(Map<String, dynamic> json) =>
      _$PollAnswerFromJson(json);
  Map<String, dynamic> toJson() => _$PollAnswerToJson(this);
}
