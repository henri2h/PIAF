import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:piaf/config/matrix_types.dart';
import 'minestrix_client_extension.dart';

extension MinestrixNotifications on Client {
  Stream<SyncUpdate> get onMinestrixUpdate =>
      onSync.stream.where((up) => up.hasRoomUpdate);

  Stream<SyncUpdate> get onNewPost => onSync.stream.where((up) {
        if (up.rooms?.join?.values != null) {
          for (var room in up.rooms!.join!.values) {
            if (room.timeline?.events?.isNotEmpty == true) {
              for (var event in room.timeline!.events!) {
                if (event.type == MatrixTypes.post) {
                  return true;
                }
              }
            }
          }
        }
        return false;
      });

  /// This method should fetch all the user events and build the notification feed
  // TODO : add a way to check if the user has been mentionned or not.
  // May be we set the event as read or not.
  List<Notification> get notifications {
    List<Notification> notifications = [];

    // load friend requests
    for (var room in minestrixInvites) {
      Notification n = Notification();
      n.body = "Friend request";
      n.type = NotificationType.friendRequest;
      notifications.add(n);
    }
    return notifications;
  }

  get hasNotifications => _hasNotifications();
  bool _hasNotifications() {
    if (notifications.isEmpty) return false;
    return true;
  }

  int get totalNotificationsCount {
    int count = 0;

    for (var room in rooms) {
      count += room.notificationCount;
    }
    return count;
  }
}

class Notification {
  String title = "";
  String body = "";

  NotificationType type = NotificationType.text;
  DateTime? timestamp;
  Profile? p;
}

enum NotificationType { text, friendRequest }
