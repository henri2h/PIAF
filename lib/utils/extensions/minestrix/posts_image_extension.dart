import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';

import '../../extensible_event/extensible_event_file.dart';
import '../../extensible_event/extensible_event_image.dart';

extension PostImageExtension on Room {
  /// Downloads (and decrypts if necessary) the attachment of this
  /// post and returns it as a [MatrixFile]. If this event doesn't
  /// contain an attachment, this throws an error. Set [getThumbnailIfUnencrypted] to
  /// true to download the thumbnail instead.
  Future<MatrixFile> downloadAndDecryptPostAttachment(
      {required ExtensibleEventFile file,
      required ExtensibleEventImage image,
      bool getThumbnailIfUnencrypted = false,
      int width = 600,
      int height = 600,
      bool animated = true,
      required String body,
      Future<Uint8List> Function(Uri)? downloadCallback}) async {
    final database = client.database;

    if (file.url == null) {
      throw "This event hasn't any attachment or thumbnail.";
    }

    Uri? mxcUrl = Uri.tryParse(file.url!);

    if (mxcUrl == null) {
      throw "This event attachment is invalid.";
    }

    final isEncrypted = file.key != null;
    if (isEncrypted && !client.encryptionEnabled) {
      throw ('Encryption is not enabled in your Client.');
    }

    // Is this file storeable?
    var storeable = database != null &&
        file.size != null &&
        file.size! <= database.maxFileSize;

    Uint8List? uint8list;
    if (storeable) {
      uint8list = await client.database?.getFile(mxcUrl);
    }

    // Download the file
    if (uint8list == null) {
      if (getThumbnailIfUnencrypted && !isEncrypted) {
        mxcUrl = mxcUrl.getThumbnail(client,
            width: width,
            height: height,
            method: ThumbnailMethod.scale,
            animated: animated);
      }

      downloadCallback ??= (Uri url) async => (await http.get(url)).bodyBytes;
      uint8list = await downloadCallback(mxcUrl.getDownloadLink(client));

      storeable = database != null &&
          storeable &&
          uint8list.lengthInBytes < database.maxFileSize;
      if (storeable) {
        await database.storeFile(
            mxcUrl, uint8list, DateTime.now().millisecondsSinceEpoch);
      }
    }

    // Decrypt the file
    if (isEncrypted) {
      if (!file.key!['key_ops'].contains('decrypt')) {
        throw ("Missing 'decrypt' in 'key_ops'.");
      }
      final encryptedFile = EncryptedFile(
        data: uint8list,
        iv: file.iv ?? '',
        k: file.key!['k'],
        sha256: file.hashes!['sha256'],
      );
      uint8list = await client.nativeImplementations.decryptFile(encryptedFile);
      if (uint8list == null) {
        throw ('Unable to decrypt file');
      }
    }
    return MatrixFile(bytes: uint8list, name: body);
  }
}
