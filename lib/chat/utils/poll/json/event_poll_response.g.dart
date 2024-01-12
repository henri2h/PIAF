// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_poll_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventPollResponse _$EventPollResponseFromJson(Map<String, dynamic> json) =>
    EventPollResponse()
      ..answers =
          (json['answers'] as List<dynamic>?)?.map((e) => e as String).toList();

Map<String, dynamic> _$EventPollResponseToJson(EventPollResponse instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('answers', instance.answers);
  return val;
}
