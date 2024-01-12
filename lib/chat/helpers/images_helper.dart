import 'dart:typed_data';

import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:image/image.dart';

class ImagesHelper {
  static Future<BlurHash> createBlurHash(Uint8List file) async {
    final image = decodeImage(file)!;
    return BlurHash.encode(image, numCompX: 4, numCompY: 3);
  }
}
