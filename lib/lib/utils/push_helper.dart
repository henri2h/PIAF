import 'dart:convert';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../config/settings_key.dart';
import 'manager/client_manager.dart';

Future<void> pushHelper(
  PushNotification notification, {
  Client? client,
  String? activeRoomId,
  Future<dynamic> Function(NotificationResponse?)? onSelectNotification,
}) async {
  final isBackgroundMessage = client == null;
  Logs().v(
    'Push helper has been started (background=$isBackgroundMessage).',
    notification.toJson(),
  );

  if (!isBackgroundMessage &&
      activeRoomId == notification.roomId &&
      activeRoomId != null &&
      client.syncPresence == null) {
    Logs().v('Room is in foreground. Stop push helper here.');
    return;
  }

  // Initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('notifications_icon'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: onSelectNotification,
  );

  client ??= (await ClientManager.getClients(initialize: false)).first;
  final event = await client.getEventByPushNotification(
    notification,
    storeInDatabase: isBackgroundMessage,
  );

  if (event == null) {
    Logs().v('Notification is a clearing indicator.');
    await flutterLocalNotificationsPlugin.cancelAll();
    final store = await SharedPreferences.getInstance();
    await store.setString(SettingKeys.notificationCurrentIds, json.encode({}));
    return;
  }
  Logs().v('Push helper got notification event.');

  const matrixLocals = MatrixDefaultLocalizations();

  // Calculate the body
  final body = await event.calcLocalizedBody(
    matrixLocals,
    plaintextBody: true,
    withSenderNamePrefix: !event.room.isDirectChat,
    hideReply: true,
    hideEdit: true,
    removeMarkdown: true,
  );

  // The person object for the android message style notification
  final avatar = event.room.avatar
      ?.getThumbnail(
        client,
        width: 126,
        height: 126,
      )
      .toString();
  final avatarFile =
      avatar == null ? null : await DefaultCacheManager().getSingleFile(avatar);

  // Show notification
  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    AppConfig.pushNotificationsChannelId,
    AppConfig.pushNotificationsChannelName,
    channelDescription: AppConfig.pushNotificationsChannelDescription,
    styleInformation: MessagingStyleInformation(
      Person(name: event.room.client.userID),
      conversationTitle: event.room.displayname,
      groupConversation: !event.room.isDirectChat,
      messages: [
        Message(
          body,
          event.originServerTs,
          Person(
            name: event.room.displayname,
            icon: avatarFile == null
                ? null
                : BitmapFilePathAndroidIcon(avatarFile.path),
          ),
        )
      ],
    ),
    ticker: "Unread chats ${(notification.counts?.unread ?? 1)}",
    importance: Importance.max,
    priority: Priority.high,
    groupKey: event.room.id,
  );
  const iOSPlatformChannelSpecifics = DarwinNotificationDetails();
  final platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );
  await flutterLocalNotificationsPlugin.show(
    await mapRoomIdToInt(event.room.id),
    event.room.displayname,
    body,
    platformChannelSpecifics,
    payload: event.roomId,
  );
  Logs().v('Push helper has been completed!');
}

/// Workaround for the problem that local notification IDs must be int but we
/// sort by [roomId] which is a String. To make sure that we don't have duplicated
/// IDs we map the [roomId] to a number and store this number.
Future<int> mapRoomIdToInt(String roomId) async {
  final store = await SharedPreferences.getInstance();
  final idMap = Map<String, int>.from(
      jsonDecode(store.getString(SettingKeys.notificationCurrentIds) ?? '{}'));
  int? currentInt;
  try {
    currentInt = idMap[roomId];
  } catch (_) {
    currentInt = null;
  }
  if (currentInt != null) {
    return currentInt;
  }
  var nCurrentInt = 0;
  while (idMap.values.contains(nCurrentInt)) {
    nCurrentInt++;
  }
  idMap[roomId] = nCurrentInt;
  await store.setString(SettingKeys.notificationCurrentIds, json.encode(idMap));
  return nCurrentInt;
}
