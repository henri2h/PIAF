import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';

import 'package:minestrix_chat/partials/matrix/matrix_image_avatar.dart';
import '../../utils/platform_infos.dart';
import '../../utils/text.dart';
import '../components/adaptive_flat_button.dart';

class KeyVerificationDialog extends StatefulWidget {
  Future<void> show(BuildContext context) => PlatformInfos.isCupertinoStyle
      ? showCupertinoDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => this,
          useRootNavigator: false,
        )
      : showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => this,
          useRootNavigator: false,
        );

  final KeyVerification request;

  const KeyVerificationDialog({
    super.key,
    required this.request,
  });

  @override
  KeyVerificationPageState createState() => KeyVerificationPageState();
}

class KeyVerificationPageState extends State<KeyVerificationDialog> {
  void Function()? originalOnUpdate;
  late final List<dynamic> sasEmoji;

  @override
  void initState() {
    originalOnUpdate = widget.request.onUpdate;
    widget.request.onUpdate = () {
      originalOnUpdate?.call();
      setState(() {});
    };
    widget.request.client.getProfileFromUserId(widget.request.userId).then((p) {
      profile = p;
      setState(() {});
    });
    rootBundle.loadString('assets/sas-emoji.json').then((e) {
      sasEmoji = json.decode(e);
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    widget.request.onUpdate =
        originalOnUpdate; // don't want to get updates anymore
    if (![KeyVerificationState.error, KeyVerificationState.done]
        .contains(widget.request.state)) {
      widget.request.cancel('m.user');
    }
    super.dispose();
  }

  Profile? profile;

  Future<void> checkInput(String input) async {
    if (input.isEmpty) return;

    final valid = await showFutureLoadingDialog(
        context: context,
        future: () async {
          // make sure the loading spinner shows before we test the keys
          await Future.delayed(const Duration(milliseconds: 100));
          var valid = false;
          try {
            await widget.request.openSSSS(keyOrPassphrase: input);
            valid = true;
          } catch (_) {
            valid = false;
          }
          return valid;
        });
    if (valid.error != null) {
      await showOkAlertDialog(
        useRootNavigator: false,
        context: context,
        message: "Incorrect passphrase or recovery key",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user;
    final directChatId =
        widget.request.client.getDirectChatFromUserId(widget.request.userId);
    if (directChatId != null) {
      user = widget.request.client
          .getRoomById(directChatId)!
          .unsafeGetUserFromMemoryOrFallback(widget.request.userId);
    }
    final displayName =
        user?.calcDisplayname() ?? widget.request.userId.localpart!;
    var title = const Text("Verifying other account");
    Widget body;
    final buttons = <Widget>[];
    switch (widget.request.state) {
      case KeyVerificationState.askSSSS:
        // prompt the user for their ssss passphrase / key
        final textEditingController = TextEditingController();
        String input;
        body = Container(
          margin: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                  "To be able to sign the other person, please enter your secure store passphrase or recovery key.",
                  style: TextStyle(fontSize: 20)),
              Container(height: 10),
              TextField(
                controller: textEditingController,
                autofocus: false,
                autocorrect: false,
                onSubmitted: (s) {
                  input = s;
                  checkInput(input);
                },
                minLines: 1,
                maxLines: 1,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Incorrect passphrase or recovery key",
                  prefixStyle:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                  suffixStyle:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        );
        buttons.add(AdaptiveFlatButton(
          label: "Submit",
          onPressed: () => checkInput(textEditingController.text),
        ));
        buttons.add(AdaptiveFlatButton(
          label: "Skip",
          onPressed: () => widget.request.openSSSS(skip: true),
        ));
        break;
      case KeyVerificationState.askAccept:
        title = const Text("New verification request!");
        body = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              if (!PlatformInfos.isCupertinoStyle)
                MatrixImageAvatar(
                    url: user?.avatarUrl,
                    defaultText: displayName,
                    client: widget.request.client),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: PlatformInfos.isCupertinoStyle
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      '${widget.request.userId} - ${widget.request.deviceId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Image.asset('assets/verification.png', fit: BoxFit.contain),
            const SizedBox(height: 16),
            Text(
              "Accept this verification request from $displayName?",
            )
          ],
        );
        buttons.add(AdaptiveFlatButton(
          label: "Reject",
          textColor: Colors.red,
          onPressed: () => widget.request
              .rejectVerification()
              .then((_) => Navigator.of(context, rootNavigator: false).pop()),
        ));
        buttons.add(AdaptiveFlatButton(
          label: "Accept",
          onPressed: () => widget.request.acceptVerification(),
        ));
        break;
      case KeyVerificationState.waitingAccept:
        body = Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset('assets/verification.png', fit: BoxFit.contain),
            const SizedBox(height: 16),
            const CircularProgressIndicator.adaptive(strokeWidth: 2),
            const SizedBox(height: 16),
            const Text(
              "Waiting for partner to accept the request…",
              textAlign: TextAlign.center,
            ),
          ],
        );
        final key = widget.request.client.userDeviceKeys[widget.request.userId]
            ?.deviceKeys[widget.request.deviceId];
        if (key != null) {
          buttons.add(AdaptiveFlatButton(
            label: "Verify manually",
            onPressed: () async {
              final result = await showOkCancelAlertDialog(
                useRootNavigator: false,
                context: context,
                title: "Verify manually",
                message: key.ed25519Key?.beautified ?? 'Key not found',
              );
              if (result == OkCancelResult.ok) {
                await key.setVerified(true);
              }
              await widget.request.cancel();
              if (!context.mounted) return;
              Navigator.of(context, rootNavigator: false).pop();
            },
          ));
        }

        break;
      case KeyVerificationState.askSas:
        TextSpan compareWidget;
        // maybe add a button to switch between the two and only determine default
        // view for if "emoji" is a present sasType or not?
        String compareText;
        if (widget.request.sasTypes.contains('emoji')) {
          compareText =
              "Compare and make sure the following emoji match those of the other device:";
          compareWidget = TextSpan(
            children: widget.request.sasEmojis
                .map((e) => WidgetSpan(child: _Emoji(e, sasEmoji)))
                .toList(),
          );
        } else {
          compareText =
              "Compare and make sure the following numbers match those of the other device:";
          final numbers = widget.request.sasNumbers;
          final numbstr = '${numbers[0]}-${numbers[1]}-${numbers[2]}';
          compareWidget =
              TextSpan(text: numbstr, style: const TextStyle(fontSize: 40));
        }
        body = Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Center(
              child: Text(
                compareText,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            Text.rich(
              compareWidget,
              textAlign: TextAlign.center,
            ),
          ],
        );
        buttons.add(AdaptiveFlatButton(
          textColor: Colors.red,
          label: "They Don't Match",
          onPressed: () => widget.request.rejectSas(),
        ));
        buttons.add(AdaptiveFlatButton(
          label: "They Match",
          onPressed: () => widget.request.acceptSas(),
        ));
        break;
      case KeyVerificationState.waitingSas:
        final acceptText = widget.request.sasTypes.contains('emoji')
            ? "Waiting for partner to accept the emoji…"
            : "Waiting for partner to accept the numbers…";
        body = Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator.adaptive(strokeWidth: 2),
            const SizedBox(height: 10),
            Text(
              acceptText,
              textAlign: TextAlign.center,
            ),
          ],
        );
        break;
      case KeyVerificationState.done:
        body = const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outlined, color: Colors.green, size: 200.0),
            SizedBox(height: 10),
            Text(
              "You successfully verified!",
              textAlign: TextAlign.center,
            ),
          ],
        );
        buttons.add(AdaptiveFlatButton(
          label: "Close",
          onPressed: () => Navigator.of(context, rootNavigator: false).pop(),
        ));
        break;
      case KeyVerificationState.error:
        body = Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.cancel, color: Colors.red, size: 200.0),
            const SizedBox(height: 10),
            Text(
              'Error ${widget.request.canceledCode}: ${widget.request.canceledReason}',
              textAlign: TextAlign.center,
            ),
          ],
        );
        buttons.add(AdaptiveFlatButton(
          label: "Close",
          onPressed: () => Navigator.of(context, rootNavigator: false).pop(),
        ));
        break;
      case KeyVerificationState.askChoice:
        body = const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outlined, color: Colors.green, size: 200.0),
            SizedBox(height: 10),
            Text(
              "Ask choice",
              textAlign: TextAlign.center,
            ),
          ],
        );
        break;
      case KeyVerificationState.showQRSuccess:
        body = const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outlined, color: Colors.green, size: 200.0),
            SizedBox(height: 10),
            Text(
              "Show QR Success",
              textAlign: TextAlign.center,
            ),
          ],
        );
        break;
      case KeyVerificationState.confirmQRScan:
        body = const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outlined, color: Colors.green, size: 200.0),
            SizedBox(height: 10),
            Text(
              "Confirm QRScan",
              textAlign: TextAlign.center,
            ),
          ],
        );
        break;
    }
    final content = SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          body,
        ],
      ),
    );
    if (PlatformInfos.isCupertinoStyle) {
      return CupertinoAlertDialog(
        title: title,
        content: content,
        actions: buttons,
      );
    }
    return AlertDialog(
      title: title,
      content: content,
      actions: buttons,
    );
  }
}

