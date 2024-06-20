// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_poll_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventPollResponse _$EventPollResponseFromJson(Map<String, dynamic> json) =>
    EventPollResponse()
      ..answers =
          (json['answers'] as List<dynamic>?)?.map((e) => e as String).toList();

Map<String, dynamic> _$EventPollResponseToJson(EventPollResponse instance) =>
    <String, dynamic>{
      'answers': instance.answers,
    };
