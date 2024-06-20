import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../pages/chat/chat_lib/device_media_gallery.dart';
import 'platform_infos.dart';

class FilesPicker {
  static Future<List<PlatformFile>?> pick(BuildContext context) async {
    if (PlatformInfos.isAndroid) {
      final result = await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const DeviceMediaGallery()));
      if (result is List<AssetEntity> && result.isNotEmpty) {
        final list = <PlatformFile>[];
        for (final item in result) {
          final file = await item.file;
          final data = await file?.readAsBytes();
          if (data != null) {
            list.add(PlatformFile(
                name: result.first.title ?? '',
                size: data.length,
                bytes: data));
          }
        }
        return list;
      }
    } else {
      return (await FilePicker.platform
              .pickFiles(type: FileType.image, withData: true))
          ?.files;
    }
    return null;
  }
}
