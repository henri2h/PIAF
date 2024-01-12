// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extensible_event_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExtensibleEventImage _$ExtensibleEventImageFromJson(
        Map<String, dynamic> json) =>
    ExtensibleEventImage()
      ..width = json['w'] as int?
      ..height = json['h'] as int?
      ..blurhash = json['xyz.amorgan.blurhash'] as String?;

Map<String, dynamic> _$ExtensibleEventImageToJson(
    ExtensibleEventImage instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('w', instance.width);
  writeNotNull('h', instance.height);
  writeNotNull('xyz.amorgan.blurhash', instance.blurhash);
  return val;
}
