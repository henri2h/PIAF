import 'package:flutter/foundation.dart';

import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:just_audio/just_audio.dart';

import '../../utils/platform_infos.dart';

class UserMediaManager {
  final player = FlutterRingtonePlayer();
  factory UserMediaManager() {
    return _instance;
  }

  UserMediaManager._internal();

  static final UserMediaManager _instance = UserMediaManager._internal();

  AudioPlayer? _assetsAudioPlayer;

  Future<void> startRingingTone() async {
    if (PlatformInfos.isMobile) {
      await player.playRingtone(volume: 80);
    } else if ((kIsWeb || PlatformInfos.isMacOS) &&
        _assetsAudioPlayer != null) {
      const path = 'assets/sounds/phone.ogg';
      final player = _assetsAudioPlayer = AudioPlayer();
      player.setAsset(path);
      player.play();
    }
    return;
  }

  Future<void> stopRingingTone() async {
    if (PlatformInfos.isMobile) {
      await player.stop();
    }
    await _assetsAudioPlayer?.stop();
    _assetsAudioPlayer = null;
    return;
  }
}
