import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  String toFormatedString() {
    final dt = DateTime.now();
    if (dt.difference(this).inDays.abs() > 7) {
      return DateFormat.yMMMMEEEEd().add_jm().format(this);
    } else if (dt.difference(this).inDays.abs() > 0) {
      return DateFormat.E().add_jm().format(this);
    } else {
      return DateFormat.jm().format(this);
    }
  }
}
