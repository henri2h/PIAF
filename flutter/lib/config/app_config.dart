abstract class AppConfig {
  static String applicationName = 'PIAF';
  static const String enablePushTutorial =
      'https://www.reddit.com/r/fluffychat/comments/qn6liu/enable_push_notifications_without_google_services/';
  static const String pushNotificationsChannelId = 'minestrix_push';
  static const String pushNotificationsChannelName = 'MinesTRIX push channel';
  static const String pushNotificationsChannelDescription =
      'Push notifications for MinesTRIX';
  static const String pushNotificationsGatewayUrl =
      'https://push.fluffychat.im/_matrix/push/v1/notify';
  static const String pushNotificationsPusherFormat = 'event_id_only';
  static const String pushNotificationsAppId = 'fr.henri2h.minestrix';
  static bool enableSentry = true;
  static bool experimentalVoip = true;
  static bool controlEnterToSend = false;
}
