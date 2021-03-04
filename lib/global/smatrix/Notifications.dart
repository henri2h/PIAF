import 'package:minestrix/global/smatrix.dart';

class Notifications {
  List<Notification> notification = List.empty();

  Notifications() {}
  void loadNotifications(SClient sclient) {}
}

class Notification {
  String body;
  NotificationType type;
}

enum NotificationType { Text, FriendRequest }
