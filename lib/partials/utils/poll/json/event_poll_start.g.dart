// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_poll_start.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventPollStart _$EventPollStartFromJson(Map<String, dynamic> json) =>
    EventPollStart()
      ..kind = $enumDecodeNullable(_$PollKindEnumEnumMap, json['kind'])
      ..question = json['question'] == null
          ? null
          : ExtensibleEventContent.fromJson(
              json['question'] as Map<String, dynamic>)
      ..message = (json['org.matrix.msc1767.message'] as List<dynamic>?)
          ?.map(
              (e) => ExtensibleEventContent.fromJson(e as Map<String, dynamic>))
          .toList()
      ..answers = (json['answers'] as List<dynamic>?)
          ?.map((e) => PollAnswer.fromJson(e as Map<String, dynamic>))
          .toList()
      ..maxSelections = (json['max_selections'] as num?)?.toInt();

Map<String, dynamic> _$EventPollStartToJson(EventPollStart instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('kind', _$PollKindEnumEnumMap[instance.kind]);
  writeNotNull('question', instance.question?.toJson());
  writeNotNull('org.matrix.msc1767.message',
      instance.message?.map((e) => e.toJson()).toList());
  writeNotNull('answers', instance.answers?.map((e) => e.toJson()).toList());
  writeNotNull('max_selections', instance.maxSelections);
  return val;
}

const _$PollKindEnumEnumMap = {
  PollKindEnum.disclosed: 'org.matrix.msc3381.poll.disclosed',
  PollKindEnum.undisclosed: 'org.matrix.msc3381.poll.undisclosed',
};

PollAnswer _$PollAnswerFromJson(Map<String, dynamic> json) => PollAnswer()
  ..id = json['id'] as String
  ..text = json['org.matrix.msc1767.text'] as String?;

Map<String, dynamic> _$PollAnswerToJson(PollAnswer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'org.matrix.msc1767.text': instance.text,
    };
