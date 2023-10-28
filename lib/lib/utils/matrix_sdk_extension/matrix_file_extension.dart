import 'dart:io';

import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../platform_infos.dart';

extension MatrixFileExtension on MatrixFile {
  void save(BuildContext context) async {
    if (PlatformInfos.isIOS || PlatformInfos.isAndroid) {
      return share(context);
    }
    final fileName = name.split('/').last;

    final path = await FilePicker.platform.saveFile(
        dialogTitle: "Please select an output file", fileName: fileName);
    if (path != null) {
      final f = File(path);
      await f.writeAsBytes(bytes);
    }
  }

  void share(BuildContext context) async {
    final fileName = name.split('/').last;
    final tmpDirectory = await getTemporaryDirectory();
    final path = '${tmpDirectory.path}$fileName';
    await File(path).writeAsBytes(bytes);
    final box = context.findRenderObject() as RenderBox;
    await Share.shareFiles(
      [path],
      sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
    );
    return;
  }

   MatrixFile get detectFileType {
    if (msgType == MessageTypes.Image) {
      return MatrixImageFile(bytes: bytes, name: name);
    }
    if (msgType == MessageTypes.Video) {
      return MatrixVideoFile(bytes: bytes, name: name);
    }
    if (msgType == MessageTypes.Audio) {
      return MatrixAudioFile(bytes: bytes, name: name);
    }
    return this;
  }
}
