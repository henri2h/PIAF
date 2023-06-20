import 'package:json_annotation/json_annotation.dart';
import 'package:matrix/matrix.dart';

import 'package:minestrix_chat/config/matrix_types.dart';

part 'event_poll_response.g.dart';

abstract class PollKind {
  static const String disclosed = "org.matrix.msc3381.poll.disclosed";
}

enum PollKindEnum {
  @JsonValue(PollKind.disclosed)
  disclosed
}

@JsonSerializable(explicitToJson: true)

/// A class to parse the poll response event content
class EventPollResponse {
  List<String>? answers = [];

  EventPollResponse();

  factory EventPollResponse.fromEvent(Event e) => _$EventPollResponseFromJson(
      e.content.tryGetMap(MatrixEventTypes.pollResponse) ?? {});
  Map<String, dynamic> toJson() => _$EventPollResponseToJson(this);
}