class _Emoji extends StatelessWidget {
  final KeyVerificationEmoji emoji;
  final List<dynamic>? sasEmoji;

  const _Emoji(this.emoji, this.sasEmoji);

  String getLocalizedName() {
    final sasEmoji = this.sasEmoji;
    if (sasEmoji == null) {
      // asset is still being loaded
      return emoji.name;
    }
    final translations = Map<String, String?>.from(
        sasEmoji[emoji.number]['translated_descriptions']);
    translations['en'] = emoji.name;
    for (final locale in window.locales) {
      final wantLocaleParts = locale.toString().split('_');
      final wantLanguage = wantLocaleParts.removeAt(0);
      for (final haveLocale in translations.keys) {
        final haveLocaleParts = haveLocale.split('_');
        final haveLanguage = haveLocaleParts.removeAt(0);
        if (haveLanguage == wantLanguage &&
            (Set.from(haveLocaleParts)..removeAll(wantLocaleParts)).isEmpty &&
            (translations[haveLocale]?.isNotEmpty ?? false)) {
          return translations[haveLocale]!;
        }
      }
    }
    return emoji.name;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(emoji.emoji, style: const TextStyle(fontSize: 50)),
        Text(getLocalizedName()),
        const SizedBox(height: 10, width: 5),
      ],
    );
  }
}
