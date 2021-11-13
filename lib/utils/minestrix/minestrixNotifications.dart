import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:minestrix/utils/minestrix/minestrixClient.dart';

class MinestrixNotifications {
  List<Notification> notifications = List.empty(growable: true);

  MinestrixNotifications() {}

  StreamController<String> onNotifications = StreamController.broadcast();

  /// This method should fetch all the user events and build the notification feed
  // TODO : add a way to check if the user has been mentionned or not.
  // May be we set the event as read or not.
  void loadNotifications(MinestrixClient MinestrixClient) {
    notifications.clear();

    // load friend requests
    MinestrixClient.sInvites.forEach((key, value) {
      Notification n = Notification();
      n.body = "Friend request";
      n.type = NotificationType.FriendRequest;
      notifications.add(n);
    });

    onNotifications.add("update");
  }

  get hasNotifications => _hasNotifications();
  bool _hasNotifications() {
    if (notifications.length == 0) return false;
    return true;
  }
}

class Notification {
  String title = "";
  String body = "";

  NotificationType type = NotificationType.Text;
  DateTime? timestamp;
  Profile? p;
}

enum NotificationType { Text, FriendRequest }
