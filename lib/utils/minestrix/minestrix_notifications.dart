import 'dart:async';

import 'package:matrix/matrix.dart';
import 'minestrix_client_extension.dart';

extension MinestrixNotifications on Client {
  Stream get onMinestrixUpdate => onSync.stream;

  /// This method should fetch all the user events and build the notification feed
  // TODO : add a way to check if the user has been mentionned or not.
  // May be we set the event as read or not.
  List<Notification> get notifications {
    List<Notification> notifications = [];

    // load friend requests
    minestrixInvites.forEach((room) {
      Notification n = Notification();
      n.body = "Friend request";
      n.type = NotificationType.FriendRequest;
      notifications.add(n);
    });
    return notifications;
  }

  get hasNotifications => _hasNotifications();
  bool _hasNotifications() {
    if (notifications.length == 0) return false;
    return true;
  }

  int get totalNotificationsCount {
    int count = 0;

    rooms.forEach((room) {
      count += room.notificationCount;
    });
    return count;
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
