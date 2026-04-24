// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extensible_event_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExtensibleEventContent _$ExtensibleEventContentFromJson(
        Map<String, dynamic> json) =>
    ExtensibleEventContent()
      ..text = json['org.matrix.msc1767.text'] as String? ?? ''
      ..body = json['body'] as String? ?? ''
      ..html = json['org.matrix.msc1767.html'] as String?
      ..file = json['org.matrix.msc1767.file'] == null
          ? null
          : ExtensibleEventFile.fromJson(
              json['org.matrix.msc1767.file'] as Map<String, dynamic>)
      ..image = json['org.matrix.msc1767.image'] == null
          ? null
          : ExtensibleEventImage.fromJson(
              json['org.matrix.msc1767.image'] as Map<String, dynamic>)
      ..thumbnailFile = json['org.matrix.msc1767.thumbnail_file'] == null
          ? null
          : ExtensibleEventFile.fromJson(
              json['org.matrix.msc1767.thumbnail_file'] as Map<String, dynamic>)
      ..thumbnailInfo = json['org.matrix.msc1767.thumbnail_info'] == null
          ? null
          : ExtensibleEventImage.fromJson(
              json['org.matrix.msc1767.thumbnail_info'] as Map<String, dynamic>)
      ..caption = (json['org.matrix.msc1767.caption'] as List<dynamic>?)
          ?.map(
              (e) => ExtensibleEventContent.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$ExtensibleEventContentToJson(
    ExtensibleEventContent instance) {
  final val = <String, dynamic>{
    'org.matrix.msc1767.text': instance.text,
    'body': instance.body,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('org.matrix.msc1767.html', instance.html);
  writeNotNull('org.matrix.msc1767.file', instance.file?.toJson());
  writeNotNull('org.matrix.msc1767.image', instance.image?.toJson());
  writeNotNull(
      'org.matrix.msc1767.thumbnail_file', instance.thumbnailFile?.toJson());
  writeNotNull(
      'org.matrix.msc1767.thumbnail_info', instance.thumbnailInfo?.toJson());
  writeNotNull('org.matrix.msc1767.caption',
      instance.caption?.map((e) => e.toJson()).toList());
  return val;
}
