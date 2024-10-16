import 'package:json_annotation/json_annotation.dart';
import 'package:matrix/matrix.dart';

part 'extensible_event_file.g.dart';

@JsonSerializable(includeIfNull: false)
class ExtensibleEventFile {
  ExtensibleEventFile();

  String? mimetype;
  String? name;
  String? url;
  int? size;

  // encryption parameters
  String? v;
  Map<String, dynamic>? key;
  String? iv;
  Map<String, dynamic>? hashes;

  Future<void> uploadFile(Room room, MatrixFile file) async {
    if (url != null) throw Exception("File already uploaded");

    MatrixFile uploadFile = file; // ignore: unused_local_variable

    if (room.encrypted && room.client.fileEncryptionEnabled) {
      EncryptedFile? encryptedFile;
      encryptedFile = await file.encrypt();
      uploadFile = encryptedFile.toMatrixFile();

      v = 'v2';
      key = {
        'alg': 'A256CTR',
        'ext': true,
        'k': encryptedFile.k,
        'key_ops': ['encrypt', 'decrypt'],
        'kty': 'oct'
      };
      iv = encryptedFile.iv;
      hashes = {'sha256': encryptedFile.sha256};
    }

    // set metadata

    name = file.name;
    size = file.size;
    mimetype = file.mimeType;

    url = (await room.client.uploadContent(
      uploadFile.bytes,
      filename: uploadFile.name,
      contentType: uploadFile.mimeType,
    ))
        .toString();
  }

  factory ExtensibleEventFile.fromJson(Map<String, dynamic> json) =>
      _$ExtensibleEventFileFromJson(json);
  Map<String, dynamic> toJson() => _$ExtensibleEventFileToJson(this);
}
