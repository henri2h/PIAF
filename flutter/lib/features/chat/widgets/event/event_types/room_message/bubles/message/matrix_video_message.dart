import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:matrix/matrix.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:piaf/utils/matrix_sdk_extension/matrix_file_extension.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

class MatrixVideoMessage extends StatefulWidget {
  const MatrixVideoMessage(this.event, {super.key});

  final Event event;

  @override
  State<MatrixVideoMessage> createState() => _MatrixVideoMessageState();
}

class _MatrixVideoMessageState extends State<MatrixVideoMessage> {
  bool get isDesktop => Platform.isLinux || Platform.isWindows;

  MatrixFile? file;

  Future<File>? decryptedFile;
  Directory? temporaryDirectory;
  List<File> temporaryFiles = [];

  ChewieController? chewieController;
  VideoPlayerController? videoPlayerController;

  Future<void> dowloadAttachement() async {
    if (file == null) await getFile();
    if (mounted) {
      file?.save(context);
    }
  }

  Future<bool>? mobileFuture;

  @override
  void initState() {
    super.initState();

    if (!widget.event.isAttachmentEncrypted && !isDesktop) {
      mobileFuture = getMobileVideoPlayer();
    }
  }

  Future<bool> getMobileVideoPlayer() async {
    videoPlayerController = VideoPlayerController.network(
        widget.event.getAttachmentUrl().toString());
    await videoPlayerController?.initialize();

    chewieController = ChewieController(
      videoPlayerController: videoPlayerController!,
      looping: false,
    );

    return true;
  }

  @override
  void dispose() {
    // let's be sure to have cleaned temporary files
    cleanFiles();
    temporaryDirectory?.delete(recursive: true);

    videoPlayerController?.dispose();
    chewieController?.dispose();
    super.dispose();
  }

  Future<File> getFile() async {
    file = await widget.event.downloadAndDecryptAttachment(
      downloadCallback: (Uri url) async {
        final file = await DefaultCacheManager().getSingleFile(url.toString());
        return await file.readAsBytes();
      },
    );

    cleanFiles();

    temporaryDirectory ??=
        await Directory("${Directory.systemTemp.path}/${const Uuid().v1()}")
            .create(recursive: true);

    // DANGER: we are saving a decrypted file to disc. We MUST minise the time
    // spent where the file is in cleartext on the disk.
    // Can we avoid saving the file in this state on the disk and still be able
    // to render the video?
    final f = File("${temporaryDirectory!.path}/${widget.event.body}");
    await f.writeAsBytes(file!.bytes);
    temporaryFiles.add(f);

    if (!isDesktop) {
      videoPlayerController = VideoPlayerController.file(f);

      await videoPlayerController!.initialize();

      chewieController = ChewieController(
        videoPlayerController: videoPlayerController!,
        autoPlay: true,
        looping: false,
      );
    }

    return f;
  }

  void cleanFiles() {
    while (temporaryFiles.isNotEmpty) {
      final file = temporaryFiles.first;
      if (file.existsSync()) file.deleteSync();
      temporaryFiles.remove(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratio =
        widget.event.infoMap['w'] is int && widget.event.infoMap['h'] is int
            ? widget.event.infoMap['w'] / widget.event.infoMap['h']
            : null;

    if (!widget.event.isAttachmentEncrypted) {
      Widget? viewer;
      if (isDesktop) {
        viewer = LinuxMatrixVideoMessage(
            media: widget.event.getAttachmentUrl().toString());
      } else {
        viewer = FutureBuilder<bool>(
            future: mobileFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return Chewie(
                controller: chewieController!,
              );
            });
      }

      return ratio != null
          ? AspectRatio(
              aspectRatio: ratio,
              child: viewer,
            )
          : viewer;
    }
    return FutureBuilder<File>(
        future: decryptedFile ??= getFile(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const CircularProgressIndicator();
          }

          Widget? viewer;
          if (isDesktop) {
            viewer = LinuxMatrixVideoMessage(
                media: "file:///${snap.data!.path}",
                key: Key("file:///${snap.data!.path}"));
          } else {
            viewer = Chewie(
              controller: chewieController!,
            );
          }

          return ratio != null
              ? AspectRatio(
                  aspectRatio: ratio,
                  child: viewer,
                )
              : viewer;
        });
  }
}

class LinuxMatrixVideoMessage extends StatefulWidget {
  const LinuxMatrixVideoMessage({super.key, required this.media});

  final String media;

  @override
  State<LinuxMatrixVideoMessage> createState() =>
      _LinuxMatrixVideoMessageState();
}

class _LinuxMatrixVideoMessageState extends State<LinuxMatrixVideoMessage> {
  final player = Player();
  late VideoController playerController;

  Future<bool>? initFuture;

  @override
  void initState() {
    super.initState();
    playerController = VideoController(player);

    initFuture = init();
  }

  Future<bool> init() async {
    await player.open(
      Playlist(
        [
          Media(widget.media),
        ],
      ),
    );

    // let the player start and then pause, so the player load a frame
    Future.delayed(Duration.zero, () async {
      await player.pause();
    });
    return true;
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: initFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Video(
                controller: playerController,
              ),
              Row(
                children: [
                  StreamBuilder<bool>(
                      stream: player.streams.playing,
                      builder: (context, snapshot) {
                        return IconButton(
                          icon: Icon(player.state.playing
                              ? Icons.pause
                              : Icons.play_arrow),
                          onPressed: () {
                            player.playOrPause();
                          },
                        );
                      }),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: StreamBuilder<Duration>(
                          stream: player.streams.position,
                          builder: (context, snapshot) {
                            final value = snapshot.hasData
                                ? snapshot.data!.inMilliseconds /
                                    player.state.duration.inMilliseconds
                                : 0.0;
                            return LinearProgressIndicator(
                              value: value,
                            );
                          }),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.restart_alt),
                    onPressed: () async {
                      await player.seek(Duration.zero);
                    },
                  ),
                ],
              )
            ],
          );
        });
  }
}
