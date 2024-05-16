import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

extension DateTimeExtension on DateTime {
  String get timeSinceInDays {
    final dt = DateTime.now();
    if (dt.difference(this).inDays.abs() > 90) {
      return DateFormat.yMMMMEEEEd().format(this);
    } else if (dt.difference(this).inDays.abs() > 7) {
      return DateFormat.MMMEd().format(this);
    } else if (dt.difference(this).inDays.abs() > 0) {
      return DateFormat.E().format(this);
    } else {
      return DateFormat.E().format(this);
    }
  }

  String get simpleFormatTime {
    final dt = DateTime.now();
    if (dt.difference(this).inDays.abs() > 90) {
      return DateFormat.yMd().format(this);
    } else if (dt.difference(this).inDays.abs() > 7) {
      return DateFormat.Md().format(this);
    } else if (dt.difference(this).inDays.abs() > 0) {
      return DateFormat.E().format(this);
    } else {
      return DateFormat.jm().format(this);
    }
  }

  String get timeSinceAWeekOrDuration {
    final dt = DateTime.now();
    if (dt.difference(this).inDays.abs() == 0) {
      return timeago.format(this);
    } else if (dt.difference(this).inDays.abs() > 365) {
      return DateFormat.yMMMd().format(this);
    } else if (dt.difference(this).inDays.abs() < 7) {
      return DateFormat.E().format(this);
    } else {
      return DateFormat.MMMd().format(this);
    }
  }
}

extension DurationExtension on Duration {
  String get toShortString {
    // TODO: Properly translate me
    if (inSeconds < 60) {
      return "${inSeconds}s";
    }
    if (inMinutes < 60) {
      return "${inMinutes}min ${inSeconds % 60}s";
    }
    return "${inHours}h ${inMinutes % 60}min";
  }
}
