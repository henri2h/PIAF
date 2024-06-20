import 'package:json_annotation/json_annotation.dart';

import '../../../config/matrix_types.dart';

part 'extensible_event_image.g.dart';

@JsonSerializable(includeIfNull: false)
class ExtensibleEventImage {
  @JsonKey(name: "w")
  int? width;

  @JsonKey(name: "h")
  int? height;

  @JsonKey(name: MatrixTypes.blurhash)
  String? blurhash;

  ExtensibleEventImage();

  factory ExtensibleEventImage.fromJson(Map<String, dynamic> json) =>
      _$ExtensibleEventImageFromJson(json);
  Map<String, dynamic> toJson() => _$ExtensibleEventImageToJson(this);
}
