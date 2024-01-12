// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extensible_event_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExtensibleEventFile _$ExtensibleEventFileFromJson(Map<String, dynamic> json) =>
    ExtensibleEventFile()
      ..mimetype = json['mimetype'] as String?
      ..name = json['name'] as String?
      ..url = json['url'] as String?
      ..size = json['size'] as int?
      ..v = json['v'] as String?
      ..key = json['key'] as Map<String, dynamic>?
      ..iv = json['iv'] as String?
      ..hashes = json['hashes'] as Map<String, dynamic>?;

Map<String, dynamic> _$ExtensibleEventFileToJson(ExtensibleEventFile instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('mimetype', instance.mimetype);
  writeNotNull('name', instance.name);
  writeNotNull('url', instance.url);
  writeNotNull('size', instance.size);
  writeNotNull('v', instance.v);
  writeNotNull('key', instance.key);
  writeNotNull('iv', instance.iv);
  writeNotNull('hashes', instance.hashes);
  return val;
}
