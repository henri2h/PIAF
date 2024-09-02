import 'dart:typed_data';

import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image/image.dart' as img;
import 'package:matrix/matrix.dart';
import 'package:piaf/partials/dialogs/adaptative_dialogs.dart';
import 'package:piaf/partials/utils/matrix_sdk_extension/matrix_file_extension.dart';
import 'package:shimmer/shimmer.dart';

import '../chat_components/shimmer_widget.dart';

class MImageViewer extends StatelessWidget {
  const MImageViewer(
      {super.key,
      required this.event,
      this.fit = BoxFit.contain,
      this.imageWidth,
      this.imageHeight});

  final BoxFit fit;
  final Event event;

  final int? imageWidth;
  final int? imageHeight;

  Future<void> saveImage(BuildContext context) async {
    final file = await event.downloadAndDecryptAttachment(
      downloadCallback: (Uri url) async {
        final file = await DefaultCacheManager().getSingleFile(url.toString());
        return await file.readAsBytes();
      },
    );
    if (context.mounted) {
      file.save(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AdaptativeDialogs.show(
            context: context,
            title: "Image display ${event.body}",
            actions: [
              IconButton(
                  onPressed: () => saveImage(context),
                  icon: const Icon(Icons.download)),
            ],
            builder: (context) => InteractiveViewer(
                minScale: 0.01,
                maxScale: 4,
                child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: MatrixImage(
                        event: event,
                        getThumbnail: false,
                        fit: BoxFit.contain,
                        key: Key("img_full_${event.eventId}")))));
      },
      child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: MatrixImage(
            event: event,
            fit: fit,
            imageHeight: imageHeight,
            imageWidth: imageWidth,
            key: Key("img_${event.eventId}"),
          )),
    );
  }
}

class MatrixImage extends StatefulWidget {
  final Room? room;
  final Event event;
  final bool highRes;
  final bool getThumbnail;

  final BoxFit fit;
  final BorderRadius? borderRadius;
  final int? imageWidth;
  final int? imageHeight;

  const MatrixImage(
      {super.key,
      required this.event,
      this.room,
      this.fit = BoxFit.contain,
      this.borderRadius,
      this.highRes = false,
      this.imageHeight,
      this.imageWidth,
      this.getThumbnail = true});

  @override
  State<MatrixImage> createState() => _MatrixImageState();
}

class _MatrixImageState extends State<MatrixImage> {
  Event get event => widget.event;
  Room get room => widget.room ?? event.room;
  bool get getThumbnail => widget.getThumbnail;

  Future<MatrixFile>? futureFile;
  Uint8List? blurhashImage;
  String blurHashString = 'LEHV6nWB2yk8pyo0adR*.7kCMdnj';

  double? ratio;

  int width = 400;
  int height = 400;

  @override
  void initState() {
    ratio = event.infoMap['w'] is int && event.infoMap['h'] is int
        ? event.infoMap['w'] / event.infoMap['h']
        : null;

    if (!getThumbnail &&
        event.infoMap['w'] is int &&
        event.infoMap['h'] is int) {
      width = event.infoMap['w'];
      height = event.infoMap['h'];
    }

    if (event.infoMap['xyz.amorgan.blurhash'] is String) {
      blurHashString = event.infoMap['xyz.amorgan.blurhash'];
    }

    ratio = ratio ?? 1.0;

    if (ratio! > 1.0) {
      height = (width / ratio!).round();
    } else {
      width = (height * ratio!).round();
    }

    futureFile = event.downloadAndDecryptAttachment(
      getThumbnail: getThumbnail,
      downloadCallback: (Uri url) async {
        final file = await DefaultCacheManager().getSingleFile(url.toString());
        return await file.readAsBytes();
      },
    );

    super.initState();
  }

  Uint8List? getBlurHashImage() {
    if (blurhashImage != null) return blurhashImage;

    var width = this.width;
    var height = this.height;
    if (width > height) {
      width = 32;
      height = (width / ratio!).round();
    } else {
      height = 32;
      width = (height * ratio!).round();
    }

    try {
      blurhashImage = Uint8List.fromList(img
          .encodeJpg(BlurHash.decode(blurHashString).toImage(width, height)));
    } catch (e) {
      Logs().e("Could not calculate hash", e);
    }

    return blurhashImage;
  }

  @override
  Widget build(BuildContext context) {
    final image = FutureBuilder<MatrixFile>(
      future: futureFile,
      builder: (BuildContext context, AsyncSnapshot<MatrixFile> file) {
        if (file.hasData) {
          return Image.memory(file.data!.bytes,
              fit: widget.fit, cacheWidth: widget.imageWidth ?? width);
        }
        var blurhashImage = getBlurHashImage();
        if (blurhashImage != null) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(blurhashImage,
                  fit: widget.fit, cacheWidth: widget.imageWidth ?? width),
              Center(
                child: Shimmer.fromColors(
                  baseColor: Colors.transparent,
                  highlightColor: Colors.grey.withAlpha(40),
                  child: widget.fit == BoxFit.cover || ratio == null
                      ? Container(color: Colors.white)
                      : AspectRatio(
                          aspectRatio: ratio!,
                          child: Container(color: Colors.white)),
                ),
              ),
            ],
          );
        }

        return Center(
          child: ShimmerWidget(
            child: widget.fit == BoxFit.cover || ratio == null
                ? Container(color: Colors.white)
                : AspectRatio(
                    aspectRatio: ratio!, child: Container(color: Colors.white)),
          ),
        );
      },
    );

    if (widget.fit == BoxFit.cover) return image;
    return ratio != null
        ? AspectRatio(aspectRatio: ratio!, child: image)
        : image;
  }
}
