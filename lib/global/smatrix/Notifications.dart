import 'dart:async';

import 'package:famedlysdk/famedlysdk.dart';
import 'package:minestrix/global/smatrix.dart';

class Notifications {
  List<Notification> notifications = List.empty(growable: true);

  Notifications() {}

  StreamController<String> onNotifications = StreamController.broadcast();

  /// This method should fetch all the user events and build the notification feed
  // TODO : add a way to check if the user has been mentionned or not.
  // May be we set the event as read or not.
  void loadNotifications(SClient sclient) {
    notifications.clear();

    // load friend requests
    sclient.sInvites.forEach((key, value) {
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
  DateTime timestamp;
  Profile p;
}

enum NotificationType { Text, FriendRequest }
