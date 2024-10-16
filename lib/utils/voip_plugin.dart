import 'dart:core';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc_impl;
import 'package:matrix/matrix.dart';
import 'package:piaf/features/chat/widgets/dialer/dialer.dart';
import 'package:webrtc_interface/webrtc_interface.dart' hide Navigator;

import '../utils/matrix_widget.dart';
import '../utils/platform_infos.dart';
import 'voip/callkeep_manager.dart';
import 'voip/user_media_manager.dart';

class VoipPlugin with WidgetsBindingObserver implements WebRTCDelegate {
  final MatrixState matrix;
  Client get client => matrix.client;

  VoipPlugin(this.matrix) {
    voip = VoIP(client, this);
    if (!kIsWeb) {
      final wb = WidgetsBinding.instance;
      wb.addObserver(this);
      didChangeAppLifecycleState(wb.lifecycleState);
    }
  }
  bool background = false;
  bool speakerOn = false;
  late VoIP voip;
  OverlayEntry? overlayEntry;

  @override
  void didChangeAppLifecycleState(AppLifecycleState? state) {
    background = (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused);
    Logs().w('Set background mode in VOIP plugin', background);
  }

  void addCallingOverlay(String callId, CallSession call) {
    if (overlayEntry != null) {
      Logs().e('[VOIP] addCallingOverlay: The call session already exists?');
      overlayEntry!.remove();
    }
    // Overlay.of(context) is broken on web
    // falling back on a dialog
    if (kIsWeb) {
      showDialog(
        context: matrix.context,
        builder: (context) => Calling(
          context: matrix.context,
          client: client,
          callId: callId,
          call: call,
          onClear: () => Navigator.of(context).pop(),
        ),
      );
    } else {
      overlayEntry = OverlayEntry(
        builder: (_) => Calling(
          context: matrix.context,
          client: client,
          callId: callId,
          call: call,
          onClear: () {
            overlayEntry?.remove();
            overlayEntry = null;
          },
        ),
      );
      Overlay.of(matrix.context).insert(overlayEntry!);
    }
  }

  @override
  MediaDevices get mediaDevices => webrtc_impl.navigator.mediaDevices;

  @override
  bool get isWeb => kIsWeb;

  @override
  Future<RTCPeerConnection> createPeerConnection(
    Map<String, dynamic> configuration, [
    Map<String, dynamic> constraints = const {},
  ]) =>
      webrtc_impl.createPeerConnection(configuration, constraints);

  Future<bool> get hasCallingAccount async =>
      kIsWeb ? false : await CallKeepManager().hasPhoneAccountEnabled;

  @override
  Future<void> playRingtone() async {
    if (!background && !await hasCallingAccount) {
      try {
        await UserMediaManager().startRingingTone();
      } catch (_) {}
    }
  }

  @override
  Future<void> stopRingtone() async {
    if (!background && !await hasCallingAccount) {
      try {
        await UserMediaManager().stopRingingTone();
      } catch (_) {}
    }
  }

  @override
  Future<void> handleNewCall(CallSession call) async {
    if (PlatformInfos.isAndroid) {
      // probably works on ios too
      final hasCallingAccount = await CallKeepManager().hasPhoneAccountEnabled;
      if (call.direction == CallDirection.kIncoming &&
          hasCallingAccount &&
          call.type == CallType.kVoice) {
        ///Popup native telecom manager call UI for incoming call.
        final callKeeper = CallKeeper(CallKeepManager(), call);
        CallKeepManager().addCall(call.callId, callKeeper);
        await CallKeepManager().showCallkitIncoming(call);
        return;
      } else {
        try {
          final wasForeground = await FlutterForegroundTask.isAppOnForeground;

          await matrix.store.setItemBool('wasForeground', wasForeground);
          FlutterForegroundTask.setOnLockScreenVisibility(true);
          FlutterForegroundTask.wakeUpScreen();
          FlutterForegroundTask.launchApp();
        } catch (e) {
          Logs().e('VOIP foreground failed $e');
        }
        // use fallback flutter call pages for outgoing and video calls.
        addCallingOverlay(call.callId, call);
        try {
          if (!hasCallingAccount) {
            ScaffoldMessenger.of(matrix.context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No calling accounts found (used for native calls UI)',
                ),
              ),
            );
          }
        } catch (e) {
          Logs().e('failed to show snackbar');
        }
      }
    } else {
      addCallingOverlay(call.callId, call);
    }
  }

  @override
  Future<void> handleCallEnded(CallSession session) async {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
      if (PlatformInfos.isAndroid) {
        FlutterForegroundTask.setOnLockScreenVisibility(false);
        FlutterForegroundTask.stopService();
        final wasForeground = await matrix.store.getItemBool('wasForeground');
        wasForeground == false ? FlutterForegroundTask.minimizeApp() : null;
      }
    }
  }

  @override
  Future<void> handleGroupCallEnded(GroupCallSession groupCall) async {
    // TODO: implement handleGroupCallEnded
  }

  @override
  Future<void> handleNewGroupCall(GroupCallSession groupCall) async {
    // TODO: implement handleNewGroupCall
  }

  @override
  // TODO: implement canHandleNewCall
  bool get canHandleNewCall =>
      voip.currentCID == null && voip.currentGroupCID == null;

  @override
  Future<void> handleMissedCall(CallSession session) async {
    // TODO: implement handleMissedCall
  }

  @override
  // TODO: implement keyProvider
  EncryptionKeyProvider? get keyProvider => throw UnimplementedError();
}
