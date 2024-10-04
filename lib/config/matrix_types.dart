abstract class MatrixTypes {
  // should the account profile page type be org.matrix.msc3639.social.timeline ?
  static const String account = "org.matrix.msc3639.social.profile";

  static const String group = "org.matrix.msc3639.social.group";

  static const String post = "org.matrix.msc3639.social.post";
  static const String comment = "org.matrix.msc3639.social.comment";

  static const String image = "org.matrix.msc3639.social.image";
  static const String imageRef = "org.matrix.msc3639.social.image-ref";

  static const String shareRelation =
      "org.matrix.msc3639.social.share"; // to come
  static const String threadRelation = "m.thread";

  static const String blurhash = "xyz.amorgan.blurhash";

  static const String calendarEvent = "fr.emse.minitel.event";

  static const String reference = "m.reference";

  static const String todo = "fr.henri2h.todo";
  // MSC: https://github.com/matrix-org/matrix-spec-proposals/pull/2836
}

abstract class MatrixRoomTypes {
  static const String todo = "fr.henri2h.todo";
}

abstract class MatrixEventTypes {
  static const String pollStart = "org.matrix.msc3381.poll.start";
  static const String pollResponse = "org.matrix.msc3381.poll.response";
  static const String pollEnd = "org.matrix.msc3381.poll.end";
}

abstract class MatrixStateTypes {
  static const String calendarEventPollAttendance =
      "fr.emse.minitel.event.attendance_poll";
}

abstract class MatrixSocial {
  static const String caption = "org.matrix.msc3639.social.caption";
  static const String link = "org.matrix.msc3639.social.link";
}
