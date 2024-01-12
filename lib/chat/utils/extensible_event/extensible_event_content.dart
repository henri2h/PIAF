import 'package:json_annotation/json_annotation.dart';
import 'package:matrix/matrix.dart';

import 'package:minestrix/chat/config/extensible_types.dart';
import 'extensible_event_file.dart';
import 'extensible_event_image.dart';

part 'extensible_event_content.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class ExtensibleEventContent {
  @JsonKey(name: ExtensibleTypes.text, defaultValue: "")
  String text = "";

// legacy body text
  @JsonKey(name: "body", defaultValue: "")
  String body = "";

  @JsonKey(name: ExtensibleTypes.html)
  String? html;

  @JsonKey(name: ExtensibleTypes.file)
  ExtensibleEventFile? file;

  @JsonKey(name: ExtensibleTypes.image)
  ExtensibleEventImage? image;

  @JsonKey(name: ExtensibleTypes.thumbnail_file)
  ExtensibleEventFile? thumbnailFile;

  @JsonKey(name: ExtensibleTypes.thumbnail_info)
  ExtensibleEventImage? thumbnailInfo;

  @JsonKey(name: ExtensibleTypes.caption)
  List<ExtensibleEventContent>? caption;

  Future<void> uploadFile(
      {required Room room, required MatrixFile matrixFile}) async {
    file = ExtensibleEventFile();
    await file!.uploadFile(room, matrixFile);
  }

  Future<void> uploadImage(
      {required Room room,
      required MatrixImageFile matrixFile,
      MatrixImageFile? matrixThumbnail}) async {
    // initialize the data
    file = ExtensibleEventFile();
    await file!.uploadFile(room, matrixFile);

    image = ExtensibleEventImage();
    image!.width = matrixFile.width;
    image!.height = matrixFile.height;
    image!.blurhash = matrixFile.blurhash;

    if (matrixThumbnail != null) {
      thumbnailFile = ExtensibleEventFile();
      thumbnailFile!.uploadFile(room, matrixThumbnail);

      thumbnailInfo = ExtensibleEventImage();

      thumbnailInfo!.width = matrixThumbnail.width;
      thumbnailInfo!.height = matrixThumbnail.height;
      thumbnailInfo!.blurhash = matrixThumbnail.blurhash;
    }
  }

  ExtensibleEventContent();

  factory ExtensibleEventContent.fromJson(Map<String, dynamic> json) =>
      _$ExtensibleEventContentFromJson(json);
  Map<String, dynamic> toJson() => _$ExtensibleEventContentToJson(this);
}
