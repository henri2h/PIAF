class TextHelper {
  static String getRoomInitial(String roomName) {
    List<String> names = roomName.split(" ");
    String initials = "";

    int numWords = 2;
    if (numWords > names.length) {
      numWords = names.length;
    }

    for (var i = 0; i < numWords; i++) {
      if (names[i].length > 1 &&
          RegExp(r"^[a-zA-Z0-9]+$").hasMatch(names[i][0]))
        initials += '${names[i][0].toUpperCase()}';
    }
    return initials;
  }
}
